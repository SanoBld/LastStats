// Widget showing a small recap: total, weekly, loved and now playing.

package com.example.laststats_mobile.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.laststats_mobile.R
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlin.concurrent.thread

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
        val artUrl = data.getString("track_art", "") ?: ""
        val palette = WidgetTheme.resolve(context, data)
        val layout = WidgetTheme.layoutFor(
            data, R.layout.widget_recap_nothing, R.layout.widget_recap_default
        )

        val views = RemoteViews(context.packageName, layout)
        views.setInt(R.id.widget_root, "setBackgroundResource", palette.bgDrawableRes)
        views.setTextViewText(R.id.recap_total, total)
        views.setTextViewText(R.id.recap_weekly, weekly)
        views.setTextViewText(R.id.recap_loved, loved)
        for (i in intArrayOf(R.id.recap_total, R.id.recap_weekly, R.id.recap_loved)) {
            views.setTextColor(i, palette.text)
        }
        views.setTextViewText(
            R.id.recap_now,
            if (track.isEmpty()) "No scrobble yet" else "$track — $artist"
        )
        views.setTextColor(R.id.recap_now, palette.text)
        views.setInt(R.id.accent_bar, "setBackgroundColor", palette.accent)
        WidgetUtils.setOpenAppIntent(context, views, R.id.widget_root)
        for (id in ids) manager.updateAppWidget(id, views)

        thread {
            val bitmap = WidgetImageLoader.fetch(artUrl)?.let {
                WidgetImageLoader.roundCorners(it, 14f)
            } ?: return@thread
            views.setImageViewBitmap(R.id.recap_art, bitmap)
            for (id in ids) manager.updateAppWidget(id, views)
        }
    }
}
