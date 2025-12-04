package com.example.silsila_dawrah

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Allow screen recording and screenshots
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
