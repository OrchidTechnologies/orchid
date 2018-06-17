#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <jni.h>
#include <android/log.h>
#include "orchid.h"


int g_fd;

JNIEXPORT void JNICALL
Java_com_orchid_android_OrchidNative_runTunnel(JNIEnv* env, jobject thiz, jint fd)
{
    __android_log_print(ANDROID_LOG_VERBOSE, "orchid", "runTunnel:%d", fd);

    // set blocking
    fcntl(fd, F_SETFL, fcntl(fd, F_GETFL, 0) ^ O_NONBLOCK);

    g_fd = fd;

    for (;;) {
        uint8_t packet[65536];
        ssize_t r = read(fd, packet, sizeof(packet));
        if (r < 0) {
            int err = errno;
            __android_log_print(ANDROID_LOG_VERBOSE, "orchid", "read error: %d (%s)\n", err, strerror(err));
            return;
        }
        if (!on_tunnel_packet(packet, (size_t)r)) {
            write(fd, packet, r);
        }
    }
}

void write_tunnel_packet(const uint8_t *packet, size_t length)
{
    write(g_fd, packet, length);
}
