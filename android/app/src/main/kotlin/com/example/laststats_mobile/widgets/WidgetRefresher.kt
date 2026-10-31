// Refreshes widget data straight from Last.fm, without the app running.
// Battery friendly: each widget only asks for what it shows, and every
// request type has its own minimum delay.

package com.example.laststats_mobile.widgets

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import kotlin.concurrent.thread

object WidgetRefresher {
    private const val TRACK_EVERY_MS = 45_000L
    private const val COUNTS_EVERY_MS = 15 * 60_000L
    private const val PLACEHOLDER = "2a96cbd8b46e442fc41c2b86b821562f"

    private fun get(url: String): JSONObject? = try {
        val c = URL(url).openConnection() as HttpURLConnection
        c.connectTimeout = 4000
        c.readTimeout = 4000
        c.setRequestProperty("User-Agent", "LastStats")
        c.inputStream.bufferedReader().use { JSONObject(it.readText()) }
    } catch (_: Throwable) { null }

    private fun api(method: String, user: String, key: String, extra: String = ""): JSONObject? =
        get("https://ws.audioscrobbler.com/2.0/?method=$method&user=${URLEncoder.encode(user, "UTF-8")}" +
            "&api_key=$key&format=json$extra")

    private fun pickImage(images: JSONArray?): String {
        if (images == null) return ""
        for (i in images.length() - 1 downTo 0) {
            val url = images.optJSONObject(i)?.optString("#text") ?: ""
            if (url.isNotEmpty() && !url.contains(PLACEHOLDER)) return url
        }
        return ""
    }

