// Vision API 연결 테스트 스크립트.
//
// 앱을 실행하지 않고 서비스 계정 → OAuth → Vision API 호출까지
// 단계별로 확인합니다. 문제가 있으면 어느 단계에서 실패했는지 바로 알 수 있어요.
//
// 실행 방법 (프로젝트 루트에서):
//   flutter pub get
//   dart run tool/vision_api_test.dart
//
// 선택: 특정 로컬 이미지로 테스트하려면
//   dart run tool/vision_api_test.dart path/to/my_photo.jpg

import 'dart:convert';
import 'dart:io';

import 'package:fridge_expert/services/ingredient_translator.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

const _credentialsPath = 'assets/credentials/vision_service_account.json';

// 로컬 이미지를 안 주면 이 사진으로 테스트.
// Google Cloud 가 Vision API 샘플 용도로 공개 호스팅 중인 이미지라 가장 안정적.
const _fallbackImageUrl =
    'https://storage.googleapis.com/cloud-samples-data/vision/label/wakeupcat.jpg';

Future<void> main(List<String> args) async {
  stdout.writeln('============================================');
  stdout.writeln('   Google Cloud Vision API 연결 테스트');
  stdout.writeln('============================================\n');

  // ── Step 1: 크레덴셜 파일 존재 확인 ──
  final credFile = File(_credentialsPath);
  if (!credFile.existsSync()) {
    _fail(
      '크레덴셜 파일을 찾을 수 없어요.',
      '다음 경로에 서비스 계정 JSON 을 저장했는지 확인하세요:',
      '  $_credentialsPath',
    );
  }
  _ok('크레덴셜 파일 발견');

  // ── Step 2: JSON 파싱 ──
  late Map<String, dynamic> credJson;
  try {
    credJson = jsonDecode(await credFile.readAsString());
  } catch (e) {
    _fail('JSON 파싱 실패', '파일이 손상되었거나 올바른 서비스 계정 키가 아닙니다.', '원인: $e');
  }

  final projectId = credJson['project_id'];
  final clientEmail = credJson['client_email'];
  _ok('JSON 파싱 성공');
  stdout.writeln('     · project_id   : $projectId');
  stdout.writeln('     · client_email : $clientEmail');
  stdout.writeln();

  // ── Step 3: OAuth 인증 ──
  stdout.writeln('🔐 OAuth 토큰 발급 중...');
  late AutoRefreshingAuthClient authClient;
  try {
    final credentials = ServiceAccountCredentials.fromJson(credJson);
    authClient = await clientViaServiceAccount(
      credentials,
      [vision.VisionApi.cloudVisionScope],
    );
  } catch (e) {
    _fail(
      'OAuth 인증 실패',
      '서비스 계정 키가 비활성화됐거나 private_key 가 올바르지 않을 수 있어요.',
      '원인: $e',
    );
  }
  _ok('OAuth 인증 성공');
  stdout.writeln();

  // ── Step 4: 테스트 이미지 로드 ──
  List<int> imageBytes;
  if (args.isNotEmpty) {
    final path = args.first;
    final file = File(path);
    if (!file.existsSync()) {
      _fail('이미지 파일을 찾을 수 없어요.', '경로: $path');
    }
    imageBytes = await file.readAsBytes();
    _ok('로컬 이미지 로드 완료  (${imageBytes.length ~/ 1024} KB)');
    stdout.writeln('     · $path');
  } else {
    stdout.writeln('🖼️  원격 테스트 이미지 다운로드 중...');
    final resp = await http.get(
      Uri.parse(_fallbackImageUrl),
      headers: const {'User-Agent': 'fridge-expert-vision-test/1.0'},
    );
    if (resp.statusCode != 200) {
      _fail(
        '이미지 다운로드 실패',
        'HTTP ${resp.statusCode}',
        'URL: $_fallbackImageUrl',
        '',
        '로컬 이미지로 테스트하려면 다음처럼 실행하세요:',
        '  dart run tool/vision_api_test.dart path/to/your_image.jpg',
      );
    }
    imageBytes = resp.bodyBytes;
    _ok('이미지 다운로드 완료  (${imageBytes.length ~/ 1024} KB)');
  }
  stdout.writeln();

  // ── Step 5: Vision API 호출 ──
  stdout.writeln('☁️  Vision API 호출 중...');
  final api = vision.VisionApi(authClient);
  final request = vision.BatchAnnotateImagesRequest(
    requests: [
      vision.AnnotateImageRequest(
        image: vision.Image(content: base64Encode(imageBytes)),
        features: [
          vision.Feature(type: 'LABEL_DETECTION', maxResults: 10),
          vision.Feature(type: 'OBJECT_LOCALIZATION', maxResults: 5),
        ],
      ),
    ],
  );

  try {
    final response = await api.images.annotate(request);
    final result = response.responses?.first;
    _ok('API 응답 수신');
    stdout.writeln();

    // ── 결과 출력 ──
    // 원본(raw) / 번역(한) / 필터링 여부를 함께 보여줘서 재료 인식 품질 한눈에 확인.
    stdout.writeln('===== Label Detection =====');
    final labels = result?.labelAnnotations ?? [];
    if (labels.isEmpty) {
      stdout.writeln('  (레이블 없음)');
    } else {
      for (final l in labels) {
        final en = l.description ?? '';
        final score = ((l.score ?? 0) * 100).toStringAsFixed(1);
        final ko = IngredientTranslator.translate(en);
        final mark = ko == null ? '✗' : '✓';
        final koLabel = (ko ?? '— (재료 아님)').padRight(14);
        stdout.writeln('  $mark ${en.padRight(28)} $koLabel $score%');
      }
    }

    stdout.writeln();
    stdout.writeln('===== Object Localization =====');
    final objects = result?.localizedObjectAnnotations ?? [];
    if (objects.isEmpty) {
      stdout.writeln('  (객체 없음)');
    } else {
      for (final o in objects) {
        final en = o.name ?? '';
        final score = ((o.score ?? 0) * 100).toStringAsFixed(1);
        final ko = IngredientTranslator.translate(en);
        final mark = ko == null ? '✗' : '✓';
        final koLabel = (ko ?? '— (재료 아님)').padRight(14);
        stdout.writeln('  $mark ${en.padRight(28)} $koLabel $score%');
      }
    }

    // 최종 필터링 결과 요약 (신뢰도 ≥ 0.6 & 한국어 매핑 성공한 것만)
    stdout.writeln();
    stdout.writeln('===== ✨ 최종 재료 목록 (앱 채팅에 전달될 내용) =====');
    final Map<String, double> finalItems = {};
    for (final l in labels) {
      final score = l.score ?? 0;
      if (score < 0.6) continue;
      final ko = IngredientTranslator.translate(l.description ?? '');
      if (ko == null) continue;
      if ((finalItems[ko] ?? 0) < score) finalItems[ko] = score;
    }
    for (final o in objects) {
      final score = o.score ?? 0;
      if (score < 0.6) continue;
      final ko = IngredientTranslator.translate(o.name ?? '');
      if (ko == null) continue;
      if ((finalItems[ko] ?? 0) < score) finalItems[ko] = score;
    }
    if (finalItems.isEmpty) {
      stdout.writeln('  (조건 통과한 재료 없음 — 사진을 더 밝게/가깝게 찍어보세요)');
    } else {
      final sorted = finalItems.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final e in sorted.take(8)) {
        stdout.writeln(
          '  • ${e.key.padRight(14)} (${(e.value * 100).toStringAsFixed(1)}%)',
        );
      }
    }

    stdout.writeln();
    stdout.writeln('============================================');
    stdout.writeln('   ✅ 모든 단계 통과 — API 연결 정상!');
    stdout.writeln('============================================');
  } catch (e) {
    _fail(
      'Vision API 호출 실패',
      '다음을 확인해주세요:',
      '  1. Google Cloud Console → API 라이브러리에서 Cloud Vision API 가 "사용 설정" 상태인가?',
      '  2. 서비스 계정에 "Cloud Vision API User" (roles/cloudvision.user) 역할이 부여됐는가?',
      '  3. 프로젝트의 결제(Billing) 가 활성화돼 있는가?',
      '원인: $e',
    );
  } finally {
    authClient.close();
  }
}

void _ok(String msg) => stdout.writeln('✅ $msg');

Never _fail(String title, [
  String? l1,
  String? l2,
  String? l3,
  String? l4,
  String? l5,
  String? l6,
]) {
  stderr.writeln('\n❌ $title');
  for (final line in [l1, l2, l3, l4, l5, l6]) {
    if (line != null) stderr.writeln('   $line');
  }
  stderr.writeln('');
  exit(1);
}
