// Downloads an album art bitmap for a widget. Simple and best-effort:
// any failure just leaves the placeholder background showing.

package com.example.laststats_mobile.widgets

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import java.net.URL

object WidgetImageLoader {
    // Fetch a bitmap from a URL. Runs on a background thread (caller's job).
    fun fetch(url: String): Bitmap? {
        if (url.isEmpty()) return null
        return try {
            URL(url).openStream().use { BitmapFactory.decodeStream(it) }
        } catch (_: Exception) {
            null
        }
    }

    // Round the corners so it matches the app's card style.
    fun roundCorners(bitmap: Bitmap, radiusPx: Float): Bitmap {
        val output = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val path = Path().apply {
            addRoundRect(
                0f, 0f, bitmap.width.toFloat(), bitmap.height.toFloat(),
                radiusPx, radiusPx, Path.Direction.CW
            )
        }
        canvas.clipPath(path)
        canvas.drawBitmap(bitmap, 0f, 0f, paint)
        return output
    }
}
