package org.flightgear.android;

import android.app.Activity;
import android.os.Bundle;
import android.view.Window;
import android.view.WindowManager;
import android.widget.TextView;

public class MainActivity extends Activity {
    static { System.loadLibrary("flightgear_android"); }

    private native void nativeInit();

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);
        TextView view = new TextView(this);
        view.setText("FlightGear Android\nNative ARM64 engine bootstrap");
        view.setTextSize(20);
        view.setPadding(40, 40, 40, 40);
        setContentView(view);
        nativeInit();
    }
}
