import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_export.dart';
import 'core/session_keys.dart';
import 'services/auth_service.dart';

var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const configChannel = MethodChannel('com.naengo.app/config');
  final kakaoKey = await configChannel.invokeMethod<String>('getKakaoNativeAppKey') ?? '';
  KakaoSdk.init(nativeAppKey: kakaoKey);

  // RealAuthService로 교체하고 저장된 토큰이 있으면 세션을 복원.
  final authService = RealAuthService();
  AuthServiceLocator.instance = authService;
  await authService.restoreSession();
  final prefs = await SharedPreferences.getInstance();
  final hasSeenLoginEntry = prefs.getBool(hasSeenLoginEntryKey) ?? false;
  final initialRoute = authService.isLoggedIn || hasSeenLoginEntry
      ? AppRoutes.mainShell
      : AppRoutes.loginEntryScreen;

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, this.initialRoute = AppRoutes.initialRoute});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'fridge_expert',
          debugShowCheckedModeBanner: false,
          initialRoute: initialRoute,
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
