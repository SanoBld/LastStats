// Widget showing the current (or last played) track.

package com.example.laststats_mobile.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.laststats_mobile.R
import es.antonborri.home_widget.HomeWidgetPlugin

class NowPlayingWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)
        val track = data.getString("track_name", "") ?: ""
        val artist = data.getString("artist_name", "") ?: ""
        val playing = data.getBoolean("is_playing", false)

        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.widget_now_playing)
            if (track.isEmpty()) {
                views.setTextViewText(R.id.widget_track, "No scrobble yet")
                views.setTextViewText(R.id.widget_artist, "")
            } else {
                views.setTextViewText(R.id.widget_track, track)
                views.setTextViewText(R.id.widget_artist, artist)
            }
            views.setTextViewText(
                R.id.widget_status,
                if (playing) "▶ Now playing" else "Last played"
            )
            WidgetUtils.setOpenAppIntent(context, views, R.id.widget_root)
            manager.updateAppWidget(id, views)
        }
    }
}
