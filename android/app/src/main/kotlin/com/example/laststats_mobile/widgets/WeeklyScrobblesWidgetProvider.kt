// Widget showing scrobbles from the last 7 days. Size-responsive: tiny/pill/full.

package com.example.laststats_mobile.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.laststats_mobile.R
import es.antonborri.home_widget.HomeWidgetPlugin

class WeeklyScrobblesWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)
        val weekly = data.getString("weekly_scrobbles", "0") ?: "0"
        val palette = WidgetTheme.resolve(context, data)
        val nothing = data.getString("theme_style", "default") == "nothing"

        fun build(tinyRes: Int, pillRes: Int, fullRes: Int): RemoteViews {
            val tiny = RemoteViews(context.packageName, tinyRes)
            tiny.setInt(R.id.card_bg, "setColorFilter", palette.surface)
            tiny.setTextViewText(R.id.widget_value, weekly)
            tiny.setTextColor(R.id.widget_value, palette.text)
            WidgetUtils.setOpenAppIntent(context, tiny, R.id.widget_root)

            val pill = RemoteViews(context.packageName, pillRes)
            pill.setInt(R.id.card_bg, "setColorFilter", palette.surface)
            pill.setInt(R.id.icon_chip, "setColorFilter", palette.chip)
            pill.setTextViewText(R.id.widget_value, weekly)
            pill.setTextColor(R.id.widget_value, palette.text)
            WidgetUtils.setOpenAppIntent(context, pill, R.id.widget_root)

            val full = RemoteViews(context.packageName, fullRes)
            full.setInt(R.id.card_bg, "setColorFilter", palette.surface)
            full.setInt(R.id.icon_chip, "setColorFilter", palette.chip)
            full.setTextViewText(R.id.widget_value, weekly)
            full.setTextColor(R.id.widget_value, palette.text)
            full.setTextViewText(R.id.widget_label, context.getString(R.string.widget_weekly_label))
            full.setTextColor(R.id.widget_label, palette.accent)
            WidgetUtils.setOpenAppIntent(context, full, R.id.widget_root)

            return WidgetUtils.responsiveViews(context, tiny, pill, full)
        }

        val views = if (nothing) {
            build(R.layout.widget_weekly_scrobbles_tiny_nothing, R.layout.widget_weekly_scrobbles_pill_nothing, R.layout.widget_weekly_scrobbles_nothing)
        } else {
            build(R.layout.widget_weekly_scrobbles_tiny_default, R.layout.widget_weekly_scrobbles_pill_default, R.layout.widget_weekly_scrobbles_default)
        }
        for (id in ids) manager.updateAppWidget(id, views)
    }
}
