//C:\dev\jbm_escpos\android\app\src\main\kotlin\com\example\jbm_escpos\MainActivity.kt

package com.example.jbm_escpos

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log


class MainActivity: FlutterActivity() {

    private val CHANNEL = "jbm.intent.channel"

    private var pendingUri: String? = null
    private lateinit var channel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        // 🔥 Flutter pide leer archivo
        channel.setMethodCallHandler { call, result ->

            if (call.method == "read_file") {
                val uri = Uri.parse(call.arguments as String)

                val input = contentResolver.openInputStream(uri)
                val bytes = input!!.readBytes()

                result.success(bytes)
            }

            // 🔥 Flutter avisa que ya está listo
            if (call.method == "flutter_ready") {
                pendingUri?.let {
                    channel.invokeMethod("file_received", it)
                    pendingUri = null
                }
                result.success(true)
            }
        }

        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {

        if (Intent.ACTION_VIEW == intent.action) {
            val uri: Uri? = intent.data

            uri?.let {
                pendingUri = it.toString()
            }
        }
        Log.d("JBM", "Intent recibido: $intent")
        Log.d("JBM", "URI: $uri")
    }
}