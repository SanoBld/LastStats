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

        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.widget_loved_count)
            views.setTextViewText(R.id.widget_value, loved)
            views.setTextViewText(R.id.widget_label, "loved tracks ♥")
            WidgetUtils.setOpenAppIntent(context, views, R.id.widget_root)
            manager.updateAppWidget(id, views)
        }
    }
}
