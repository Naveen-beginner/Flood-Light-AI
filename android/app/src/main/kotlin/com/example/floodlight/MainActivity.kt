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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Firebase.initialize(this)
        Firebase.appCheck.installAppCheckProviderFactory(
            DebugAppCheckProviderFactory.getInstance()
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
    }
}
