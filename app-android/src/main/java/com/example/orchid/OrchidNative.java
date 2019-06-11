package com.example.orchid;

class OrchidNative {
    public static native void runTunnel(int fd);

    static {
        System.loadLibrary("orchid");
    }
}
