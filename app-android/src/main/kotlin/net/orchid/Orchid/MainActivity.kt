package net.orchid.Orchid

import android.os.Bundle
import android.util.Log

import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import android.content.Intent;
import android.net.VpnService;

class MainActivity(): FlutterActivity() {
    lateinit var feedback: MethodChannel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this)

        feedback = MethodChannel(flutterView, "orchid.com/feedback")
        feedback.setMethodCallHandler { call, result ->
            Log.d("Orchid", call.method)
            when (call.method) {
                "group_path" -> {
                    result.success(getFilesDir().getAbsolutePath())
                    feedback.invokeMethod("providerStatus", true)
                }
                "connect" -> {
                    val intent = VpnService.prepare(this);
                    if (intent != null) {
                        startActivityForResult(intent, 0)
                    } else {
                        startService(getServiceIntent())
                        feedback.invokeMethod("connectionStatus", "Connected")
                    }
                }
                "disconnect" -> {
                    // TODO:
                    //feedback.invokeMethod("connectionStatus", "Disconnected")
                }
                "reroute" -> {
                }
            }
        }
    }

    override fun onActivityResult(request: Int, result: Int, data: Intent?) {
        if (result == RESULT_OK) {
            startService(getServiceIntent());
            feedback.invokeMethod("connectionStatus", "Connected")
        }
    }

    private fun getServiceIntent(): Intent {
        return Intent(this, OrchidVpnService::class.java);
    }
}
