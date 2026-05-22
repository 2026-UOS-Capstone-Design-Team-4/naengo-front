import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'core/app_export.dart';
import 'services/auth_service.dart';

var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kakao SDK 초기화 — 카카오 로그인 버튼을 쓰기 전에 반드시 먼저 실행.
  // 네이티브 앱 키는 빌드 시 --dart-define=KAKAO_NATIVE_APP_KEY=xxx 로 주입.
  // 네이티브 설정 필요: Android AndroidManifest.xml, iOS Info.plist 참고.
  KakaoSdk.init(
    nativeAppKey: const String.fromEnvironment(
      'KAKAO_NATIVE_APP_KEY',
      defaultValue: '',
    ),
  );

  // RealAuthService로 교체. 토큰은 in-memory — 앱 재시작 시 재로그인 필요.
  AuthServiceLocator.instance = RealAuthService();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'fridge_expert',
          debugShowCheckedModeBanner: false,
          initialRoute: AppRoutes.initialRoute,
          onGenerateRoute: AppRoutes.generateRoute,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
        );
      },
    );
  }
}
