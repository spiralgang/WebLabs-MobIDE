#include <jni.h>
#include "native_terminal_core.cpp"

static NativeTerminalCore* getTerminalCore(jlong handle) {
    return reinterpret_cast<NativeTerminalCore*>(handle);
}

extern "C" {

JNIEXPORT jlong JNICALL
Java_com_spiralgang_ashlar_MainActivity_initializeNativeTerminal(JNIEnv *env, jobject thiz) {
    auto* terminal = new NativeTerminalCore();
    if (terminal->initializeNativePTY()) {
        return reinterpret_cast<jlong>(terminal);
    }
    delete terminal;
    return 0;
}

JNIEXPORT jstring JNICALL
Java_com_spiralgang_ashlar_MainActivity_executeNativeCommand(JNIEnv *env, jobject thiz, 
                                                            jlong handle, jstring command) {
    auto* terminal = getTerminalCore(handle);
    if (!terminal) return env->NewStringUTF("Terminal not initialized");
    
    const char* cmd = env->GetStringUTFChars(command, nullptr);
    std::string result = terminal->executeCommand(std::string(cmd));
    env->ReleaseStringUTFChars(command, cmd);
    
    return env->NewStringUTF(result.c_str());
}

JNIEXPORT void JNICALL
Java_com_spiralgang_ashlar_MainActivity_destroyNativeTerminal(JNIEnv *env, jobject thiz, 
                                                             jlong handle) {
    auto* terminal = getTerminalCore(handle);
    if (terminal) {
        delete terminal;
    }
}

}