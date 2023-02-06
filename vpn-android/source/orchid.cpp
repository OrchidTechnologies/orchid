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
#include "local.hpp"
#include "port.hpp"
#include "transport.hpp"

namespace orc {

// NOLINTBEGIN(cppcoreguidelines-avoid-non-const-global-variables)
static JavaVM *jvm;
static asio::io_context *executor_;
S<BufferSink<Capture>> capture_;
// NOLINTEND(cppcoreguidelines-avoid-non-const-global-variables)

extern "C" JNIEXPORT void JNICALL
Java_net_orchid_Orchid_OrchidVpnService_runTunnel(JNIEnv* env, jobject thiz, jint file, jstring dir)
{
    Initialize();

    orc_assert(file != -1);

    auto local(Host_);

    const char* cDir = env->GetStringUTFChars(dir, nullptr);
    std::string files_dir = std::string(cDir);
    env->ReleaseStringUTFChars(dir, cDir);

    std::string config = files_dir + std::string("/orchid.cfg");

    auto capture(Break<BufferSink<Capture>>(Break<Local>(), local));
    auto connection(std::make_unique<File<asio::posix::stream_descriptor>>(Context(), file));
    auto &inverted(capture->Wire<Inverted>(std::move(connection)));

    asio::io_context executor;
    auto work(asio::make_work_guard(executor));
    executor_ = &executor;

    std::thread thread([&]() {
        capture->Start(config);
        inverted.Open();
        capture_ = std::move(capture);
    });

    executor_->run();
    thread.join();

    // XXX: this does asynchronous Shut on Capture, which might be wrong
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
        if (jvm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
            return false;
        }
        IMPORT(net/orchid/Orchid, OrchidVpnService);
        CATCH(return false);
        // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg)
        jmethodID mVpnProtect = env->GetStaticMethodID(cOrchidVpnService, "vpnProtect", "(I)Z");
        CATCH(return false);
        // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg)
        jboolean success = env->CallStaticBooleanMethod(cOrchidVpnService, mVpnProtect, s);
        CATCH(return false);
        //Log() << "vpn_protect fd:" << s << " success:" << (bool)success << std::endl;
        return (bool)success;
    })).get();
}

}

JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void* reserved)
{
    orc::jvm = vm;
    JNIEnv* env;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
        return -1;
    }
    return JNI_VERSION_1_6;
}
