package org.flightgear.android;

import android.app.Activity;
import android.os.Build;
import android.os.Bundle;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.Window;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;

public class MainActivity extends Activity implements SurfaceHolder.Callback {
    static {
        System.loadLibrary("flightgear_android");
    }

    private SurfaceView surfaceView;
    private boolean nativeSurfaceReady;

    private static native void nativeSurfaceCreated(Surface surface);
    private static native void nativeSurfaceChanged(Surface surface, int width, int height);
    private static native void nativeSurfaceDestroyed();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN
                | WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        surfaceView = new SurfaceView(this);
        surfaceView.getHolder().addCallback(this);
        setContentView(surfaceView);
        enterImmersiveMode();
    }

    @Override
    protected void onResume() {
        super.onResume();
        enterImmersiveMode();
        resumeNativeSurfaceIfAvailable();
    }

    @Override
    protected void onPause() {
        pauseNativeSurface();
        super.onPause();
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) {
            enterImmersiveMode();
        }
    }

    private void enterImmersiveMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            WindowInsetsController controller = getWindow().getInsetsController();
            if (controller != null) {
                controller.hide(WindowInsets.Type.statusBars()
                        | WindowInsets.Type.navigationBars());
                controller.setSystemBarsBehavior(
                        WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
            }
        } else {
            int flags = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    | View.SYSTEM_UI_FLAG_FULLSCREEN
                    | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY;
            getWindow().getDecorView().setSystemUiVisibility(flags);
        }
    }

    private void resumeNativeSurfaceIfAvailable() {
        if (surfaceView == null || nativeSurfaceReady) {
            return;
        }

        SurfaceHolder holder = surfaceView.getHolder();
        Surface surface = holder.getSurface();
        if (surface != null && surface.isValid()) {
            startNativeSurface(surface);
            android.graphics.Rect frame = holder.getSurfaceFrame();
            nativeSurfaceChanged(surface, frame.width(), frame.height());
        }
    }

    private void startNativeSurface(Surface surface) {
        if (!nativeSurfaceReady && surface != null && surface.isValid()) {
            nativeSurfaceCreated(surface);
            nativeSurfaceReady = true;
        }
    }

    private void pauseNativeSurface() {
        if (nativeSurfaceReady) {
            nativeSurfaceDestroyed();
            nativeSurfaceReady = false;
        }
    }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        startNativeSurface(holder.getSurface());
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
        if (nativeSurfaceReady) {
            nativeSurfaceChanged(holder.getSurface(), width, height);
        }
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        pauseNativeSurface();
    }
}
