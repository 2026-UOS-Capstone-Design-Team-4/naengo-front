# Google Cloud 서비스 계정 인증서

이 폴더에 Vision API용 서비스 계정 JSON 키 파일을 놓습니다.

## 파일 배치
1. Google Cloud Console에서 받은 서비스 계정 JSON 파일을 아래 이름으로 **이 폴더**에 저장:
   ```
   assets/credentials/vision_service_account.json
   ```
2. `flutter pub get` 실행
3. 앱 재빌드

## ⚠️ 보안 주의
- 이 JSON은 절대 git에 커밋하지 마세요 (이미 .gitignore에 등록됨)
- 모바일 앱에 서비스 계정 키를 번들링하는 것은 개발/데모 단계에서만 사용하세요
- 프로덕션에서는 백엔드 서버를 프록시로 두고 거기서 Vision API를 호출해야 합니다
- 클라우드 콘솔에서 해당 서비스 계정에 **Cloud Vision API User** 역할만 부여하세요 (최소 권한)
