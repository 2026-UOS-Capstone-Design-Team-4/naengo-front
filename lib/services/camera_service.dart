import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// 카메라 / 갤러리 접근 헬퍼.
///
/// [image_picker]를 래핑해서 한 곳에서 설정을 관리합니다.
/// - iOS: Info.plist 의 NSCameraUsageDescription / NSPhotoLibraryUsageDescription 필요
/// - Android: AndroidManifest.xml 의 CAMERA 권한 필요 (image_picker 인텐트 방식)
class CameraService {
  CameraService._();

  static final ImagePicker _picker = ImagePicker();

  /// 카메라를 열어 사진 촬영.
  /// 취소하거나 실패하면 null 반환.
  static Future<XFile?> takePhoto({
    int imageQuality = 85,
    double? maxWidth = 1920,
    double? maxHeight = 1920,
  }) async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    } catch (e) {
      debugPrint('[CameraService] 카메라 실행 실패: $e');
      return null;
    }
  }

  /// 갤러리에서 사진 선택 (필요 시 사용).
  static Future<XFile?> pickFromGallery({
    int imageQuality = 85,
  }) async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
      );
    } catch (e) {
      debugPrint('[CameraService] 갤러리 선택 실패: $e');
      return null;
    }
  }
}
