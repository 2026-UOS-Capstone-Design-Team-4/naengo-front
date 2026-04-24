import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:googleapis_auth/auth_io.dart';

import 'ingredient_translator.dart';

/// Google Cloud Vision API 호출을 담당하는 서비스.
///
/// 서비스 계정 JSON (`assets/credentials/vision_service_account.json`) 을
/// 로드해서 OAuth2 인증 후 Vision API 의 Label Detection / Object Localization 실행.
///
/// ⚠️ 모바일 앱에 서비스 계정 키를 번들링하는 건 프로덕션엔 부적합.
///    추후 백엔드 프록시로 이전해야 함.
class VisionService {
  VisionService._();

  static const String _credentialsAsset =
      'assets/credentials/vision_service_account.json';

  static AutoRefreshingAuthClient? _client;

  /// 인증 클라이언트 초기화 (앱 실행 중 1번만).
  static Future<AutoRefreshingAuthClient> _getAuthClient() async {
    if (_client != null) return _client!;

    final raw = await rootBundle.loadString(_credentialsAsset);
    final credentials = ServiceAccountCredentials.fromJson(jsonDecode(raw));
    _client = await clientViaServiceAccount(
      credentials,
      [vision.VisionApi.cloudVisionScope],
    );
    return _client!;
  }

  /// 이미지 파일에서 재료를 인식해 리스트로 반환.
  /// Label Detection + Object Localization 두 가지 기능을 함께 호출.
  static Future<List<DetectedIngredient>> detectIngredients(
    File imageFile, {
    double minConfidence = 0.6,
    int maxResults = 8,
  }) async {
    try {
      final client = await _getAuthClient();
      final api = vision.VisionApi(client);

      final bytes = await imageFile.readAsBytes();
      final encoded = base64Encode(bytes);

      final request = vision.BatchAnnotateImagesRequest(
        requests: [
          vision.AnnotateImageRequest(
            image: vision.Image(content: encoded),
            features: [
              vision.Feature(type: 'LABEL_DETECTION', maxResults: 15),
              vision.Feature(type: 'OBJECT_LOCALIZATION', maxResults: 10),
            ],
          ),
        ],
      );

      final response = await api.images.annotate(request);
      final result = response.responses?.first;
      if (result == null) return [];

      // 중복 제거를 위한 맵.
      // 한국어 이름을 키로 쓰면, 서로 다른 영문 레이블(shrimp/prawn)이 같은 재료(새우)로
      // 매핑될 때 하나로 통합됨. 'lemon' + 'lemon juice' 처럼 브랜드/상세 레이블도 동일.
      final Map<String, DetectedIngredient> merged = {};

      // Label Annotations
      for (final label in result.labelAnnotations ?? <vision.EntityAnnotation>[]) {
        final name = label.description ?? '';
        final score = label.score ?? 0;
        if (name.isEmpty || score < minConfidence) continue;

        final korean = IngredientTranslator.translate(name);
        if (korean == null) continue; // 사전에 없는 레이블 = 재료 아님 → 스킵

        _mergeInto(merged, name, korean, score);
      }

      // Object Localization
      for (final obj
          in result.localizedObjectAnnotations ??
              <vision.LocalizedObjectAnnotation>[]) {
        final name = obj.name ?? '';
        final score = obj.score ?? 0;
        if (name.isEmpty || score < minConfidence) continue;

        final korean = IngredientTranslator.translate(name);
        if (korean == null) continue;

        _mergeInto(merged, name, korean, score);
      }

      // 신뢰도 내림차순 정렬 후 상한
      final sorted = merged.values.toList()
        ..sort((a, b) => b.confidence.compareTo(a.confidence));
      return sorted.take(maxResults).toList();
    } catch (e, st) {
      debugPrint('[VisionService] detectIngredients 실패: $e\n$st');
      rethrow;
    }
  }

  /// 한국어 재료명을 키로 merged 맵에 등록/갱신.
  /// 이미 같은 한국어 재료가 있으면 신뢰도가 더 높은 쪽만 남김.
  static void _mergeInto(
    Map<String, DetectedIngredient> map,
    String nameEn,
    String nameKo,
    double score,
  ) {
    final existing = map[nameKo];
    if (existing == null || score > existing.confidence) {
      map[nameKo] = DetectedIngredient(
        nameEn: nameEn,
        nameKo: nameKo,
        confidence: score,
      );
    }
  }

  /// 인식된 재료 목록을 채팅 메시지용 한국어 문장으로 포매팅.
  static String formatAsMessage(List<DetectedIngredient> items) {
    if (items.isEmpty) {
      return '음… 사진에서 재료를 확실히 알아보기 어려워요. 더 밝은 곳에서 가까이 찍어주시겠어요?';
    }

    final topNames = items.take(5).map((e) => e.nameKo).toList();
    final namesStr = topNames.join(', ');
    return '사진에서 $namesStr 이(가) 보여요!\n'
        '이 재료들로 어떤 요리를 해볼까요?';
  }
}

class DetectedIngredient {
  final String nameEn;
  final String nameKo;
  final double confidence;

  const DetectedIngredient({
    required this.nameEn,
    required this.nameKo,
    required this.confidence,
  });

  @override
  String toString() =>
      'DetectedIngredient($nameKo / $nameEn, ${(confidence * 100).toStringAsFixed(1)}%)';
}
