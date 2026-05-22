import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'core/app_export.dart';
import 'services/auth_service.dart';

var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const configChannel = MethodChannel('com.naengo.app/config');
  final kakaoKey = await configChannel.invokeMethod<String>('getKakaoNativeAppKey') ?? '';
  KakaoSdk.init(nativeAppKey: kakaoKey);

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
