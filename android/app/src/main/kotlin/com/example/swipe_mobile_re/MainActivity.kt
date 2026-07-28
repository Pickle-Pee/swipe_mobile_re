package com.example.swipe_mobile_re

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private companion object {
        const val APP_INFORMATION_CHANNEL =
            "com.example.swipe_mobile_re/app_information"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            APP_INFORMATION_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "getPackageInfo") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            try {
                val packageInfo = packageManager.getPackageInfo(packageName, 0)
                val buildNumber = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    packageInfo.longVersionCode
                } else {
                    @Suppress("DEPRECATION")
                    packageInfo.versionCode.toLong()
                }
                result.success(
                    mapOf(
                        "appName" to applicationInfo.loadLabel(packageManager).toString(),
                        "version" to (packageInfo.versionName ?: ""),
                        "buildNumber" to buildNumber.toString(),
                    ),
                )
            } catch (error: Exception) {
                result.error(
                    "PACKAGE_INFO_UNAVAILABLE",
                    "Installed package information is unavailable",
                    null,
                )
            }
        }
    }
}
