package com.example.floodlight

import android.os.Bundle
import androidx.lifecycle.lifecycleScope
import com.google.firebase.Firebase
import com.google.firebase.ai.ai
import com.google.firebase.ai.type.GenerativeBackend
import com.google.firebase.appcheck.appCheck
import com.google.firebase.appcheck.debug.DebugAppCheckProviderFactory
import com.google.firebase.initialize
import com.google.mlkit.genai.common.DownloadStatus
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.floodlight/hybrid_ai"
    private val capabilityChannelName = "com.example.floodlight/device_ai"
    private val nanoModel by lazy { Generation.getClient() }

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
            when (call.method) {
                "isGeminiNanoSupported" -> lifecycleScope.launch {
                    try {
                        result.success(isGeminiNanoSupported())
                    } catch (e: Exception) {
                        result.error("NANO_STATUS_ERROR", e.message ?: "Could not check Gemini Nano availability", null)
                    }
                }
                "generateGeminiNano" -> {
                    val prompt = call.argument<String>("prompt") ?: ""
                    lifecycleScope.launch {
                        try {
                            result.success(generateGeminiNano(prompt))
                        } catch (e: Exception) {
                            result.error("NANO_AI_ERROR", e.message ?: "Gemini Nano could not generate a response", null)
                        }
                    }
                }
                else -> result.notImplemented()
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
    }

    private suspend fun isGeminiNanoSupported(): Boolean {
        return when (nanoModel.checkStatus()) {
            FeatureStatus.AVAILABLE,
            FeatureStatus.DOWNLOADABLE,
            FeatureStatus.DOWNLOADING -> true
            else -> false
        }
    }

    private suspend fun generateGeminiNano(prompt: String): String {
        when (nanoModel.checkStatus()) {
            FeatureStatus.AVAILABLE -> Unit
            FeatureStatus.DOWNLOADABLE, FeatureStatus.DOWNLOADING -> {
                var downloadCompleted = false
                nanoModel.download().collect { status ->
                    when (status) {
                        is DownloadStatus.DownloadCompleted -> downloadCompleted = true
                        is DownloadStatus.DownloadFailed -> throw status.e
                        else -> Unit
                    }
                }
                if (!downloadCompleted || nanoModel.checkStatus() != FeatureStatus.AVAILABLE) {
                    throw IllegalStateException("Gemini Nano is not ready on this device.")
                }
            }
            else -> throw IllegalStateException("Gemini Nano is unavailable on this device.")
        }

        val response = nanoModel.generateContent(prompt)
        return response.candidates.firstOrNull()?.text?.takeIf { it.isNotBlank() }
            ?: throw IllegalStateException("Gemini Nano returned an empty response.")
    }
}
