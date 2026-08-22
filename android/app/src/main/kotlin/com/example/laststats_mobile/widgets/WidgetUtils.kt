// Small helpers shared by every home screen widget.
// Reads the data saved from Dart via HomeWidget.saveWidgetData.

package com.example.laststats_mobile.widgets

import android.app.PendingIntent
import android.content.Context
import android.widget.RemoteViews
import com.example.laststats_mobile.MainActivity
import es.antonborri.home_widget.HomeWidgetLaunchIntent

object WidgetUtils {
    // Open the app when the user taps the widget.
    fun setOpenAppIntent(context: Context, views: RemoteViews, layoutId: Int) {
        val pending: PendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
        views.setOnClickPendingIntent(layoutId, pending)
    }

    // Builds a size-responsive widget: Android 12+ picks the right layout
    // automatically as the widget is resized (tiny number-only → pill →
    // full card). Older Android just gets the full layout always.
    fun responsiveViews(
        context: Context,
        tiny: RemoteViews,
        pill: RemoteViews,
        full: RemoteViews
    ): RemoteViews {
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            RemoteViews(
                mapOf(
                    android.util.SizeF(40f, 40f) to tiny,
                    android.util.SizeF(110f, 40f) to pill,
                    android.util.SizeF(110f, 110f) to full
                )
            )
        } else {
            full
        }
    }
}
