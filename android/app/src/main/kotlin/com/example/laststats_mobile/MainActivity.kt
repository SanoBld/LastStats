package com.example.laststats_mobile

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Battery saver: asks Android for a low refresh rate ("low") or the
        // highest one ("high") at the CURRENT resolution. Setting
        // preferredRefreshRate too (not only the mode id) is what makes
        // phones with an adaptive 120 Hz screen really drop to 60 Hz.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "laststats/refresh")
            .setMethodCallHandler { call, result ->
                if (call.method != "set") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val low = call.argument<String>("mode") == "low"
                runOnUiThread {
                    try {
                        @Suppress("DEPRECATION")
                        val display = windowManager.defaultDisplay
                        val cur = display.mode
                        val same = display.supportedModes.filter {
                            it.physicalWidth == cur.physicalWidth &&
                                it.physicalHeight == cur.physicalHeight
                        }
                        val target = if (low) {
                            // lowest rate that is still smooth (>= 55 Hz), else the lowest
                            same.filter { it.refreshRate >= 55f }.minByOrNull { it.refreshRate }
                                ?: same.minByOrNull { it.refreshRate }
                        } else {
                            same.maxByOrNull { it.refreshRate }
                        }
                        val lp: WindowManager.LayoutParams = window.attributes
                        if (target != null) {
                            lp.preferredDisplayModeId = target.modeId
                            lp.preferredRefreshRate = target.refreshRate
                        } else {
                            lp.preferredDisplayModeId = 0
                            lp.preferredRefreshRate = 0f
                        }
                        window.attributes = lp
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
            }
    }
}
