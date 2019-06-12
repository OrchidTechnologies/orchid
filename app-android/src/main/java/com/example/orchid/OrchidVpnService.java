package com.example.orchid;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.IOException;
import java.io.OutputStream;

import android.app.Application;
import android.app.Notification;
import android.app.PendingIntent;
import android.content.Intent;
import android.content.res.AssetManager;
import android.net.VpnService;
import android.os.ParcelFileDescriptor;
import android.util.Log;

public class OrchidVpnService extends VpnService {
    private static final String TAG = "OrchidVpnService";
    private static OrchidVpnService vpnService;

    static boolean vpnProtect(int fd) {
        return vpnService.vpnProtect(fd);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "onStartCommand: intent:" + intent + " flags:" + flags + " startId:" + startId);
        return START_STICKY;
    }

    public static void copyTo(InputStream in, File dst) throws IOException {
        try {
            OutputStream out = new FileOutputStream(dst);
            try {
                // Transfer bytes from in to out
                byte[] buf = new byte[4096];
                int len;
                while ((len = in.read(buf)) > 0) {
                    out.write(buf, 0, len);
                }
            } finally {
                out.close();
            }
        } finally {
            in.close();
        }
    }

    private static Application app() {
        try {
            return (Application) Class.forName("android.app.ActivityThread")
                    .getMethod("currentApplication").invoke(null, (Object[]) null);
        } catch (Exception e) {
        }
        return null;
    }

    @Override
    public void onCreate() {
        Log.d(TAG, "onCreate");
        Builder builder = new Builder();
        builder.addAddress("10.7.0.3", 32);
        builder.addRoute("0.0.0.0", 0);
        builder.addDnsServer("8.8.8.8");
        builder.addDnsServer("8.8.4.4");
        builder.setSession("Orchid");
        Log.i(TAG, "builder:" + builder);
        try {
            ParcelFileDescriptor p = builder.establish();
            if (p != null) {
                final int fd = p.detachFd();
                Log.w(TAG, "Success: " + fd);
                vpnService = this;
                startForeground();
                new Thread(new Runnable() { public void run() {

                    File f = app().getFilesDir();
                    AssetManager assetManager = app().getAssets();
                    try {
                        InputStream in = assetManager.open("PureVPN.ovpn");
                        copyTo(in, new File(f, "PureVPN.ovpn"));
                    } catch (IOException e) {
                        Log.e(TAG, "onCreate", e);
                    }

                    OrchidNative.runTunnel(fd, f.getAbsolutePath());
                    stopSelfResult(1);
                }}).start();
            }
        } catch (IllegalStateException e) {
            Log.e(TAG, "onCreate", e);
        }
    }

    @Override
    public void onRevoke() {
        Log.d(TAG, "onRevoke");
        // TODO: close fd
        super.onRevoke();
    }

    @Override
    public void onTrimMemory(int level) {
        Log.d(TAG, "onTrimMemory(" + level + ")");
    }

    @Override
    public void onLowMemory() {
        Log.d(TAG, "onLowMemory");
    }

    @Override
    public void onDestroy() {
        Log.d(TAG, "onDestroy");
    }

    public void startForeground() {
        Intent startIntent = new Intent(this, MainActivity.class);
        startIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_REORDER_TO_FRONT | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        PendingIntent contentIntent = PendingIntent.getActivity(this, 0, startIntent, 0);
        Notification.Builder builder = new Notification.Builder(this);
        builder.setContentTitle(getText(R.string.app));
        builder.setContentText(getText(R.string.connected));
        builder.setContentIntent(contentIntent);
        builder.setOngoing(true);
        builder.setSmallIcon(R.drawable.ic_vpn);
        Intent i = new Intent();
        PendingIntent pendingIntent = PendingIntent.getBroadcast(this, 0, i, 0);
        builder.addAction(R.drawable.ic_vpn, "Stop", pendingIntent);
        Notification n = builder.build();
        startForeground(1, n);
    }

}