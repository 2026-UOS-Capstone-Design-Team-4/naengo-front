package com.naengo.app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.naengo.app/config")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getKakaoNativeAppKey" -> result.success(BuildConfig.KAKAO_NATIVE_APP_KEY)
                    else -> result.notImplemented()
                }
            }
    }
}
