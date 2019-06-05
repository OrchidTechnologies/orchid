package com.example.orchid

import android.os.Bundle

import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity(): FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this)

        MethodChannel(flutterView, "orchid.com/feedback").setMethodCallHandler { call, result ->
            when (call.method) {
                "connect" -> {
                    System.exit(-1)
                }
                "disconnect" -> {
                }
                "reroute" -> {
                }
            }
        }
    }
}
