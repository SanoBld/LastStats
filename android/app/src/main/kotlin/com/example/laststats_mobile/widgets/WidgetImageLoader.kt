// Downloads an album art bitmap for a widget. Best-effort: any failure just
// leaves the placeholder showing. The bitmap is cropped square, downscaled
// (RemoteViews have a size limit) and rounded so it matches the card style.

package com.example.laststats_mobile.widgets

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import java.net.HttpURLConnection
import java.net.URL

object WidgetImageLoader {
    fun fetch(url: String, maxPx: Int = 360, cornerFraction: Float = 0.16f): Bitmap? {
        if (url.isEmpty()) return null
        return try {
            val conn = URL(url).openConnection() as HttpURLConnection
            conn.connectTimeout = 8000
            conn.readTimeout = 8000
            conn.instanceFollowRedirects = true
            conn.setRequestProperty("User-Agent", "LastStats")
            val raw = conn.inputStream.use { BitmapFactory.decodeStream(it) } ?: return null
            val side = minOf(raw.width, raw.height)
            var out = Bitmap.createBitmap(raw, (raw.width - side) / 2, (raw.height - side) / 2, side, side)
            if (side > maxPx) out = Bitmap.createScaledBitmap(out, maxPx, maxPx, true)
            if (cornerFraction > 0f) roundCorners(out, out.width * cornerFraction) else out
        } catch (_: Exception) {
            null
        }
    }

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
