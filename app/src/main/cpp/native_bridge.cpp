#include <jni.h>
#include <android/native_window_jni.h>

extern "C" void fg_android_surface_created(ANativeWindow* window);
extern "C" void fg_android_surface_changed(int width, int height);
extern "C" void fg_android_surface_destroyed();

extern "C" JNIEXPORT void JNICALL
Java_org_flightgear_android_MainActivity_nativeSurfaceCreated(JNIEnv* env, jclass, jobject surface) {
    ANativeWindow* window = ANativeWindow_fromSurface(env, surface);
    fg_android_surface_created(window);
    if (window) {
        ANativeWindow_release(window);
    }
}

extern "C" JNIEXPORT void JNICALL
Java_org_flightgear_android_MainActivity_nativeSurfaceChanged(JNIEnv*, jclass, jobject, jint width, jint height) {
    fg_android_surface_changed(width, height);
}

extern "C" JNIEXPORT void JNICALL
Java_org_flightgear_android_MainActivity_nativeSurfaceDestroyed(JNIEnv*, jclass) {
    fg_android_surface_destroyed();
}
