// Reads the app's theme choice (style + light/dark) and turns it into
// concrete colors for the widgets. Falls back to sensible defaults.

package com.example.laststats_mobile.widgets

import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Color

data class WidgetPalette(
    val bgDrawableRes: Int,
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

        return if (style == "nothing") {
            if (isDark) {
                WidgetPalette(
                    bgDrawableRes = R.drawable.widget_bg_nothing_dark,
                    text = Color.parseColor("#FFFFFF"),
                    muted = Color.parseColor("#8A8A8A"),
                    accent = Color.parseColor("#FF2020")
                )
            } else {
                WidgetPalette(
                    bgDrawableRes = R.drawable.widget_bg_nothing_light,
                    text = Color.parseColor("#0D0D0D"),
                    muted = Color.parseColor("#6B6B6B"),
                    accent = Color.parseColor("#FF2020")
                )
            }
        } else {
            val accent = parseAccent(data.getString("accent_color", ""))
            if (isDark) {
                WidgetPalette(
                    bgDrawableRes = R.drawable.widget_bg_default_dark,
                    text = Color.parseColor("#E6E1E5"),
                    muted = Color.parseColor("#948F99"),
                    accent = accent
                )
            } else {
                WidgetPalette(
                    bgDrawableRes = R.drawable.widget_bg_default_light,
                    text = Color.parseColor("#1C1B1F"),
                    muted = Color.parseColor("#79747E"),
                    accent = accent
                )
            }
        }
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

    // Which layout resource to inflate — the Nothing style uses the app's
    // dot-matrix fonts, the default style uses the system font.
    fun layoutFor(data: SharedPreferences, nothingRes: Int, defaultRes: Int): Int {
        val style = data.getString("theme_style", "default") ?: "default"
        return if (style == "nothing") nothingRes else defaultRes
    }
}
