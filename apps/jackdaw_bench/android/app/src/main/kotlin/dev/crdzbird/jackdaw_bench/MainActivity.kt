package dev.crdzbird.jackdaw_bench

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

/** Keeps the screen on so long benchmarks are not frozen in the background. */
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
}
