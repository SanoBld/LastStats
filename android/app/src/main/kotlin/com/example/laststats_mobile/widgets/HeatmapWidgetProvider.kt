// Listening calendar widget: small squares, one per day (like GitHub).

package com.example.laststats_mobile.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.widget.RemoteViews
import com.example.laststats_mobile.R
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import java.util.Calendar

class HeatmapWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        draw(context, manager, ids)
        // Only today's number is fetched here (cheap); older days come from the app.
        val pending = try { goAsync() } catch (_: Throwable) { null }
        WidgetRefresher.refresh(context, HeatmapWidgetProvider::class.java, today = true) { changed ->
            try { if (changed) draw(context, manager, ids) } finally { pending?.finish() }
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context, manager: AppWidgetManager, id: Int, newOptions: android.os.Bundle
    ) {
        draw(context, manager, intArrayOf(id))
    }

    private fun mix(base: Int, over: Int, r: Float) = Color.rgb(
        (Color.red(base) * (1 - r) + Color.red(over) * r).toInt(),
        (Color.green(base) * (1 - r) + Color.green(over) * r).toInt(),
        (Color.blue(base) * (1 - r) + Color.blue(over) * r).toInt())

    private fun key(c: Calendar) = String.format(
        "%04d-%02d-%02d", c.get(Calendar.YEAR), c.get(Calendar.MONTH) + 1, c.get(Calendar.DAY_OF_MONTH))

    private fun draw(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val data = HomeWidgetPlugin.getData(context)
        val palette = WidgetTheme.resolve(context, data)
        val nothing = data.getString("theme_style", "default") == "nothing"
        val counts = HashMap<String, Int>()
        try {
            val j = JSONObject(data.getString("heatmap_days", "{}") ?: "{}")
            for (k in j.keys()) counts[k] = j.optInt(k)
        } catch (_: Throwable) { }
        val d = context.resources.displayMetrics.density

        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.widget_heatmap)
            if (nothing) views.setInt(R.id.card_bg, "setColorFilter", palette.surface)
            else WidgetBackground.apply(context, manager, id, views, palette)
            val o = manager.getAppWidgetOptions(id)
            val wDp = o.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 160).coerceAtLeast(60)
            val hDp = o.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 110).coerceAtLeast(40)
            views.setImageViewBitmap(R.id.heat_img, render(counts, palette, (wDp * d).toInt(), (hDp * d).toInt(), d))
            WidgetUtils.setOpenAppIntent(context, views, R.id.widget_root)
            manager.updateAppWidget(id, views)
        }
    }

    private fun render(counts: Map<String, Int>, p: WidgetPalette, w: Int, h: Int, d: Float): Bitmap {
        val bmp = Bitmap.createBitmap(w.coerceAtMost(900), h.coerceAtMost(900), Bitmap.Config.ARGB_8888)
        val bw = bmp.width.toFloat(); val bh = bmp.height.toFloat()
        val c = Canvas(bmp)
        val pad = 14 * d
        val gap = 3 * d
        // 7 rows fill the height; columns fill the width (newest on the right).
        val cell = ((bh - 2 * pad - 6 * gap) / 7f).coerceIn(4 * d, 22 * d)
        val cols = (((bw - 2 * pad + gap) / (cell + gap)).toInt()).coerceIn(2, 30)
        val gridW = cols * cell + (cols - 1) * gap
        val gridH = 7 * cell + 6 * gap
        val left = (bw - gridW) / 2f
        val top = (bh - gridH) / 2f

        val today = Calendar.getInstance()
        val startOffset = (today.get(Calendar.DAY_OF_WEEK) + 5) % 7   // Monday = 0
        val max = counts.values.maxOrNull()?.coerceAtLeast(1) ?: 1
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val empty = mix(p.surface, p.text, 0.10f)
        val rect = RectF()
        val day = Calendar.getInstance()
        for (col in 0 until cols) for (row in 0 until 7) {
            // Days back from today; the last column ends on today's weekday.
            val back = (cols - 1 - col) * 7 + (startOffset - row)
            if (back < 0) continue
            day.timeInMillis = today.timeInMillis
            day.add(Calendar.DAY_OF_YEAR, -back)
            val n = counts[key(day)] ?: 0
            paint.color = if (n == 0) empty else {
                val r = n.toFloat() / max
                mix(p.surface, p.accent, when { r > 0.75f -> 1f; r > 0.5f -> 0.75f; r > 0.25f -> 0.5f; else -> 0.3f })
            }
            val x = left + col * (cell + gap)
            val y = top + row * (cell + gap)
            rect.set(x, y, x + cell, y + cell)
            c.drawRoundRect(rect, cell * 0.28f, cell * 0.28f, paint)
        }
        return bmp
    }
}
