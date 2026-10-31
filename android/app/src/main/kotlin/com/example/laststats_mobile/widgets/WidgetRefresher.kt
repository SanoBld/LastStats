// Refreshes the data the widgets show straight from Last.fm, without needing the
// app (or Flutter) to be running. Called on every widget update.

package com.example.laststats_mobile.widgets

import android.content.Context
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import kotlin.concurrent.thread

object WidgetRefresher {
    private const val TRACK_EVERY_MS = 15_000L
    private const val COUNTS_EVERY_MS = 5 * 60_000L
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

    /** Runs in the background; [done] is called with true when stored data changed. */
    fun refresh(context: Context, done: (Boolean) -> Unit) {
        val data = HomeWidgetPlugin.getData(context)
        val user = data.getString("username", "") ?: ""
        val key = data.getString("api_key", "") ?: ""
        if (user.isEmpty() || key.isEmpty()) { done(false); return }
        val now = System.currentTimeMillis()
        if (now - data.getLong("native_refresh_at", 0L) < TRACK_EVERY_MS) { done(false); return }
        thread {
            var changed = false
            try {
                val edit = data.edit()
                edit.putLong("native_refresh_at", now)

                // Now playing / last played track
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

                // Counters: less often
                if (now - data.getLong("native_counts_at", 0L) > COUNTS_EVERY_MS) {
                    edit.putLong("native_counts_at", now)
                    api("user.getinfo", user, key)?.optJSONObject("user")?.optString("playcount")
                        ?.takeIf { it.isNotEmpty() }?.let {
                            if (it != data.getString("total_scrobbles", "")) changed = true
                            edit.putString("total_scrobbles", it)
                        }
                    api("user.getlovedtracks", user, key, "&limit=1")?.optJSONObject("lovedtracks")
                        ?.optJSONObject("@attr")?.optString("total")?.takeIf { it.isNotEmpty() }?.let {
                            if (it != data.getString("loved_count", "")) changed = true
                            edit.putString("loved_count", it)
                        }
                    val from = now / 1000 - 7 * 24 * 3600
                    api("user.getrecenttracks", user, key, "&limit=1&from=$from")?.optJSONObject("recenttracks")
                        ?.optJSONObject("@attr")?.optString("total")?.takeIf { it.isNotEmpty() }?.let {
                            if (it != data.getString("weekly_scrobbles", "")) changed = true
                            edit.putString("weekly_scrobbles", it)
                        }
                }
                edit.apply()
            } catch (_: Throwable) { }
            done(changed)
        }
    }
}
