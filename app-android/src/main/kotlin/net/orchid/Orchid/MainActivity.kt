package net.orchid.Orchid

import net.orchid.Orchid.BuildConfig;

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
                    startService(getServiceIntent().setAction("disconnect"))
                    feedback.invokeMethod("connectionStatus", "Disconnected")
                }
                "reroute" -> {
                }
                "version" -> {
                    result.success("${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})")
                }
            }
        }

        // we *could* hook feedback "connectionStatus" up to ConnectivityService:
        // NetworkAgentInfo [VPN () - 112] EVENT_NETWORK_INFO_CHANGED, going from CONNECTING to CONNECTED
        // but we'd need to make sure it's the Orchid VPN.
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
