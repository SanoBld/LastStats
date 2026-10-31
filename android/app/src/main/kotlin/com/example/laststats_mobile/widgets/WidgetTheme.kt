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
    val accent: Int,
    val onChip: Int = text,
    val tertiary: Int = accent,   // poster blobs (like the share images)
    val secondary: Int = accent,
    val posterMix: Float = 0.45f   // how much container color the poster card gets
)

object WidgetTheme {
    // Material You: follows the system light/dark mode and, on Android 12+, the
    // wallpaper-based system colors. Older versions get the M3 baseline palette.
    private fun materialYou(context: Context, dark: Boolean): WidgetPalette {
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            fun c(id: Int) = context.getColor(id)
            if (dark) WidgetPalette(
                c(android.R.color.system_neutral1_900), c(android.R.color.system_accent1_700),
                c(android.R.color.system_neutral1_100), c(android.R.color.system_neutral2_200),
                c(android.R.color.system_accent1_200), c(android.R.color.system_accent1_100),
                c(android.R.color.system_accent3_200), c(android.R.color.system_accent2_200))
            else WidgetPalette(
                c(android.R.color.system_neutral1_10), c(android.R.color.system_accent1_100),
                c(android.R.color.system_neutral1_900), c(android.R.color.system_neutral2_700),
                c(android.R.color.system_accent1_600), c(android.R.color.system_accent1_900),
                c(android.R.color.system_accent3_600), c(android.R.color.system_accent2_600))
        } else if (dark) WidgetPalette(
            Color.parseColor("#141218"), Color.parseColor("#4F378B"),
            Color.parseColor("#E6E0E9"), Color.parseColor("#CAC4D0"), Color.parseColor("#D0BCFF"),
            Color.parseColor("#EADDFF"), Color.parseColor("#EFB8C8"), Color.parseColor("#CCC2DC"))
        else WidgetPalette(
            Color.parseColor("#FEF7FF"), Color.parseColor("#EADDFF"),
            Color.parseColor("#1D1B20"), Color.parseColor("#49454F"), Color.parseColor("#6750A4"),
            Color.parseColor("#21005D"), Color.parseColor("#7D5260"), Color.parseColor("#625B71"))
    }

    // Palette from the app accent (dynamic color off): honours the app's
    // light/dark choice and the "colored widgets" switch.
    private fun accentPalette(data: SharedPreferences, dark: Boolean): WidgetPalette {
        val accent = parseAccent(data.getString(if (dark) "accent_dark" else "accent_light", ""))
        val tint = data.getBoolean("widget_tint", false)
        val base = if (dark) Color.parseColor("#1C1B1F") else Color.parseColor("#FFFBFE")
        val surface = blend(base, accent, if (tint) (if (dark) 0.16f else 0.10f) else 0.03f)
        val chip = blend(base, accent, if (tint) (if (dark) 0.50f else 0.28f) else (if (dark) 0.40f else 0.20f))
        val onChip = blend(if (dark) Color.WHITE else Color.BLACK, accent, if (dark) 0.25f else 0.35f)
        val text = blend(if (dark) Color.parseColor("#E6E1E5") else Color.parseColor("#1C1B1F"), accent, 0.06f)
        val muted = blend(if (dark) Color.parseColor("#CAC4D0") else Color.parseColor("#49454F"), accent, 0.12f)
        // tertiary = accent hue shifted, secondary = softened accent (like Material schemes)
        val hsv = FloatArray(3); Color.colorToHSV(accent, hsv)
        val t = floatArrayOf((hsv[0] + 60f) % 360f, hsv[1], hsv[2])
        val sec = floatArrayOf(hsv[0], hsv[1] * 0.4f, hsv[2])
        return WidgetPalette(surface, chip, text, muted, accent, onChip,
            Color.HSVToColor(t), Color.HSVToColor(sec))
    }

    // Exact colors of the app's own ColorScheme (computed in Dart: accent, day/night
    // accent, color harmony, OLED...) so widgets match the app and the share images.
    private fun schemePalette(data: SharedPreferences, dark: Boolean): WidgetPalette? {
        val pre = if (dark) "sc_d_" else "sc_l_"
        fun col(k: String): Int? = data.getString(pre + k, null)?.toLongOrNull()?.toInt()
        val surface = col("surface") ?: return null
        val container = col("container") ?: return null
        val text = col("on_surface") ?: return null
        val muted = col("on_variant") ?: return null
        val primary = col("primary") ?: return null
        val onContainer = col("on_container") ?: return null
        return WidgetPalette(surface, container, text, muted, primary, onContainer,
            col("tertiary") ?: primary, col("secondary") ?: primary)
    }

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

        if (style != "nothing") {
            val dynamic = data.getBoolean("use_dynamic_color", false)
            val tint = data.getBoolean("widget_tint", false)
            val base = if (dynamic && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S)
                materialYou(context, isDark)
            else schemePalette(data, isDark) ?: accentPalette(data, isDark)
            return base.copy(posterMix = if (tint) 0.45f else 0.18f)
        }
        val accent = if (style == "nothing") {
            Color.parseColor("#FF2020")
        } else {
            val key = if (isDark) "accent_dark" else "accent_light"
            parseAccent(data.getString(key, ""))
        }

        // Base card color, then — only if the user opted in — a touch of
        // accent mixed in, mirroring the app's own Material You surfaces.
        // Off by default: widgets stay pure white / pure black.
        val tintOn = data.getBoolean("widget_tint", false)
        val base = if (isDark) Color.parseColor("#0D0D0D") else Color.parseColor("#FFFFFF")
        val surfaceMix = if (!tintOn) 0f else if (style == "nothing") 0.05f else 0.12f
        val surface = blend(base, accent, surfaceMix)

        val chipMix = if (!tintOn) (if (isDark) 0.12f else 0.08f)
                      else (if (isDark) 0.30f else 0.18f)
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
