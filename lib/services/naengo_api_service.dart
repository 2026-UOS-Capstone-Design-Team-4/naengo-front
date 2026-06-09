import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/recipe.dart';
import '../models/user.dart';
import 'auth_service.dart';

/// 취향 입력이 사용자 정보(음식 선호·알레르기·식단·조리 습관)가 아닐 때 서버가 반환하는 422 에러.
class ProfileInputNotUserInfoException implements Exception {
  final String message;

  const ProfileInputNotUserInfoException([
    this.message = '음식 선호, 알레르기, 식단 정보를 입력해주세요.',
  ]);

  @override
  String toString() => message;
}

/// SSE 응답을 파싱한 이벤트 타입.
sealed class ChatEvent {}

/// 첫 응답에서 방 ID가 결정됨.
class RoomCreated extends ChatEvent {
  final int roomId;
  RoomCreated(this.roomId);
}

/// AI 응답 텍스트 조각.
class MessageChunk extends ChatEvent {
  final String content;
  MessageChunk(this.content);
}

/// AI 응답 완료 후 추천된 레시피 목록.
class RecipesReceived extends ChatEvent {
  final List<Recipe> recipes;
  RecipesReceived(this.recipes);
}

/// 스트리밍 중 발생한 오류.
class ChatStreamError extends ChatEvent {
  final String message;
  ChatStreamError(this.message);
}

/// Naengo (냉고) 백엔드 채팅 API 클라이언트.
///
/// 운영 백엔드:
///   - AI 서버 (FastAPI / 채팅·SSE·게시판):  https://ai.naengo.com
///   - Spring 서버 (인증):                    https://api.naengo.com   (HTTPS)
///
/// 다른 환경(스테이징/로컬)에서는 dart-define 으로 오버라이드:
///   flutter run --dart-define=NAENGO_API_BASE=https://your-ai-server \
///               --dart-define=NAENGO_SPRING_BASE=https://your-spring-server
///
/// 두 가지 엔드포인트 모두 SSE (Server-Sent Events) 스트림으로 응답:
///   POST /api/v1/chat/rooms          — 새 방 + 첫 메시지
///   POST /api/v1/chat/rooms/{room_id} — 기존 방 메시지
///
/// 이벤트 종류:
///   event: room     → {"room_id": int}            (첫 메시지에서만)
///   event: message  → {"content": "..."} (청크 N개)
///   event: recipes  → [RecipeResponse, ...]        (선택)
class NaengoApi {
  NaengoApi._();

  /// AI 서버 URL (채팅 SSE / 레시피 / 게시판).
  /// `--dart-define=NAENGO_API_BASE=...` 로 변경 가능.
  static const String baseUrl = String.fromEnvironment(
    'NAENGO_API_BASE',
    defaultValue: 'https://ai.naengo.com',
  );

  /// Spring 서버 URL (인증 등). `--dart-define=NAENGO_SPRING_BASE=...` 로 변경 가능.
  static const String _authBase = String.fromEnvironment(
    'NAENGO_SPRING_BASE',
    defaultValue: 'https://api.naengo.com',
  );

  /// 아이디/비밀번호 로그인 (`POST /auth/login`).
  /// 반환: { user_id, nickname, role, access_token }
  /// 실패 시 서버 에러 코드(예: INVALID_CREDENTIALS)를 message로 담은 [HttpException] throw.
  static Future<Map<String, dynamic>> loginWithCredentials(
    String username,
    String password,
  ) async {
    final uri = Uri.parse('$_authBase/api/v1/auth/login');
    final r = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (r.statusCode == 200) {
      return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    }
    String code = 'LOGIN_FAILED';
    try {
      final body =
          jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      code =
          ((body['error'] as Map?)?['code'] as String?) ?? code;
    } catch (_) {}
    throw HttpException(code, uri: uri);
  }

