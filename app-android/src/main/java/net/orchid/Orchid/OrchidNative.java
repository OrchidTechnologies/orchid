package net.orchid.Orchid;

class OrchidNative {
    public static native void runTunnel(int fd, String dir);

    static {
        System.loadLibrary("orchid");
    }
}
