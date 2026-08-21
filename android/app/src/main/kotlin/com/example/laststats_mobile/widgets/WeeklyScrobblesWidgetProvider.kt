// Widget showing scrobbles from the last 7 days.

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
        val layout = WidgetTheme.layoutFor(
            data, R.layout.widget_weekly_scrobbles_nothing, R.layout.widget_weekly_scrobbles_default
        )

        for (id in ids) {
            val views = RemoteViews(context.packageName, layout)
            views.setInt(R.id.card_bg, "setColorFilter", palette.surface)
            views.setInt(R.id.icon_chip, "setColorFilter", palette.chip)
            views.setTextViewText(R.id.widget_value, weekly)
            views.setTextColor(R.id.widget_value, palette.text)
            views.setTextViewText(R.id.widget_label, "scrobbles this week")
            views.setTextColor(R.id.widget_label, palette.accent)
            WidgetUtils.setOpenAppIntent(context, views, R.id.widget_root)
            manager.updateAppWidget(id, views)
        }
    }
}
