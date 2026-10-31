// Widget showing the current (or last played) track, with album art.

package com.example.laststats_mobile.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.laststats_mobile.R
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlin.concurrent.thread

class NowPlayingWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)
        val track = data.getString("track_name", "") ?: ""
        val artist = data.getString("artist_name", "") ?: ""
        val artUrl = data.getString("track_art", "") ?: ""
        val playing = data.getBoolean("is_playing", false)
        val palette = WidgetTheme.resolve(context, data)
        val layout = WidgetTheme.layoutFor(
            data, R.layout.widget_now_playing_nothing, R.layout.widget_now_playing_default
        )

        val nothing = (data.getString("theme_style", "default") ?: "default") == "nothing"
        val views = RemoteViews(context.packageName, layout)
        if (track.isEmpty()) {
            views.setTextViewText(R.id.widget_track, context.getString(R.string.widget_no_scrobble))
            views.setTextViewText(R.id.widget_artist, "")
        } else {
            views.setTextViewText(R.id.widget_track, track)
            views.setTextViewText(R.id.widget_artist, artist)
        }
        views.setTextViewText(
            R.id.widget_status,
            if (playing) context.getString(R.string.widget_now_playing_status)
            else context.getString(R.string.widget_last_played_status)
        )
        if (nothing) {
            // Text sits over a photo + dark scrim in the Nothing layout.
            views.setTextColor(R.id.widget_status, palette.accent)
        } else {
            // Material You layout: colors come from the system color resources;
            // only the card surface is tinted here.
            views.setInt(R.id.card_bg, "setColorFilter", palette.surface)
        }
        WidgetUtils.setOpenAppIntent(context, views, R.id.widget_root)
        for (id in ids) manager.updateAppWidget(id, views)

        // Album art loads async — push a second update once it's ready.
        thread {
            val bitmap = (if (nothing) WidgetImageLoader.fetch(artUrl, 720, 0f) else WidgetImageLoader.fetch(artUrl)) ?: return@thread
            views.setImageViewBitmap(R.id.widget_art, bitmap)
            for (id in ids) manager.updateAppWidget(id, views)
        }
    }
}
