// ⚠️ DEPRECATED — 이 파일은 더 이상 사용되지 않습니다.
//
// 기존 MindLogic FactChat 게이트웨이 호출은 팀 자체 백엔드(Naengo API) 로 대체됐습니다.
// 새 구현은 `lib/services/naengo_api_service.dart` 의 `NaengoApi` 를 사용하세요.
//
// 호환성을 위해 빈 클래스를 남겨두지만, 신규 코드에서 임포트하지 마세요.
// 이 파일은 다음 정리 PR 에서 제거됩니다.

@Deprecated('Use NaengoApi from naengo_api_service.dart instead')
class ApiService {
  ApiService._();
}
