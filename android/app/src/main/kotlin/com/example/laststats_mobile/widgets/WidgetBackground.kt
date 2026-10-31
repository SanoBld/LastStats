// Draws the widget card in the same "poster" style as the app's share images:
// one flat color, big rounded corners and soft cookie-shaped blobs in the
// corners (see lib/widgets/share_card.dart, ShareCardFrame.solid).

package com.example.laststats_mobile.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RectF
import android.widget.RemoteViews
import com.example.laststats_mobile.R
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sin

object WidgetBackground {
    private const val MAX_SIDE = 640

    // Same maths as M3CookieBorder in lib/theme/m3_shapes.dart.
    private fun cookie(cx: Float, cy: Float, size: Float, lobes: Int, amplitude: Float): Path {
        val r = size / 2f
        val path = Path()
        val steps = 120
        for (i in 0..steps) {
            val a = (i.toFloat() / steps) * (PI.toFloat() * 2f)
            val k = 1f - amplitude * (1f - cos(lobes * a)) / 2f
            val x = cx + r * k * cos(a)
            val y = cy + r * k * sin(a)
            if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }
        path.close()
        return path
    }

    private fun withAlpha(color: Int, alpha: Float): Int =
        Color.argb((alpha * 255).toInt(), Color.red(color), Color.green(color), Color.blue(color))

    private fun blend(base: Int, over: Int, ratio: Float): Int = Color.rgb(
        (Color.red(base) * (1 - ratio) + Color.red(over) * ratio).toInt(),
        (Color.green(base) * (1 - ratio) + Color.green(over) * ratio).toInt(),
        (Color.blue(base) * (1 - ratio) + Color.blue(over) * ratio).toInt())

    /** Current size of one widget in pixels (capped, so the bitmap stays small). */
    private fun sizePx(context: Context, manager: AppWidgetManager, id: Int): Triple<Int, Int, Float> {
        val d = context.resources.displayMetrics.density
        val o = manager.getAppWidgetOptions(id)
        val land = context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
        val wDp = o.getInt(if (land) AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH
                           else AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val hDp = o.getInt(if (land) AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT
                           else AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
        var w = (if (wDp > 0) wDp else 160) * d
        var h = (if (hDp > 0) hDp else 160) * d
        val big = maxOf(w, h)
        var f = 1f
        if (big > MAX_SIDE) { f = MAX_SIDE / big; w *= f; h *= f }
        return Triple(w.toInt().coerceAtLeast(40), h.toInt().coerceAtLeast(40), f)
    }

    fun render(context: Context, p: WidgetPalette, w: Int, h: Int, scale: Float): Bitmap {
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val corner = min(
            context.resources.getDimension(R.dimen.widget_corner) * scale,
            min(w, h) / 2f)
        // flat poster color: surface + a touch of the container color
        paint.color = blend(p.surface, p.chip, p.posterMix)
        c.drawRoundRect(RectF(0f, 0f, w.toFloat(), h.toFloat()), corner, corner, paint)

        // blobs only where the card is already drawn (keeps the rounded corners)
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_ATOP)
        val s = min(w, h).toFloat()
        paint.color = withAlpha(p.accent, 0.12f)
        c.drawPath(cookie(w - 0.12f * s, 0.12f * s, 0.9f * s, 8, 0.07f), paint)
        paint.color = withAlpha(p.tertiary, 0.11f)
        c.drawPath(cookie(0.02f * s, h - 0.02f * s, 0.8f * s, 12, 0.07f), paint)
        paint.color = withAlpha(p.secondary, 0.08f)
        c.drawPath(cookie(w + 0.05f * s, h * 0.58f, 0.6f * s, 6, 0.12f), paint)
        return bmp
    }

    /** Sets the poster-style background on [views] for widget [id]. */
    fun apply(context: Context, manager: AppWidgetManager, id: Int, views: RemoteViews, p: WidgetPalette) {
        try {
            val (w, h, f) = sizePx(context, manager, id)
            views.setImageViewBitmap(R.id.card_bg, render(context, p, w, h, f))
        } catch (_: Throwable) {
            views.setInt(R.id.card_bg, "setColorFilter", p.surface)
        }
    }
}
