package com.orchid.android;

class OrchidNative {
    public static native void setTunnelFd(int fd);

    static {
        System.loadLibrary("orchid");
    }
}
