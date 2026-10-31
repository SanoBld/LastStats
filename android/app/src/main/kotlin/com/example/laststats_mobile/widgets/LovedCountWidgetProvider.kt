// Widget showing loved tracks count. Size-responsive: tiny/pill/full.

package com.example.laststats_mobile.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.laststats_mobile.R
import es.antonborri.home_widget.HomeWidgetPlugin

class LovedCountWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        draw(context, manager, ids)
        // Pull fresh data straight from Last.fm so the widget is never stale.
        val pending = try { goAsync() } catch (_: Throwable) { null }
        WidgetRefresher.refresh(context) { changed ->
            try { if (changed) draw(context, manager, ids) } finally { pending?.finish() }
        }
    }

    // Resizing: redraw so the card background matches the new size (keeps corners round).
    override fun onAppWidgetOptionsChanged(
        context: Context, manager: AppWidgetManager, id: Int, newOptions: android.os.Bundle
    ) {
        draw(context, manager, intArrayOf(id))
    }

    private fun draw(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)
        val loved = data.getString("loved_count", "0") ?: "0"
        val palette = WidgetTheme.resolve(context, data)
        val nothing = data.getString("theme_style", "default") == "nothing"

        fun build(id: Int, tinyRes: Int, pillRes: Int, fullRes: Int): RemoteViews {
            val tiny = RemoteViews(context.packageName, tinyRes)
            if (nothing) tiny.setInt(R.id.card_bg, "setColorFilter", palette.surface)
            else WidgetBackground.apply(context, manager, id, tiny, palette)
            tiny.setTextViewText(R.id.widget_value, loved)
            tiny.setTextColor(R.id.widget_value, palette.text)
            WidgetUtils.setOpenAppIntent(context, tiny, R.id.widget_root)

            val pill = RemoteViews(context.packageName, pillRes)
            if (nothing) pill.setInt(R.id.card_bg, "setColorFilter", palette.surface)
            else WidgetBackground.apply(context, manager, id, pill, palette)
            pill.setInt(R.id.icon_chip, "setColorFilter", palette.chip)
            if (!nothing) pill.setInt(R.id.icon_glyph, "setColorFilter", palette.onChip)
            pill.setTextViewText(R.id.widget_value, loved)
            pill.setTextColor(R.id.widget_value, palette.text)
            WidgetUtils.setOpenAppIntent(context, pill, R.id.widget_root)

            val full = RemoteViews(context.packageName, fullRes)
            if (nothing) full.setInt(R.id.card_bg, "setColorFilter", palette.surface)
            else WidgetBackground.apply(context, manager, id, full, palette)
            full.setInt(R.id.icon_chip, "setColorFilter", palette.chip)
            if (!nothing) full.setInt(R.id.icon_glyph, "setColorFilter", palette.onChip)
            full.setTextViewText(R.id.widget_value, loved)
            full.setTextColor(R.id.widget_value, palette.text)
            full.setTextViewText(R.id.widget_label, context.getString(R.string.widget_loved_label))
            full.setTextColor(R.id.widget_label, palette.accent)
            WidgetUtils.setOpenAppIntent(context, full, R.id.widget_root)

            return WidgetUtils.responsiveViews(context, tiny, pill, full)
        }

        for (id in ids) {
        val views = if (nothing) {
            build(id, R.layout.widget_loved_count_tiny_nothing, R.layout.widget_loved_count_pill_nothing, R.layout.widget_loved_count_nothing)
        } else {
            build(id, R.layout.widget_loved_count_tiny_default, R.layout.widget_loved_count_pill_default, R.layout.widget_loved_count_default)
        }
        manager.updateAppWidget(id, views)
        }
    }
}
