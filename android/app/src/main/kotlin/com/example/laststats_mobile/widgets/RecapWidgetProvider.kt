// Widget showing a small recap: total, weekly, loved and now playing.

package com.example.laststats_mobile.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.laststats_mobile.R
import es.antonborri.home_widget.HomeWidgetPlugin

class RecapWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)
        val total = data.getString("total_scrobbles", "0") ?: "0"
        val weekly = data.getString("weekly_scrobbles", "0") ?: "0"
        val loved = data.getString("loved_count", "0") ?: "0"
        val track = data.getString("track_name", "") ?: ""
        val artist = data.getString("artist_name", "") ?: ""

        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.widget_recap)
            views.setTextViewText(R.id.recap_total, total)
            views.setTextViewText(R.id.recap_weekly, weekly)
            views.setTextViewText(R.id.recap_loved, loved)
            views.setTextViewText(
                R.id.recap_now,
                if (track.isEmpty()) "No scrobble yet" else "$track — $artist"
            )
            WidgetUtils.setOpenAppIntent(context, views, R.id.widget_root)
            manager.updateAppWidget(id, views)
        }
    }
}
