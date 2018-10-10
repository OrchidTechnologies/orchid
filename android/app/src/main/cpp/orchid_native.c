#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <jni.h>
#include <android/log.h>
#include "orchid.h"


int g_fd = -1;
static JavaVM *g_jvm;

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

jint JNI_OnLoad(JavaVM *vm, void *reserved)
{
    g_jvm = vm;
    JNIEnv *env;
    if ((*vm)->GetEnv(vm, (void**)&env, JNI_VERSION_1_6) != JNI_OK) {
        return JNI_ERR;
    }
    return JNI_VERSION_1_6;
}

#define STR(A) #A
#define IMPORT(pkg, class) jclass c ## class = (*env)->FindClass(env, STR(pkg) "/" STR(class));
#define CATCH(code) if ((*env)->ExceptionOccurred(env)) { /*(*env)->ExceptionClear(env);*/ code; }

bool vpn_protect(int s, port_t port)
{
    JNIEnv *env;
    if ((*g_jvm)->GetEnv(g_jvm, (void**)&env, JNI_VERSION_1_6) != JNI_OK) {
        return false;
    }
    IMPORT(com/orchid/android, OrchidVpnService);
    CATCH(return false);
    jmethodID mVpnProtect = (*env)->GetStaticMethodID(env, cOrchidVpnService, "vpnProtect", "(I)Z");
    CATCH(return false);
    jboolean success = (*env)->CallStaticBooleanMethod(env, cOrchidVpnService, mVpnProtect, s);
    return success;
}

void write_tunnel_packet(const uint8_t *packet, size_t length)
{
    write(g_fd, packet, length);
}
