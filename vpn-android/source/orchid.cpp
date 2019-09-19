#include <fcntl.h>
#include <unistd.h>

#include <cerrno>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <string>

#include <android/log.h>
#include <jni.h>

#include "capture.hpp"
#include "file.hpp"
#include "transport.hpp"

namespace orc {

#define ORC_CATCH() catch(...) { \
    /* XXX: implement */ \
    orc_insist(false); \
}

static JavaVM *g_jvm;
static asio::io_context *executor_;
std::string files_dir;
U<Sink<Capture>> capture_;

extern "C" JNIEXPORT void JNICALL
Java_net_orchid_Orchid_OrchidNative_runTunnel(JNIEnv* env, jobject thiz, jint file, jstring dir)
{
    Log() << "runTunnel:" << file << std::endl;

    Initialize();

    orc_assert(file != -1);

    std::string local("10.7.0.3");

    const char* cDir = env->GetStringUTFChars(dir, nullptr);
    files_dir = std::string(cDir);
    env->ReleaseStringUTFChars(dir, cDir);

    std::string ovpnfilename = files_dir + std::string("/PureVPN.ovpn");
    Log() << ovpnfilename << std::endl;
    std::ifstream ifs(ovpnfilename);
    std::string ovpnfile((std::istreambuf_iterator<char>(ifs)), (std::istreambuf_iterator<char>()));
    std::string username(ORCHID_USERNAME);
    std::string password(ORCHID_PASSWORD);

    auto capture(std::make_unique<Sink<Capture>>(local));
    auto connection(capture->Wire<File<asio::posix::stream_descriptor>>(file));
    connection->Start();

    asio::io_context executor;
    auto work(asio::make_work_guard(executor));
    Spawn([
        capture = std::move(capture),
        ovpnfile = std::move(ovpnfile),
        username = std::move(username),
        password = std::move(password)
    ]() mutable -> task<void> { try {
        co_await Schedule();
        co_await capture->Start(GetLocal());
        //co_await capture->Start(std::move(ovpnfile), std::move(username), std::move(password));
        capture_ = std::move(capture);
    } ORC_CATCH() });
    executor_ = &executor;
    executor_->run();
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
#define CATCH(code) if (env->ExceptionOccurred()) { \
    env->ExceptionDescribe(); \
    env->ExceptionClear(); \
    code; \
}

bool vpn_protect(int s)
{
    //Log() << "vpn_protect: " << s << std::endl;
    return boost::asio::post(*executor_, std::packaged_task<bool()>([&]{
        //Log() << "vpn_protect_inner: " << s << std::endl;
        JNIEnv *env;
        if (g_jvm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
            return false;
        }
        IMPORT(net/orchid/Orchid, OrchidVpnService);
        CATCH(return false);
        jmethodID mVpnProtect = env->GetStaticMethodID(cOrchidVpnService, "vpnProtect", "(I)Z");
        CATCH(return false);
        // NOLINTNEXTLINE (cppcoreguidelines-pro-type-vararg)
        jboolean success = env->CallStaticBooleanMethod(cOrchidVpnService, mVpnProtect, s);
        CATCH(return false);
        //Log() << "vpn_protect fd:" << s << " success:" << (bool)success << std::endl;
        return (bool)success;
    })).get();
}

}
