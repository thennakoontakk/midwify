package com.midwify.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var headLandmarkerBridge: HeadLandmarkerBridge

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        headLandmarkerBridge = HeadLandmarkerBridge(applicationContext)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            HEAD_LANDMARKER_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "detectFromPath" -> {
                    val imagePath = call.argument<String>("imagePath")
                    if (imagePath.isNullOrBlank()) {
                        result.error(
                            "invalid_args",
                            "imagePath is required for head landmark detection.",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    try {
                        result.success(headLandmarkerBridge.detectFromPath(imagePath))
                    } catch (t: Throwable) {
                        if (::headLandmarkerBridge.isInitialized) {
                            headLandmarkerBridge.close()
                        }
                        result.error(
                            "head_landmarker_error",
                            t.message ?: "Head landmark detection failed.",
                            mapOf(
                                "type" to t.javaClass.name,
                                "cause" to t.cause?.toString(),
                            ),
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        if (::headLandmarkerBridge.isInitialized) {
            headLandmarkerBridge.close()
        }
        super.cleanUpFlutterEngine(flutterEngine)
    }

    companion object {
        private const val HEAD_LANDMARKER_CHANNEL = "midwify/head_landmarker"
    }
}
