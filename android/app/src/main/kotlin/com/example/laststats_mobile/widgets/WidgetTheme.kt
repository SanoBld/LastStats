// Reads the app's theme choice (style + light/dark + accent) and turns it
// into concrete colors for the widgets — including a card background that's
// actually tinted with the user's chosen accent, like Material You does.

package com.example.laststats_mobile.widgets

import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Color

data class WidgetPalette(
    val surface: Int,   // card background color (tinted by accent)
    val chip: Int,      // small icon-chip background
    val text: Int,
    val muted: Int,
    val accent: Int
)

object WidgetTheme {
    fun resolve(context: Context, data: SharedPreferences): WidgetPalette {
        val style = data.getString("theme_style", "default") ?: "default"
        val mode = data.getString("theme_mode", "system") ?: "system"
        val isDark = when (mode) {
            "dark" -> true
            "light" -> false
            else -> {
                val night = context.resources.configuration.uiMode and
                    Configuration.UI_MODE_NIGHT_MASK
                night == Configuration.UI_MODE_NIGHT_YES
            }
        }

        val accent = if (style == "nothing") {
            Color.parseColor("#FF2020")
        } else {
            parseAccent(data.getString("accent_color", ""))
        }

        // Base card color, then a touch of accent mixed in — mirrors the
        // app's own Material You surfaces (ColorScheme.fromSeed).
        val base = if (isDark) Color.parseColor("#0D0D0D") else Color.parseColor("#FFFFFF")
        val surfaceMix = if (style == "nothing") 0.05f else 0.12f
        val surface = blend(base, accent, surfaceMix)

        val chipMix = if (isDark) 0.30f else 0.18f
        val chip = blend(base, accent, chipMix)

        val text = if (isDark) Color.parseColor("#F5F5F5") else Color.parseColor("#0D0D0D")
        val muted = if (isDark) Color.parseColor("#9A9A9A") else Color.parseColor("#6B6B6B")

        return WidgetPalette(surface, chip, text, muted, accent)
    }

    // Mixes `overlay` into `base` by `ratio` (0 = pure base, 1 = pure overlay).
    private fun blend(base: Int, overlay: Int, ratio: Float): Int {
        val r = (Color.red(base) * (1 - ratio) + Color.red(overlay) * ratio).toInt()
        val g = (Color.green(base) * (1 - ratio) + Color.green(overlay) * ratio).toInt()
        val b = (Color.blue(base) * (1 - ratio) + Color.blue(overlay) * ratio).toInt()
        return Color.rgb(r, g, b)
    }

    // Mirrors app_state.dart's accentFromString: named key or '#RRGGBB' hex.
    private fun parseAccent(raw: String?): Int {
        val fallback = Color.parseColor("#7C3AED")
        if (raw.isNullOrEmpty()) return fallback
        if (raw.startsWith("#") && raw.length == 7) {
            return try { Color.parseColor(raw) } catch (_: Exception) { fallback }
        }
        return when (raw) {
            "blue" -> Color.parseColor("#1D4ED8")
            "green" -> Color.parseColor("#059669")
            "red" -> Color.parseColor("#DC2626")
            "orange" -> Color.parseColor("#D97706")
            "pink" -> Color.parseColor("#DB2777")
            "teal" -> Color.parseColor("#0F766E")
            "neutral" -> Color.parseColor("#607D8B")
            else -> fallback
        }
    }

    // Which layout resource to inflate — same idea for both, kept separate
    // in case the two styles need to diverge again later.
    fun layoutFor(data: SharedPreferences, nothingRes: Int, defaultRes: Int): Int {
        val style = data.getString("theme_style", "default") ?: "default"
        return if (style == "nothing") nothingRes else defaultRes
    }
}
