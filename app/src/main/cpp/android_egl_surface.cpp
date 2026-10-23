#include <jni.h>
#include <android/native_window_jni.h>
#include <android/log.h>
#include <EGL/egl.h>

#define LOG_TAG "FlightGearAndroid"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace {
ANativeWindow* g_window = nullptr;
EGLDisplay g_display = EGL_NO_DISPLAY;
EGLSurface g_surface = EGL_NO_SURFACE;
EGLContext g_context = EGL_NO_CONTEXT;
}

static bool createEglSurface(ANativeWindow* window) {
    if (!window) return false;

    g_display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if (g_display == EGL_NO_DISPLAY) return false;

    EGLint major = 0, minor = 0;
    if (!eglInitialize(g_display, &major, &minor)) return false;

    const EGLint configAttribs[] = {
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
        EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
        EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8,
        EGL_BLUE_SIZE, 8, EGL_ALPHA_SIZE, 8,
        EGL_DEPTH_SIZE, 24,
        EGL_NONE
    };

    EGLConfig config = nullptr;
    EGLint count = 0;
    if (!eglChooseConfig(g_display, configAttribs, &config, 1, &count) || count == 0)
        return false;

    const EGLint contextAttribs[] = { EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE };
    g_context = eglCreateContext(g_display, config, EGL_NO_CONTEXT, contextAttribs);
    if (g_context == EGL_NO_CONTEXT) return false;

    g_surface = eglCreateWindowSurface(g_display, config, window, nullptr);
    if (g_surface == EGL_NO_SURFACE) return false;

    if (!eglMakeCurrent(g_display, g_surface, g_surface, g_context)) return false;

    LOGI("Android EGL initialized: %dx%d, GLES 2 context", ANativeWindow_getWidth(window), ANativeWindow_getHeight(window));
    return true;
}

static void destroyEgl() {
    if (g_display != EGL_NO_DISPLAY) {
        eglMakeCurrent(g_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        if (g_surface != EGL_NO_SURFACE) eglDestroySurface(g_display, g_surface);
        if (g_context != EGL_NO_CONTEXT) eglDestroyContext(g_display, g_context);
        eglTerminate(g_display);
    }
    g_display = EGL_NO_DISPLAY;
    g_surface = EGL_NO_SURFACE;
    g_context = EGL_NO_CONTEXT;
}

extern "C" JNIEXPORT void JNICALL
Java_org_flightgear_android_MainActivity_nativeSurfaceCreated(JNIEnv* env, jclass, jobject surface) {
    destroyEgl();
    if (g_window) {
        ANativeWindow_release(g_window);
        g_window = nullptr;
    }
    g_window = ANativeWindow_fromSurface(env, surface);
    if (!createEglSurface(g_window)) LOGE("Failed to create Android EGL surface");
}

extern "C" JNIEXPORT void JNICALL
Java_org_flightgear_android_MainActivity_nativeSurfaceChanged(JNIEnv*, jclass, jobject, jint width, jint height) {
    LOGI("Surface changed: %dx%d", width, height);
    if (g_display != EGL_NO_DISPLAY && g_surface != EGL_NO_SURFACE) {
        eglQuerySurface(g_display, g_surface, EGL_WIDTH, &width);
        eglQuerySurface(g_display, g_surface, EGL_HEIGHT, &height);
    }
}

extern "C" JNIEXPORT void JNICALL
Java_org_flightgear_android_MainActivity_nativeSurfaceDestroyed(JNIEnv*, jclass) {
    destroyEgl();
    if (g_window) {
        ANativeWindow_release(g_window);
        g_window = nullptr;
    }
    LOGI("Android EGL surface destroyed");
}