  /// 카카오 소셜 로그인 (`POST /api/v1/auth/social/kakao`).
  /// [kakaoAccessToken]: 카카오 SDK에서 받은 access_token.
  /// 반환: { user_id, nickname, role, access_token }
  static Future<Map<String, dynamic>> socialLoginKakao(
    String kakaoAccessToken,
  ) async {
    final uri = Uri.parse('$_authBase/api/v1/auth/social/kakao');
    final r = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'access_token': kakaoAccessToken}),
    );
    if (r.statusCode == 200) {
      return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    }
    throw HttpException(
      'socialLoginKakao ${r.statusCode}: ${r.body}',
      uri: uri,
    );
  }

  /// 로그아웃 (`POST /api/v1/auth/logout`).
  static Future<void> postLogout() async {
    try {
      final uri = Uri.parse('$_authBase/api/v1/auth/logout');
      await http.post(uri, headers: _authHeaders());
    } catch (_) {
      // stateless JWT라 서버 실패해도 로컬 토큰 삭제로 충분
    }
  }

  static Future<void> withdrawAccount() async {
    final uri = Uri.parse('$_authBase/api/v1/users/me');
    final r = await http.delete(uri, headers: _authHeaders());
    if (r.statusCode != 204) {
      String code = 'WITHDRAW_FAILED';
      try {
        final body = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
        code = ((body['error'] as Map?)?['code'] as String?) ?? code;
      } catch (_) {}
      throw HttpException(code, uri: uri);
    }
  }

  /// 인증이 필요한 API 호출에 쓸 헤더.
  /// 로그인 상태면 Authorization 헤더가 자동으로 붙음.
  static Map<String, String> _authHeaders() => {
    'Content-Type': 'application/json',
    if (AuthServiceLocator.instance.token != null)
      'Authorization': 'Bearer ${AuthServiceLocator.instance.token}',
  };

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

  /// 게스트 채팅 (SSE 스트림). 비로그인 사용자 전용.
  ///
  /// 서버에 저장되지 않으며, 이전 대화 이력([history])을 매 요청마다 클라이언트가 전달.
  /// [history] 항목은 `{"role": "user"|"model", "content": "..."}` 형식. 최대 20개.
  /// 응답에 `room` 이벤트 없음 — [RoomCreated] 가 yield 되지 않음.
  static Stream<ChatEvent> guestChat({
    required String prompt,
    String? imageDataUrl,
    List<Map<String, String>> history = const [],
  }) {
    final uri = Uri.parse('$baseUrl/api/v1/guest/chat');
    return _streamChat(
      uri,
      prompt: prompt,
      imageDataUrl: imageDataUrl,
      history: history,
    );
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

  // ───────────────────────── 동기화 (GET) API ─────────────────────────

  /// 사용자의 채팅방 목록 조회 (`GET /api/v1/chat/rooms`).
  /// `updated_at` 내림차순으로 정렬돼 옴.
  ///
  /// 반환되는 `ChatRoom` 의 `roomId` 는 `'server-{id}'` 포맷 (로컬 키),
  /// `serverRoomId` 에 백엔드 정수 ID 가 그대로 들어있음.
  static Future<List<ChatRoom>> listRooms() async {
    final uri = Uri.parse('$baseUrl/api/v1/chat/rooms');
    final r = await http.get(uri, headers: _authHeaders());
    if (r.statusCode != 200) {
      throw HttpException('listRooms ${r.statusCode}: ${r.body}', uri: uri);
    }
    final list = jsonDecode(utf8.decode(r.bodyBytes)) as List;
    return list
        .map((j) => _roomFromJson(j as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// 특정 채팅방의 전체 메시지 내역 조회 (`GET /api/v1/chat/rooms/{room_id}`).
  /// 시간순(오래된 것 → 최신)으로 반환됨.
  ///
  /// AI 응답에 레시피가 첨부됐었다면 `ChatMessage.recipes` 가 채워짐.
  /// 사용자가 첨부했던 이미지는 백엔드 `image_url` 필드로 복원됨 (S3 URL).
  static Future<List<ChatMessage>> getRoomHistory(int roomId) async {
    final uri = Uri.parse('$baseUrl/api/v1/chat/rooms/$roomId');
    final r = await http.get(uri, headers: _authHeaders());
    if (r.statusCode != 200) {
      throw HttpException(
        'getRoomHistory ${r.statusCode}: ${r.body}',
        uri: uri,
      );
    }
    final list = jsonDecode(utf8.decode(r.bodyBytes)) as List;
    return list
        .map((j) => _messageFromJson(j as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// 채팅방 삭제 (`DELETE /api/v1/chat/rooms/{room_id}`).
  /// 백엔드는 실제 삭제 대신 `is_active = false` 로 숨김 처리.
  /// 이후 `listRooms()` 응답에서 자동 제외됨.
  ///
  /// 이미 삭제된 방에 호출하면 404. 호출 측에서 그 경우도 "이미 삭제된 거니 OK" 로
  /// 처리할 수 있게, 404 도 성공으로 swallow.
  static Future<void> deleteRoom(int roomId) async {
    final uri = Uri.parse('$baseUrl/api/v1/chat/rooms/$roomId');
    final r = await http.delete(uri, headers: _authHeaders());
    if (r.statusCode == 200 || r.statusCode == 404) return;
    throw HttpException('deleteRoom ${r.statusCode}: ${r.body}', uri: uri);
  }

  /// `ChatRoomResponse` → 로컬 `ChatRoom` 변환.
  static ChatRoom _roomFromJson(Map<String, dynamic> j) {
    final id = j['room_id'] as int;
    return ChatRoom(
      roomId: 'server-$id',
      userId: 1, // 백엔드 임시 user_id=1, 인증 도입 시 갱신
      title: (j['title'] as String?)?.trim().isNotEmpty == true
          ? j['title'] as String
          : '새 채팅',
      createdAt: DateTime.parse(j['created_at'] as String),
      updatedAt: DateTime.parse(j['updated_at'] as String),
      serverRoomId: id,
    );
  }

  /// `ChatMessageResponse` → 로컬 `ChatMessage` 변환.
  static ChatMessage _messageFromJson(Map<String, dynamic> j) {
    final role = j['role'] as String? ?? 'model';
    final recipesJson = j['recipes'] as List?;
    return ChatMessage(
      text: j['content'] as String? ?? '',
      isMe: role == 'user',
      sentAt: DateTime.parse(j['created_at'] as String),
      imagePath: j['image_url'] as String?,
      recipes: recipesJson
          ?.map((r) => Recipe.fromJson((r as Map).cast<String, dynamic>()))
          .toList(growable: false),
      isStreaming: false,
    );
  }

  // ───────────────────────── 레시피 목록 API ─────────────────────────

  /// 레시피 목록 조회 (`GET /api/v1/recipes`).
  /// [cursor] 가 있으면 해당 커서 이후 항목을 반환 (cursor 기반 페이지네이션).
  /// 반환값: `(items, nextCursor, hasNext)`
  static Future<({List<Recipe> items, String? nextCursor, bool hasNext})>
  getRecipes({String sort = 'latest', int limit = 20, String? cursor}) async {
    final params = <String, String>{
      'sort': sort,
      'limit': limit.toString(),
      if (cursor != null) 'cursor': cursor,
    };
    final uri = Uri.parse(
      '$baseUrl/api/v1/recipes',
    ).replace(queryParameters: params);
    final r = await http.get(uri, headers: _authHeaders());
    if (r.statusCode != 200) {
      throw HttpException('getRecipes ${r.statusCode}: ${r.body}', uri: uri);
    }
    final decoded = jsonDecode(utf8.decode(r.bodyBytes));
    final map = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    final rawItems = map['items'] as List? ?? (decoded is List ? decoded : []);
    final items = rawItems
        .map((e) => Recipe.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
    return (
      items: items,
      nextCursor: map['next_cursor'] as String?,
      hasNext: map['has_next'] as bool? ?? false,
    );
  }

  /// 레시피 단건 조회 (`GET /api/v1/recipes/{recipe_id}`).
  static Future<Recipe> getRecipe(int recipeId) async {
    final uri = Uri.parse('$baseUrl/api/v1/recipes/$recipeId');
    final r = await http.get(uri, headers: _authHeaders());
    if (r.statusCode != 200) {
      throw HttpException('getRecipe ${r.statusCode}: ${r.body}', uri: uri);
    }
    return Recipe.fromJson(
      jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>,
    );
  }

  /// 내가 스크랩한 레시피 목록 (`GET /api/v1/recipes/scraps`).
  static Future<({List<Recipe> items, String? nextCursor, bool hasNext})>
  getMyScraps({int limit = 20, String? cursor}) async {
    final params = <String, String>{
      'limit': limit.toString(),
      if (cursor != null) 'cursor': cursor,
    };
    final uri = Uri.parse(
      '$baseUrl/api/v1/recipes/scraps',
    ).replace(queryParameters: params);
    final r = await http.get(uri, headers: _authHeaders());
    if (r.statusCode != 200) {
      throw HttpException('getMyScraps ${r.statusCode}: ${r.body}', uri: uri);
    }
    final decoded = jsonDecode(utf8.decode(r.bodyBytes));
    final map = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    final rawItems = map['items'] as List? ?? (decoded is List ? decoded : []);
    final items = rawItems
        .map((e) => Recipe.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
    return (
      items: items,
      nextCursor: map['next_cursor']?.toString(),
      hasNext: map['has_next'] as bool? ?? false,
    );
  }

  /// 승인된 사용자 레시피 목록 (`GET /api/v1/user-recipes`).
  static Future<({List<Map<String, dynamic>> items, String? nextCursor, bool hasNext})>
  getApprovedUserRecipes({int limit = 20, String? cursor}) async {
    final params = <String, String>{
      'limit': limit.toString(),
      if (cursor != null) 'cursor': cursor,
    };
    final uri = Uri.parse(
      '$baseUrl/api/v1/user-recipes',
    ).replace(queryParameters: params);
    final r = await http.get(uri, headers: _authHeaders());
    if (r.statusCode != 200) {
      throw HttpException(
        'getApprovedUserRecipes ${r.statusCode}: ${r.body}',
        uri: uri,
      );
    }
    final decoded = jsonDecode(utf8.decode(r.bodyBytes));
    final map = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    final rawItems = map['items'] as List? ?? (decoded is List ? decoded : []);
    final items = rawItems
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList(growable: false);
    return (
      items: items,
      nextCursor: map['next_cursor'] as String?,
      hasNext: map['has_next'] as bool? ?? false,
    );
  }

  /// 승인된 사용자 레시피 단건 조회 (`GET /api/v1/user-recipes/{id}`).
  static Future<Map<String, dynamic>> getApprovedUserRecipe(int id) async {
    final uri = Uri.parse('$baseUrl/api/v1/user-recipes/$id');
    final r = await http.get(uri, headers: _authHeaders());
    if (r.statusCode != 200) {
      throw HttpException(
        'getApprovedUserRecipe ${r.statusCode}: ${r.body}',
        uri: uri,
      );
    }
    return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<Map<String, int>> setRecipeLike(
    int recipeId, {
    required bool liked,
  }) =>
      _toggleRecipeReaction(recipeId: recipeId, kind: 'likes', enabled: liked);

  static Future<Map<String, int>> setRecipeScrap(
    int recipeId, {
    required bool scrapped,
  }) => _toggleRecipeReaction(
    recipeId: recipeId,
    kind: 'scraps',
    enabled: scrapped,
  );

  static Future<Map<String, int>> _toggleRecipeReaction({
    required int recipeId,
    required String kind,
    required bool enabled,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/recipes/$recipeId/$kind');
    final r = enabled
        ? await http.post(uri, headers: _authHeaders())
        : await http.delete(uri, headers: _authHeaders());
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw HttpException(
        '$kind ${enabled ? 'POST' : 'DELETE'} ${r.statusCode}: ${r.body}',
        uri: uri,
      );
    }
    if (r.bodyBytes.isEmpty) return {};
    final json = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    return {
      if (json['likes_count'] is int) 'likes_count': json['likes_count'] as int,
      if (json['scrap_count'] is int) 'scrap_count': json['scrap_count'] as int,
    };
  }

  // ───────────────────────── 레시피 제출 API ─────────────────────────

  /// 레시피 제출 (`POST /api/v1/user-recipes/me`, multipart/form-data).
  /// [payload]: 레시피 데이터 Map — `payload` 필드에 JSON 문자열로 전송.
  /// [mainImage]: 대표 이미지 (선택, jpeg/png/webp, max 10MB).
  static Future<int> submitPendingRecipe(
    Map<String, dynamic> payload, {
    XFile? mainImage,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/user-recipes/me');
    final request = http.MultipartRequest('POST', uri);
    if (AuthServiceLocator.instance.token != null) {
      request.headers['Authorization'] =
          'Bearer ${AuthServiceLocator.instance.token}';
    }
    request.fields['payload'] = jsonEncode(payload);
    // S3 도입 완료. main_image 멀티파트 파일 첨부.
    if (mainImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('main_image', mainImage.path),
      );
    }
    final streamed = await request.send();
    final r = await http.Response.fromStream(streamed);
    if (r.statusCode != 201) {
      throw HttpException(
        'submitPendingRecipe ${r.statusCode}: ${r.body}',
        uri: uri,
      );
    }
    final json = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    return json['user_recipe_id'] as int? ?? json['pending_recipe_id'] as int;
  }

  /// 내가 제출한 레시피 목록 (`GET /api/v1/user-recipes/me`).
  static Future<List<Map<String, dynamic>>> getMyPendingRecipes() async {
    final uri = Uri.parse('$baseUrl/api/v1/user-recipes/me');
    final r = await http.get(uri, headers: _authHeaders());
    if (r.statusCode != 200) {
      throw HttpException(
        'getMyPendingRecipes ${r.statusCode}: ${r.body}',
        uri: uri,
      );
    }
    final decoded = jsonDecode(utf8.decode(r.bodyBytes));
    final List rawItems;
    if (decoded is Map<String, dynamic>) {
      rawItems = decoded['items'] as List? ?? [];
    } else if (decoded is List) {
      rawItems = decoded;
    } else {
      rawItems = [];
    }
    return rawItems.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  /// 내가 제출한 레시피 단건 조회 (`GET /api/v1/user-recipes/me/{id}`).
  static Future<Map<String, dynamic>> getUserRecipe(int id) async {
    final uri = Uri.parse('$baseUrl/api/v1/user-recipes/me/$id');
    final r = await http.get(uri, headers: _authHeaders());
    if (r.statusCode != 200) {
      throw HttpException('getUserRecipe ${r.statusCode}: ${r.body}', uri: uri);
    }
    return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  }

  /// 제출한 레시피 삭제 (`DELETE /api/v1/user-recipes/me/{id}`).
  static Future<void> deletePendingRecipe(int id) async {
    final uri = Uri.parse('$baseUrl/api/v1/user-recipes/me/$id');
    final r = await http.delete(uri, headers: _authHeaders());
    if (r.statusCode != 200) {
      throw HttpException(
        'deletePendingRecipe ${r.statusCode}: ${r.body}',
        uri: uri,
      );
    }
  }

  // ───────────────────────── 유저 API ─────────────────────────

  /// 내 정보 조회 (`GET /api/v1/users/me`).
  static Future<AppUser> getMe() async {
    final uri = Uri.parse('$baseUrl/api/v1/users/me');
    final r = await http.get(uri, headers: _authHeaders());
    if (r.statusCode != 200) {
      throw HttpException('getMe ${r.statusCode}: ${r.body}', uri: uri);
    }
    return AppUser.fromJson(
      jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>,
    );
  }

  /// 닉네임 수정 (`PATCH /api/v1/users/me`).
  static Future<AppUser> patchNickname(String nickname) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/me');
    final r = await http.patch(
      uri,
      headers: _authHeaders(),
      body: jsonEncode({'nickname': nickname}),
    );
    if (r.statusCode != 200) {
      throw HttpException('patchNickname ${r.statusCode}: ${r.body}', uri: uri);
    }
    return AppUser.fromJson(
      jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>,
    );
  }

  /// 내 프로필 조회 — user_input 배열만 반환 (`GET /api/v1/users/me/profile`).
  /// 프로필이 아직 없으면(404) 빈 배열 반환.
  static Future<List<String>> getProfileInput() async {
    final uri = Uri.parse('$baseUrl/api/v1/users/me/profile');
    final r = await http.get(uri, headers: _authHeaders());
    if (r.statusCode == 404) return [];
    if (r.statusCode != 200) {
      throw HttpException(
        'getProfileInput ${r.statusCode}: ${r.body}',
        uri: uri,
      );
    }
    final decoded = jsonDecode(utf8.decode(r.bodyBytes));
    final raw = switch (decoded) {
      {'user_input': final List list} => list,
      {'inputs': final List list} => list,
      {'data': {'user_input': final List list}} => list,
      {'profile': {'user_input': final List list}} => list,
      final List list => list,
      _ => const [],
    };
    return raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  static Future<void> appendProfileInput(String text) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/me/profile');
    final r = await http.post(
      uri,
      headers: _authHeaders(),
      body: jsonEncode({'text': text}),
    );
    if (r.statusCode == 422) {
      throw ProfileInputNotUserInfoException(_extractErrorMessage(r.bodyBytes));
    }
    if (r.statusCode >= 300) {
      throw HttpException(
        'appendProfileInput ${r.statusCode}: ${r.body}',
        uri: uri,
      );
    }
  }

  static String _extractErrorMessage(List<int> bodyBytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bodyBytes));
      final message = switch (decoded) {
        {'message': final String value} => value,
        {'detail': final String value} => value,
        {'error': {'message': final String value}} => value,
        {'error': {'detail': final String value}} => value,
        _ => null,
      };
      if (message != null && message.trim().isNotEmpty) return message.trim();
    } catch (_) {}
    return '음식 선호, 알레르기, 식단 정보를 입력해주세요.';
  }

  static Future<void> deleteProfileInput(String text) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/me/profile');
    final r = await http.delete(
      uri,
      headers: _authHeaders(),
      body: jsonEncode({'text': text}),
    );
    if (r.statusCode >= 300) {
      throw HttpException(
        'deleteProfileInput ${r.statusCode}: ${r.body}',
        uri: uri,
      );
    }
  }

  /// SSE 스트리밍 내부 구현.
  static Stream<ChatEvent> _streamChat(
    Uri uri, {
    required String prompt,
    String? imageDataUrl,
    List<Map<String, String>>? history,
  }) async* {
    final client = http.Client();
    try {
      final request = http.Request('POST', uri);
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      if (AuthServiceLocator.instance.token != null) {
        request.headers['Authorization'] =
            'Bearer ${AuthServiceLocator.instance.token}';
      }

      request.body = jsonEncode({
        'prompt': prompt,
        if (imageDataUrl != null) 'image': imageDataUrl,
        if (history != null) 'history': history,
      });

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        yield ChatStreamError(
          'Server error (${streamedResponse.statusCode}): $body',
        );
        return;
      }

      String? currentEvent;
      await for (final line in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (line.isEmpty) continue;

        if (line.startsWith('event:')) {
          currentEvent = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          final data = line.substring(5).trim();
          if (data == '[DONE]') break;

          try {
            final decoded = jsonDecode(data);
            if (currentEvent == 'room') {
              final roomId = decoded['room_id'] as int?;
              if (roomId != null) yield RoomCreated(roomId);
            } else if (currentEvent == 'message') {
              final content = decoded['content'] as String?;
              if (content != null) yield MessageChunk(content);
            } else if (currentEvent == 'recipes') {
              if (decoded is List) {
                final recipes = decoded
                    .map(
                      (r) =>
                          Recipe.fromJson((r as Map).cast<String, dynamic>()),
                    )
                    .toList();
                yield RecipesReceived(recipes);
              }
            }
          } catch (_) {
            // chunk parse error, ignore or handle specifically if needed
          }
        }
      }
    } catch (e) {
      yield ChatStreamError('Connection error: $e');
    } finally {
      client.close();
    }
  }
}
