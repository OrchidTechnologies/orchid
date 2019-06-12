#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <jni.h>
#include <android/log.h>

#include "transport.hpp"
#include "file.hpp"

using namespace orc;

#define ORC_CATCH() catch(...) { \
    /* XXX: implement */ \
    orc_insist(false); \
}

static JavaVM *g_jvm;
std::string files_dir;

extern "C" JNIEXPORT void JNICALL
Java_com_example_orchid_OrchidNative_runTunnel(JNIEnv* env, jobject thiz, jint file, jstring dir)
{
    __android_log_print(ANDROID_LOG_VERBOSE, "orchid", "runTunnel:%d", file);

    Initialize();

    orc_assert(file != -1);

    const char* cDir = env->GetStringUTFChars(dir, NULL);
    files_dir = std::string(cDir);
    env->ReleaseStringUTFChars(dir, cDir);

    std::string ovpnfile = files_dir + std::string("/PureVPN.ovpn");
    std::string username(ORCHID_USERNAME);
    std::string password(ORCHID_PASSWORD);

    auto capture(std::make_unique<Sink<Capture>>("10.7.0.3"));
    auto connection(capture->Wire<File<asio::posix::stream_descriptor>>(file));
    connection->Start();

    Wait([&]() -> task<void> {
        co_await Schedule();
        co_await capture->Start(std::move(ovpnfile), std::move(username), std::move(password));
    }());
}

JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void* reserved)
{
    g_jvm = vm;
    JNIEnv* env;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
        return -1;
    }
    return JNI_VERSION_1_6;
}

#define STR(A) #A
#define IMPORT(pkg, class) jclass c ## class = env->FindClass(STR(pkg) "/" STR(class));
#define CATCH(code) if (env->ExceptionOccurred()) { /*(*env)->ExceptionClear(env);*/ code; }

bool vpn_protect(int s)
{
    JNIEnv *env;
    if (g_jvm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
        return false;
    }
    IMPORT(com/example/orchid, OrchidVpnService);
    CATCH(return false);
    jmethodID mVpnProtect = env->GetStaticMethodID(cOrchidVpnService, "vpnProtect", "(I)Z");
    CATCH(return false);
    jboolean success = env->CallStaticBooleanMethod(cOrchidVpnService, mVpnProtect, s);
    return success;
}
