// Widget showing the number of loved (liked) tracks.

package com.example.laststats_mobile.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.laststats_mobile.R
import es.antonborri.home_widget.HomeWidgetPlugin

class LovedCountWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)
        val loved = data.getString("loved_count", "0") ?: "0"
        val palette = WidgetTheme.resolve(context, data)
        val layout = WidgetTheme.layoutFor(
            data, R.layout.widget_loved_count_nothing, R.layout.widget_loved_count_default
        )

        for (id in ids) {
            val views = RemoteViews(context.packageName, layout)
            views.setInt(R.id.card_bg, "setColorFilter", palette.surface)
            views.setInt(R.id.icon_chip, "setColorFilter", palette.chip)
            views.setTextViewText(R.id.widget_value, loved)
            views.setTextColor(R.id.widget_value, palette.text)
            views.setTextViewText(R.id.widget_label, context.getString(R.string.widget_loved_label))
            views.setTextColor(R.id.widget_label, palette.accent)
            WidgetUtils.setOpenAppIntent(context, views, R.id.widget_root)
            manager.updateAppWidget(id, views)
        }
    }
}
