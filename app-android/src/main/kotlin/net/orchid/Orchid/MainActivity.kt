package net.orchid.Orchid

import net.orchid.Orchid.BuildConfig;

import android.app.ActivityManager
import android.content.Context
import android.os.Bundle
import android.util.Log

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

import android.content.Intent;
import android.net.VpnService;

import java.io.*

const val VPN_SERVICE_REQUEST = 1

class MainActivity(): FlutterActivity() {
    lateinit var feedback: MethodChannel

    override fun configureFlutterEngine(engine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(engine)
        
        feedback = MethodChannel(engine.getDartExecutor().getBinaryMessenger(), "orchid.com/feedback")
        feedback.setMethodCallHandler { call, result ->
            Log.d("Orchid", call.method)
            when (call.method) {
                "ready" -> {
                    feedback.invokeMethod("providerStatus", true)
                    feedback.invokeMethod("connectionStatus", if ((getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager).getRunningServices(Integer.MAX_VALUE).any { it.service.className == OrchidVpnService::class.java.name }) "Connected" else "Disconnected")
                    result.success(null)
                }
                "group_path" -> {
                    result.success(getFilesDir().getAbsolutePath())
                }
                "connect" -> {
                    val intent = VpnService.prepare(this);
                    if (intent != null) {
                        startActivityForResult(intent, VPN_SERVICE_REQUEST)
                    } else {
                        startService(getServiceIntent())
                        feedback.invokeMethod("connectionStatus", "Connected")
                    }
                    result.success(null)
                }
                "disconnect" -> {
                    startService(getServiceIntent().setAction("disconnect"))
                    feedback.invokeMethod("connectionStatus", "Disconnected")
                    result.success(null)
                }
                "version" -> {
                    result.success("${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // TODO: Implement status check and "install" method of our feedback handler
        // TODO: to allow the UI to participate in permission prompting if desired.

        // we *could* hook feedback "connectionStatus" up to ConnectivityService:
        // NetworkAgentInfo [VPN () - 112] EVENT_NETWORK_INFO_CHANGED, going from CONNECTING to CONNECTED
        // but we'd need to make sure it's the Orchid VPN.
    }

    override fun onActivityResult(request: Int, result: Int, data: Intent?) {
        super.onActivityResult(request, result, data)
        if (request == VPN_SERVICE_REQUEST) {
            if (result == RESULT_OK) {
                startService(getServiceIntent());
                feedback.invokeMethod("connectionStatus", "Connected")
            }
        }
    }

    private fun getServiceIntent(): Intent {
        return Intent(this, OrchidVpnService::class.java);
    }

    private fun configFile(): File {
        return File(filesDir.absolutePath + "/orchid.cfg");
    }
}