    /**
     * Runs in the background; [done] gets true when stored data changed.
     * Ask only for what the widget shows: [track] = current song,
     * [total] / [loved] / [weekly] = the matching counters.
     */
    fun refresh(
        context: Context,
        caller: Class<*>? = null,
        track: Boolean = false,
        total: Boolean = false,
        loved: Boolean = false,
        weekly: Boolean = false,
        today: Boolean = false,
        done: (Boolean) -> Unit
    ) {
        val data = HomeWidgetPlugin.getData(context)
        val user = data.getString("username", "") ?: ""
        val key = data.getString("api_key", "") ?: ""
        if (user.isEmpty() || key.isEmpty()) { done(false); return }
        val now = System.currentTimeMillis()
        val doTrack = track && now - data.getLong("native_track_at", 0L) >= TRACK_EVERY_MS
        val doTotal = total && now - data.getLong("native_total_at", 0L) >= COUNTS_EVERY_MS
        val doLoved = loved && now - data.getLong("native_loved_at", 0L) >= COUNTS_EVERY_MS
        val doWeekly = weekly && now - data.getLong("native_weekly_at", 0L) >= COUNTS_EVERY_MS
        val doToday = today && now - data.getLong("native_today_at", 0L) >= 5 * 60_000L
        if (!doTrack && !doTotal && !doLoved && !doWeekly && !doToday) { done(false); return }
        thread {
            var changed = false
            try {
                val edit = data.edit()

                if (doTrack) {
                    edit.putLong("native_track_at", now)
                    val recent = api("user.getrecenttracks", user, key, "&limit=1")
                    val tracks = recent?.optJSONObject("recenttracks")?.opt("track")
                    val t = when (tracks) {
                        is JSONArray -> tracks.optJSONObject(0)
                        is JSONObject -> tracks
                        else -> null
                    }
                    if (t != null) {
                        val name = t.optString("name")
                        val artistObj = t.opt("artist")
                        val artist = if (artistObj is JSONObject) artistObj.optString("#text") else (artistObj?.toString() ?: "")
                        val playing = t.optJSONObject("@attr")?.optString("nowplaying") == "true"
                        var art = pickImage(t.optJSONArray("image"))
                        val oldName = data.getString("track_name", "") ?: ""
                        val oldArt = data.getString("track_art", "") ?: ""
                        if (art.isEmpty() && name == oldName) art = oldArt   // keep the cover the app resolved
                        if (name != oldName || artist != (data.getString("artist_name", "") ?: "") ||
                            playing != data.getBoolean("is_playing", false) || art != oldArt) changed = true
                        edit.putString("track_name", name)
                        edit.putString("artist_name", artist)
                        edit.putString("track_art", art)
                        edit.putBoolean("is_playing", playing)
                    }
                }

                if (doTotal) {
                    edit.putLong("native_total_at", now)
                    api("user.getinfo", user, key)?.optJSONObject("user")?.optString("playcount")
                        ?.takeIf { it.isNotEmpty() }?.let {
                            if (it != data.getString("total_scrobbles", "")) changed = true
                            edit.putString("total_scrobbles", it)
                        }
                }

                if (doLoved) {
                    edit.putLong("native_loved_at", now)
                    api("user.getlovedtracks", user, key, "&limit=1")?.optJSONObject("lovedtracks")
                        ?.optJSONObject("@attr")?.optString("total")?.takeIf { it.isNotEmpty() }?.let {
                            if (it != data.getString("loved_count", "")) changed = true
                            edit.putString("loved_count", it)
                        }
                }

                if (doWeekly) {
                    edit.putLong("native_weekly_at", now)
                    val from = now / 1000 - 7 * 24 * 3600
                    api("user.getrecenttracks", user, key, "&limit=1&from=$from")?.optJSONObject("recenttracks")
                        ?.optJSONObject("@attr")?.optString("total")?.takeIf { it.isNotEmpty() }?.let {
                            if (it != data.getString("weekly_scrobbles", "")) changed = true
                            edit.putString("weekly_scrobbles", it)
                        }
                }
                if (doToday) {
                    edit.putLong("native_today_at", now)
                    val cal = java.util.Calendar.getInstance()
                    val dayKey = String.format("%04d-%02d-%02d", cal.get(java.util.Calendar.YEAR),
                        cal.get(java.util.Calendar.MONTH) + 1, cal.get(java.util.Calendar.DAY_OF_MONTH))
                    cal.set(java.util.Calendar.HOUR_OF_DAY, 0); cal.set(java.util.Calendar.MINUTE, 0)
                    cal.set(java.util.Calendar.SECOND, 0)
                    val from = cal.timeInMillis / 1000
                    api("user.getrecenttracks", user, key, "&limit=1&from=$from")?.optJSONObject("recenttracks")
                        ?.optJSONObject("@attr")?.optString("total")?.toIntOrNull()?.let { n ->
                            val j = try { JSONObject(data.getString("heatmap_days", "{}") ?: "{}") } catch (_: Throwable) { JSONObject() }
                            if (j.optInt(dayKey, -1) != n) { j.put(dayKey, n); changed = true }
                            edit.putString("heatmap_days", j.toString())
                        }
                }
                edit.apply()
            } catch (_: Throwable) { }
            if (changed) redrawOthers(context, caller)
            done(changed)
        }
    }

    // Other widget types share the stored data: ask them to redraw too (they
    // are throttled, so this cannot loop).
    private fun redrawOthers(context: Context, caller: Class<*>?) {
        try {
            val manager = AppWidgetManager.getInstance(context)
            for (cls in listOf(
                NowPlayingWidgetProvider::class.java, ScrobbleCountWidgetProvider::class.java,
                LovedCountWidgetProvider::class.java, WeeklyScrobblesWidgetProvider::class.java,
                RecapWidgetProvider::class.java, HeatmapWidgetProvider::class.java)) {
                if (cls == caller) continue
                val ids = manager.getAppWidgetIds(ComponentName(context, cls))
                if (ids.isEmpty()) continue
                context.sendBroadcast(Intent(context, cls)
                    .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                    .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids))
            }
        } catch (_: Throwable) { }
    }
}
