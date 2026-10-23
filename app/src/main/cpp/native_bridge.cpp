#include <jni.h>
#include <android/log.h>

#define LOG_TAG "FlightGearAndroid"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

extern "C" JNIEXPORT void JNICALL
Java_org_flightgear_android_MainActivity_nativeInit(JNIEnv*, jobject) {
    LOGI("FlightGear Android native layer initialized");
    // The real FlightGear engine will be linked here in the next stage.
}
