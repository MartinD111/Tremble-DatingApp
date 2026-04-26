package tremble.dating.app.radar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.widget.RemoteViews
import tremble.dating.app.R

/**
 * Home / lock-screen widget that toggles the Tremble Radar.
 *
 * Accent tinting strategy:
 *   Android 12+ (API 31): resolve system accent colour at runtime via
 *     context.obtainStyledAttributes + R.attr.colorAccent and apply as an
 *     ImageView tint on the icon. RemoteViews does not support dynamic
 *     attribute resolution directly, so we resolve it here and set as int.
 *   Below Android 12: use the static widget_background_active drawable (deep
 *     graphite + rose border) — still visually distinct from inactive.
 */
class RadarWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        RadarStateBridge.init(context)
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_RADAR_TOGGLE) {
            RadarStateBridge.init(context)
            RadarStateBridge.isActive = !RadarStateBridge.isActive
            updateAll(context)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle
    ) {
        updateWidget(context, appWidgetManager, appWidgetId)
    }

    companion object {
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, RadarWidgetProvider::class.java)
            )
            for (id in ids) {
                updateWidget(context, manager, id)
            }
        }

        private fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int
        ) {
            val isActive = RadarStateBridge.isActive
            val views = RemoteViews(context.packageName, R.layout.widget_radar)

            // Detect size to toggle pill vs circle mode
            val options = manager.getAppWidgetOptions(widgetId)
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
            // minWidth is in dp. 1x1 is usually ~70dp. 2x1 is ~140dp.
            val isPillMode = minWidth > 100

            // Toggle pending intent
            val toggleIntent = Intent(context, RadarToggleReceiver::class.java).apply {
                action = ACTION_RADAR_TOGGLE
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, 0, toggleIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            // Label visibility based on size
            views.setViewVisibility(
                R.id.widget_text_container,
                if (isPillMode) android.view.View.VISIBLE else android.view.View.GONE
            )

            // Status text
            views.setTextViewText(
                R.id.widget_status,
                if (isActive) "Active" else "Off"
            )

            // Background based on state
            if (isActive) {
                views.setInt(
                    R.id.widget_root,
                    "setBackgroundResource",
                    R.drawable.widget_background_active
                )
                views.setInt(R.id.widget_icon, "setImageAlpha", 255)
            } else {
                views.setInt(
                    R.id.widget_root,
                    "setBackgroundResource",
                    R.drawable.widget_background_inactive
                )
                views.setInt(R.id.widget_icon, "setImageAlpha", 140)
            }

            manager.updateAppWidget(widgetId, views)
        }

    }
}
