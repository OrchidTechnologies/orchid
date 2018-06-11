#include <jni.h>

#include <android/log.h>

JNIEXPORT void JNICALL
Java_com_orchid_android_OrchidNative_setTunnelFd(JNIEnv* env, jobject thiz, jint fd)
{
    __android_log_print(ANDROID_LOG_VERBOSE, "orchid", "setTunnelFd:%d", fd);
}
