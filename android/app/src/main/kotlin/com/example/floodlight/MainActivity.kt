package com.example.floodlight

import android.os.Bundle
import androidx.lifecycle.lifecycleScope
import com.google.firebase.Firebase
import com.google.firebase.ai.ai
import com.google.firebase.ai.type.GenerativeBackend
import com.google.firebase.appcheck.appCheck
import com.google.firebase.appcheck.debug.DebugAppCheckProviderFactory
import com.google.firebase.initialize
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.floodlight/hybrid_ai"
    private val capabilityChannelName = "com.example.floodlight/device_ai"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Firebase.initialize(this)
        Firebase.appCheck.installAppCheckProviderFactory(
            DebugAppCheckProviderFactory.getInstance()
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            capabilityChannelName
        ).setMethodCallHandler { call, result ->
            if (call.method == "isGeminiNanoSupported") {
                result.success(isGeminiNanoSupported())
            } else {
                result.notImplemented()
            }
        }

        val hybridModel = Firebase.ai(backend = GenerativeBackend.googleAI()).generativeModel(
            modelName = "gemini-3.8-flash"
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "generateHybrid") {
                    val prompt = call.argument<String>("prompt") ?: ""
                    lifecycleScope.launch {
                        try {
                            val response = hybridModel.generateContent(prompt)
                            val sourceStr = try {
                                response.inferenceSource.toString()
                            } catch (_: Exception) {
                                "CLOUD"
                            }
                            result.success(
                                mapOf(
                                    "text" to (response.text ?: ""),
                                    "source" to sourceStr
                                )
                            )
                        } catch (e: Exception) {
                            result.error("HYBRID_AI_ERROR", e.message ?: "Unknown error", null)
                        }
                    }
                } else {
                    result.notImplemented()
                }
            }

            private fun isGeminiNanoSupported(): Boolean {
                val packageNames = listOf(
                "com.google.android.aicore",
                "com.google.android.gms"
                )
                val packageManager = applicationContext.packageManager

                for (packageName in packageNames) {
                try {
                    packageManager.getPackageInfo(packageName, 0)
                    if (packageName == "com.google.android.aicore") {
                        return true
                    }
                } catch (_: Exception) {
                    // Continue checking supported packages.
                }
                }

                return packageManager.systemAvailableFeatures.any {
                it.name == "com.google.android.feature.AI_CORE"
                }
            }
    }
}
