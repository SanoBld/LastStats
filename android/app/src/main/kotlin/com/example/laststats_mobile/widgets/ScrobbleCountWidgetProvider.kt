// Widget showing the total scrobble count.

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

        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.widget_scrobble_count)
            views.setTextViewText(R.id.widget_value, total)
            views.setTextViewText(R.id.widget_label, "scrobbles · $username")
            WidgetUtils.setOpenAppIntent(context, views, R.id.widget_root)
            manager.updateAppWidget(id, views)
        }
    }
}
