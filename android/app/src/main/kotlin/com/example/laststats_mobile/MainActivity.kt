package com.example.laststats_mobile

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import android.view.WindowManager
import androidx.core.content.FileProvider
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "laststats/installer")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "canInstall" -> result.success(
                            Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
                                packageManager.canRequestPackageInstalls())
                        "openSettings" -> {
                            startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                Uri.parse("package:$packageName")))
                            result.success(true)
                        }
                        "install" -> {
                            val file = File(call.argument<String>("path")!!)
                            val uri = FileProvider.getUriForFile(this, "$packageName.updatefileprovider", file)
                            val i = Intent(Intent.ACTION_VIEW)
                                .setDataAndType(uri, "application/vnd.android.package-archive")
                                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(i)
                            result.success(true)
                        }
                        "saveToDownloads" -> {
                            val src  = File(call.argument<String>("path")!!)
                            val name = call.argument<String>("name")!!
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                val mime = if (name.endsWith(".apk", true))
                                    "application/vnd.android.package-archive" else "application/octet-stream"
                                val values = ContentValues().apply {
                                    put(MediaStore.Downloads.DISPLAY_NAME, name)
                                    put(MediaStore.Downloads.MIME_TYPE, mime)
                                    put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                                    put(MediaStore.Downloads.IS_PENDING, 1)
                                }
                                val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)!!
                                contentResolver.openOutputStream(uri)!!.use { out ->
                                    src.inputStream().use { it.copyTo(out) }
                                }
                                values.clear()
                                values.put(MediaStore.Downloads.IS_PENDING, 0)
                                contentResolver.update(uri, values, null, null)
                                result.success("Downloads/$name")
                            } else {
                                val dir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)!!
                                val dst = File(dir, name)
                                src.copyTo(dst, true)
                                result.success(dst.absolutePath)
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.success(false)
                }
            }
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
