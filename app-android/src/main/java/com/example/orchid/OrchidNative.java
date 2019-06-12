package com.example.orchid;

class OrchidNative {
    public static native void runTunnel(int fd, String dir);

    static {
        System.loadLibrary("orchid");
    }
}
