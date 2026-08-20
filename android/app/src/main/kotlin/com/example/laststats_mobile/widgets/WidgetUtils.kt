// Small helpers shared by every home screen widget.
// Reads the data saved from Dart via HomeWidget.saveWidgetData.

package com.example.laststats_mobile.widgets

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

object WidgetUtils {
    // Open the app when the user taps the widget.
    fun setOpenAppIntent(context: Context, views: RemoteViews, layoutId: Int) {
        val intent: Intent = HomeWidgetLaunchIntent.getActivity(context, Class.forName(
            "com.example.laststats_mobile.MainActivity"
        ))
        val pending = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(layoutId, pending)
    }
}
