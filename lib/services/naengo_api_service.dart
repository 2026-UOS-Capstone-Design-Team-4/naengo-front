import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/recipe.dart';

/// Naengo (냉고) 백엔드 채팅 API 클라이언트.
///
/// 베이스 URL 은 dart-define 으로 주입 가능:
///   flutter run --dart-define=NAENGO_API_BASE=http://43.201.62.254:8000
///
/// 두 가지 엔드포인트 모두 **SSE (Server-Sent Events)** 스트림으로 응답:
///   POST /api/v1/chat/rooms          — 새 방 + 첫 메시지
///   POST /api/v1/chat/rooms/{room_id} — 기존 방 메시지
///
/// 이벤트 종류:
///   event: room     → {"room_id": int}            (첫 메시지에서만)
///   event: message  → {"content": "..."} (청크 N개)
///   event: recipes  → [RecipeResponse, ...]        (선택)
class NaengoApi {
  NaengoApi._();

  /// 베이스 URL. 빌드 시 `--dart-define=NAENGO_API_BASE=...` 로 변경 가능.
  static const String baseUrl = String.fromEnvironment(
    'NAENGO_API_BASE',
    defaultValue: 'http://43.201.62.254:8000',
  );

  /// 새 채팅방 생성 + 첫 메시지 (SSE 스트림).
  ///
  /// [imageDataUrl] 은 `data:image/jpeg;base64,...` 포맷이어야 함.
  /// 헬퍼 [encodeImageAsDataUrl] 로 File 에서 변환 가능.
  static Stream<ChatEvent> createRoomAndChat({
    required String prompt,
    String? imageDataUrl,
  }) {
    final uri = Uri.parse('$baseUrl/api/v1/chat/rooms');
    return _streamChat(uri, prompt: prompt, imageDataUrl: imageDataUrl);
  }

  /// 기존 채팅방에서 메시지 전송 (SSE 스트림).
  /// 백엔드가 최근 10개 대화를 컨텍스트로 자동 포함시킴.
  static Stream<ChatEvent> sendInRoom({
    required int roomId,
    required String prompt,
    String? imageDataUrl,
  }) {
    final uri = Uri.parse('$baseUrl/api/v1/chat/rooms/$roomId');
    return _streamChat(uri, prompt: prompt, imageDataUrl: imageDataUrl);
  }

  /// File → `data:image/jpeg;base64,...` 형식 data URL 로 변환.
  ///
  /// 백엔드 ChatRequest.image 가 정확히 이 포맷을 받음.
  /// JPEG/PNG 모두 mime 만 맞으면 OK — 카메라 결과는 image_picker 가 jpg 로 저장.
  static Future<String> encodeImageAsDataUrl(
    File file, {
    String mime = 'image/jpeg',
  }) async {
    final bytes = await file.readAsBytes();
    final b64 = base64Encode(bytes);
    return 'data:$mime;base64,$b64';
  }

  // ───────────────────────── 내부 구현 ─────────────────────────

  /// 공통 SSE 호출 + 파싱 로직.
  /// http.Client.send 로 streamed response 를 받아 라인 단위로 파싱.
  static Stream<ChatEvent> _streamChat(
    Uri uri, {
    required String prompt,
    String? imageDataUrl,
  }) async* {
    final client = http.Client();
    try {
      final body = <String, dynamic>{'prompt': prompt};
      if (imageDataUrl != null) body['image'] = imageDataUrl;

      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..headers['Accept'] = 'text/event-stream'
        ..body = jsonEncode(body);

      final response = await client.send(request);
      if (response.statusCode != 200) {
        final errBody = await response.stream.bytesToString();
        throw HttpException(
          'Naengo API ${response.statusCode}: $errBody',
          uri: uri,
        );
      }

      // SSE 메시지 단위 — 빈 줄로 구분되는 이벤트 블록을 모은다.
      // 한 블록 안에는 'event: foo' / 'data: ...' 이 있을 수 있음.
      String? currentEvent;
      final dataBuffer = StringBuffer();

      // bytes → utf8 → 라인 단위로 변환.
      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        if (line.isEmpty) {
          // 빈 줄 → 한 이벤트 블록 종료. 파싱하고 yield.
          final raw = dataBuffer.toString();
          if (currentEvent != null && raw.isNotEmpty) {
            final parsed = _parseEvent(currentEvent, raw);
            if (parsed != null) yield parsed;
          }
          currentEvent = null;
          dataBuffer.clear();
          continue;
        }

        if (line.startsWith('event:')) {
          currentEvent = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          // 한 이벤트가 여러 data: 줄에 걸칠 수 있음 (SSE 표준)
          if (dataBuffer.isNotEmpty) dataBuffer.writeln();
          dataBuffer.write(line.substring(5).trim());
        }
        // ":" 로 시작하는 코멘트 라인 / 기타 헤더는 무시
      }

      // 스트림 종료 직전에 남은 이벤트 처리
      final tail = dataBuffer.toString();
      if (currentEvent != null && tail.isNotEmpty) {
        final parsed = _parseEvent(currentEvent, tail);
        if (parsed != null) yield parsed;
      }
    } catch (e, st) {
      debugPrint('[NaengoApi] stream 오류: $e\n$st');
      yield ChatStreamError(message: e.toString());
    } finally {
      client.close();
    }
  }

  /// 이벤트 이름 + raw data 문자열 → ChatEvent.
  static ChatEvent? _parseEvent(String event, String dataRaw) {
    try {
      final dynamic data = jsonDecode(dataRaw);
      switch (event) {
        case 'room':
          // {"room_id": 42}
          if (data is Map && data['room_id'] is int) {
            return RoomCreated(roomId: data['room_id'] as int);
          }
          return null;
        case 'message':
          // {"content": "..."}
          if (data is Map && data['content'] is String) {
            return MessageChunk(content: data['content'] as String);
          }
          return null;
        case 'recipes':
          // [RecipeResponse, ...]
          if (data is List) {
            final list = data
                .whereType<Map>()
                .map((e) => Recipe.fromJson(e.cast<String, dynamic>()))
                .toList(growable: false);
            return RecipesReceived(recipes: list);
          }
          return null;
        default:
          return null;
      }
    } catch (e) {
      debugPrint('[NaengoApi] 이벤트 파싱 실패 ($event): $e\nraw=$dataRaw');
      return null;
    }
  }
}

// ───────────────────────── 이벤트 모델 ─────────────────────────

/// SSE 스트림에서 yield 되는 단일 이벤트.
sealed class ChatEvent {
  const ChatEvent();
}

/// `event: room` — 첫 메시지 시 백엔드가 부여한 정수 room_id.
class RoomCreated extends ChatEvent {
  final int roomId;
  const RoomCreated({required this.roomId});
}

/// `event: message` — AI 응답의 텍스트 청크. 호출 측에서 누적해 합쳐야 함.
class MessageChunk extends ChatEvent {
  final String content;
  const MessageChunk({required this.content});
}

/// `event: recipes` — 답변 완료 후 추천된 레시피 목록.
class RecipesReceived extends ChatEvent {
  final List<Recipe> recipes;
  const RecipesReceived({required this.recipes});
}

/// 네트워크/파싱 오류. UI 측에서 에러 메시지로 처리.
class ChatStreamError extends ChatEvent {
  final String message;
  const ChatStreamError({required this.message});
}
