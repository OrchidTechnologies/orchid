package net.orchid.Orchid

import net.orchid.Orchid.BuildConfig;

import android.os.Bundle
import android.util.Log

import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.view.FlutterMain

import android.content.Intent;
import android.net.VpnService;

import java.io.*

const val VPN_SERVICE_REQUEST = 1

class MainActivity(): FlutterActivity() {
    lateinit var feedback: MethodChannel

    override fun onCreate(savedInstanceState: Bundle?) {
        FlutterMain.startInitialization(this)
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this)
        
        feedback = MethodChannel(flutterView, "orchid.com/feedback")
        feedback.setMethodCallHandler { call, result ->
            Log.d("Orchid", call.method)
            when (call.method) {
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
                "get_config" -> {
                    var file = configFile();
                    val text = file.readText()
                    result.success(text);
                }
                "set_config" -> {
                    Log.d("Orchid", "set config")
                    var text: String? = call.argument<String>("text")
                    if ( text == null ) {
                        Log.d("Orchid", "invalid argument in set_config")
                        text = "";
                    }
                    val textIn = text.byteInputStream();
                    var file = configFile();
                    copyTo(textIn, file);
                    Log.d("Orchid", "copy complete")
                    result.success("true"); // todo, validation
                }
            }
        }

        // TODO: Implement status check and "install" method of our feedback handler
        // TODO: to allow the UI to participate in permission prompting if desired.
        // Indicate to the UI that the VPN permissions are granted.
        feedback.invokeMethod("providerStatus", true)

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

    fun copyTo(ins: InputStream, dst: File) {
        ins.use { ins ->
            val out = FileOutputStream(dst)
            out.use { out ->
                // Transfer bytes from in to out
                val buf = ByteArray(4096)
                var len: Int = 0
                while ({ len = ins.read(buf); len }() > 0) {
                    out.write(buf, 0, len)
                }
            }
        }
    }
}
