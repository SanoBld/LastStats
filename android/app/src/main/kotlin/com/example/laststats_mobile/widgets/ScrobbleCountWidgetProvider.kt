// Widget showing the total scrobble count. Size-responsive: tiny (just the
// number), pill (icon + number), full (icon, number, label).

package com.example.laststats_mobile.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.laststats_mobile.R
import es.antonborri.home_widget.HomeWidgetPlugin

class ScrobbleCountWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)
        val total = data.getString("total_scrobbles", "0") ?: "0"
        val username = data.getString("username", "") ?: ""
        val palette = WidgetTheme.resolve(context, data)
        val nothing = data.getString("theme_style", "default") == "nothing"

        fun build(tinyRes: Int, pillRes: Int, fullRes: Int): RemoteViews {
            val tiny = RemoteViews(context.packageName, tinyRes)
            tiny.setInt(R.id.card_bg, "setColorFilter", palette.surface)
            tiny.setTextViewText(R.id.widget_value, total)
            tiny.setTextColor(R.id.widget_value, palette.text)
            WidgetUtils.setOpenAppIntent(context, tiny, R.id.widget_root)

            val pill = RemoteViews(context.packageName, pillRes)
            pill.setInt(R.id.card_bg, "setColorFilter", palette.surface)
            pill.setInt(R.id.icon_chip, "setColorFilter", palette.chip)
            pill.setTextViewText(R.id.widget_value, total)
            pill.setTextColor(R.id.widget_value, palette.text)
            WidgetUtils.setOpenAppIntent(context, pill, R.id.widget_root)

            val full = RemoteViews(context.packageName, fullRes)
            full.setInt(R.id.card_bg, "setColorFilter", palette.surface)
            full.setInt(R.id.icon_chip, "setColorFilter", palette.chip)
            full.setTextViewText(R.id.widget_value, total)
            full.setTextColor(R.id.widget_value, palette.text)
            full.setTextViewText(R.id.widget_label, context.getString(R.string.widget_scrobbles_label, username))
            full.setTextColor(R.id.widget_label, palette.accent)
            WidgetUtils.setOpenAppIntent(context, full, R.id.widget_root)

            return WidgetUtils.responsiveViews(context, tiny, pill, full)
        }

        val views = if (nothing) {
            build(R.layout.widget_scrobble_count_tiny_nothing, R.layout.widget_scrobble_count_pill_nothing, R.layout.widget_scrobble_count_nothing)
        } else {
            build(R.layout.widget_scrobble_count_tiny_default, R.layout.widget_scrobble_count_pill_default, R.layout.widget_scrobble_count_default)
        }
        for (id in ids) manager.updateAppWidget(id, views)
    }
}
