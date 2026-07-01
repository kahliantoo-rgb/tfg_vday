package com.mycompany.tfgvday

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.URLEncoder

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WHATSAPP_BUSINESS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchSend" -> {
                    val phone = call.argument<String>("phone")
                    val text = call.argument<String>("text") ?: ""
                    if (phone.isNullOrBlank()) {
                        result.error("invalid_args", "phone is required", null)
                        return@setMethodCallHandler
                    }
                    val launched = launchWhatsAppBusinessSend(phone, text)
                    if (launched) {
                        result.success(true)
                    } else {
                        result.error(
                            "not_installed",
                            "WhatsApp Business is not installed",
                            null,
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun launchWhatsAppBusinessSend(phone: String, text: String): Boolean {
        val encodedText = URLEncoder.encode(text, "UTF-8")
        val url =
            "https://api.whatsapp.com/send?phone=$phone&text=$encodedText"
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
            setPackage(WHATSAPP_BUSINESS_PACKAGE)
        }
        return if (intent.resolveActivity(packageManager) != null) {
            startActivity(intent)
            true
        } else {
            false
        }
    }

    companion object {
        private const val WHATSAPP_BUSINESS_CHANNEL =
            "com.mycompany.tfgvday/whatsapp_business"
        private const val WHATSAPP_BUSINESS_PACKAGE = "com.whatsapp.w4b"
    }
}
