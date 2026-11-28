package com.otlobegy.customer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun getRenderMode(): RenderMode {
        return RenderMode.texture
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        FlutterScrollCaptureHelper.attach(this, flutterEngine)
    }

    override fun onPostResume() {
        super.onPostResume()
        flutterEngine?.let { FlutterScrollCaptureHelper.attach(this, it) }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        FlutterScrollCaptureHelper.detach(this)
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
