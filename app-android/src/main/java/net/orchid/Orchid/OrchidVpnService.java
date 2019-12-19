package net.orchid.Orchid;

import java.io.File;
import java.io.IOException;

import android.app.Application;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Intent;
import android.content.res.AssetManager;
import android.net.VpnService;
import android.os.ParcelFileDescriptor;
import android.util.Log;

import io.flutter.plugin.common.BinaryMessenger;


public class OrchidVpnService extends VpnService {
    private static final String TAG = "OrchidVpnService";
    private static OrchidVpnService vpnService;

    private int fd = -1;

    static boolean vpnProtect(int fd) {
        return vpnService.protect(fd);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "onStartCommand: intent:" + intent + " flags:" + flags + " startId:" + startId);
        if (intent != null && "disconnect".equals(intent.getAction())) {
            stopForeground(true);
            stopSelf();
            // the Orchid stack crashes if the fd is closed, so exit instead
            //closeFd();
            System.exit(0);
            return START_NOT_STICKY;
        }
        return START_STICKY;
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
        builder.addDnsServer("1.0.0.1");
        builder.setSession("Orchid");
        Log.i(TAG, "builder:" + builder);
        try {
            ParcelFileDescriptor p = builder.establish();
            if (p != null) {
                fd = p.detachFd();
                Log.w(TAG, "Success: " + fd);
                vpnService = this;
                startForeground();
                new Thread(new Runnable() { public void run() {
                    File f = app().getFilesDir();
                    Log.d(TAG, "OrchidNative starting");
                    OrchidNative.runTunnel(fd, f.getAbsolutePath());
                    Log.d(TAG, "OrchidNative stopped");
                    stopSelfResult(1);
                }}).start();
            }
        } catch (IllegalStateException e) {
            Log.e(TAG, "onCreate", e);
        }
    }

    void closeFd() {
        if (fd == -1) {
            return;
        }
        try {
            ParcelFileDescriptor.adoptFd(fd).close();
        } catch (IOException e) {
        }
        fd = -1;
    }

    @Override
    public void onRevoke() {
        Log.d(TAG, "onRevoke");
        super.onRevoke();
        // the Orchid stack crashes if the fd is closed, so exit instead
        //closeFd();
        System.exit(0);
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
        // the Orchid stack crashes if the fd is closed, so exit instead
        //closeFd();
        System.exit(0);
    }

    public void startForeground() {
        final String NOTIFICATION_CHANNEL_ID = getString(R.string.app);
        NotificationManager mNotificationManager = (NotificationManager)getSystemService(NOTIFICATION_SERVICE);
        mNotificationManager.createNotificationChannel(new NotificationChannel(
                NOTIFICATION_CHANNEL_ID, NOTIFICATION_CHANNEL_ID,
                NotificationManager.IMPORTANCE_DEFAULT));
        Intent startIntent = new Intent(this, MainActivity.class);
        startIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_REORDER_TO_FRONT | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        PendingIntent contentIntent = PendingIntent.getActivity(this, 0, startIntent, 0);
        Notification.Builder builder = new Notification.Builder(this, NOTIFICATION_CHANNEL_ID);
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