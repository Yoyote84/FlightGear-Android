#include <jni.h>
#include <android/log.h>
#include <android/native_window_jni.h>

#define LOG_TAG "FlightGearAndroid"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

static ANativeWindow* g_window = nullptr;

extern "C" JNIEXPORT void JNICALL
Java_org_flightgear_android_MainActivity_nativeSurfaceCreated(JNIEnv* env, jclass, jobject surface) {
    if (g_window) {
        ANativeWindow_release(g_window);
        g_window = nullptr;
    }
    g_window = ANativeWindow_fromSurface(env, surface);
    if (g_window) {
        LOGI("Android render surface acquired");
    } else {
        LOGI("Failed to acquire Android render surface");
    }
}

extern "C" JNIEXPORT void JNICALL
Java_org_flightgear_android_MainActivity_nativeSurfaceChanged(JNIEnv*, jclass, jobject, jint width, jint height) {
    LOGI("Android render surface changed: %d x %d", width, height);
    // The FlightGear/OSG Android window adapter will consume this surface.
}

extern "C" JNIEXPORT void JNICALL
Java_org_flightgear_android_MainActivity_nativeSurfaceDestroyed(JNIEnv*, jclass) {
    if (g_window) {
        ANativeWindow_release(g_window);
        g_window = nullptr;
    }
    LOGI("Android render surface released");
}
