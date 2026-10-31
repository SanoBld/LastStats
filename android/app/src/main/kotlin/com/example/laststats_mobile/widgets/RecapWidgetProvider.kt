// Widget showing a small recap: total, weekly, loved and now playing.

package com.example.laststats_mobile.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Bitmap
import android.widget.RemoteViews
import com.example.laststats_mobile.R
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlin.concurrent.thread

class RecapWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        draw(context, manager, ids)
        // Pull fresh data straight from Last.fm so the widget is never stale.
        val pending = try { goAsync() } catch (_: Throwable) { null }
        WidgetRefresher.refresh(context, RecapWidgetProvider::class.java, track = true, total = true, loved = true, weekly = true) { changed ->
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
        val total = data.getString("total_scrobbles", "0") ?: "0"
        val weekly = data.getString("weekly_scrobbles", "0") ?: "0"
        val loved = data.getString("loved_count", "0") ?: "0"
        val track = data.getString("track_name", "") ?: ""
        val artist = data.getString("artist_name", "") ?: ""
        val artUrl = data.getString("track_art", "") ?: ""
        val palette = WidgetTheme.resolve(context, data)
        val nothing = data.getString("theme_style", "default") == "nothing"
        val layout = WidgetTheme.layoutFor(
            data, R.layout.widget_recap_nothing, R.layout.widget_recap_default
        )

        fun build(id: Int, art: Bitmap?): RemoteViews {
            val views = RemoteViews(context.packageName, layout)
            if (nothing) views.setInt(R.id.card_bg, "setColorFilter", palette.surface)
            else {
                WidgetBackground.apply(context, manager, id, views, palette)
                // stat tiles, like ShareTile in the app
                for (t in intArrayOf(R.id.recap_tile_total, R.id.recap_tile_week, R.id.recap_tile_loved)) {
                    views.setInt(t, "setColorFilter", palette.chip)
                    views.setInt(t, "setImageAlpha", 180)
                }
            }
            views.setTextViewText(R.id.recap_total, total)
            views.setTextViewText(R.id.recap_weekly, weekly)
            views.setTextViewText(R.id.recap_loved, loved)
            for (i in intArrayOf(R.id.recap_total, R.id.recap_weekly, R.id.recap_loved)) {
                views.setTextColor(i, if (nothing) palette.text else palette.onChip)
            }
            views.setTextViewText(
                R.id.recap_now,
                if (track.isEmpty()) context.getString(R.string.widget_no_scrobble) else "$track — $artist"
            )
            views.setTextColor(R.id.recap_now, palette.text)
            if (!nothing) {
                for (i in intArrayOf(R.id.recap_lbl_total, R.id.recap_lbl_week, R.id.recap_lbl_loved)) {
                    views.setTextColor(i, palette.onChip)
                }
            }
            if (art != null) views.setImageViewBitmap(R.id.recap_art, art)
            WidgetUtils.setOpenAppIntent(context, views, R.id.widget_root)
            return views
        }
        for (id in ids) manager.updateAppWidget(id, build(id, null))

        thread {
            val bitmap = WidgetImageLoader.fetch(artUrl)?.let {
                WidgetImageLoader.roundCorners(it, 14f)
            } ?: return@thread
            for (id in ids) manager.updateAppWidget(id, build(id, bitmap))
        }
    }
}
