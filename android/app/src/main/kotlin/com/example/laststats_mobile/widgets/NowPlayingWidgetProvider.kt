// Widget showing the current (or last played) track, with album art.

package com.example.laststats_mobile.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Bitmap
import android.widget.RemoteViews
import com.example.laststats_mobile.R
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlin.concurrent.thread

class NowPlayingWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        draw(context, manager, ids)
        // Pull fresh data straight from Last.fm so the widget is never stale.
        val pending = try { goAsync() } catch (_: Throwable) { null }
        WidgetRefresher.refresh(context, NowPlayingWidgetProvider::class.java, track = true) { changed ->
            try { if (changed) draw(context, manager, ids) } finally { pending?.finish() }
        }
    }

    // Resizing: redraw so the card background matches the new size (keeps corners round).
    override fun onAppWidgetOptionsChanged(
        context: Context, manager: AppWidgetManager, id: Int, newOptions: android.os.Bundle
    ) {
        draw(context, manager, intArrayOf(id))
    }

    private fun draw(
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
        fun build(id: Int, art: Bitmap?): RemoteViews {
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
                WidgetBackground.apply(context, manager, id, views, palette)
                views.setInt(R.id.status_bg, "setColorFilter", palette.chip)
                views.setTextColor(R.id.widget_status, palette.onChip)
                views.setTextColor(R.id.widget_track, palette.text)
                views.setTextColor(R.id.widget_artist, palette.muted)
            }
            if (art != null) views.setImageViewBitmap(R.id.widget_art, art)
            WidgetUtils.setOpenAppIntent(context, views, R.id.widget_root)
            return views
        }
        for (id in ids) manager.updateAppWidget(id, build(id, null))

        // Album art loads async — push a second update once it's ready.
        thread {
            val bitmap = (if (nothing) WidgetImageLoader.fetch(artUrl, 720, 0f) else WidgetImageLoader.fetch(artUrl)) ?: return@thread
            for (id in ids) manager.updateAppWidget(id, build(id, bitmap))
        }
    }
}
