package tremble.dating.app.radar

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import io.flutter.plugin.common.EventChannel
import tremble.dating.app.ACTION_POST_RADAR_NOTIFICATION
import tremble.dating.app.EXTRA_RADAR_BODY

private const val PREFS_NAME = "tremble_radar"
private const val KEY_ACTIVE = "radar_active"

/**
 * Canonical source of truth for Radar active state shared between:
 *   - Flutter engine (via EventChannel sink)
 *   - RadarTileService (Quick Settings)
 *   - RadarWidgetProvider (home/lock-screen widget)
 *   - RadarNotificationReceiver (CallStyle live-activity notification)
 *
 * State is persisted to SharedPreferences so the tile and widget can read
 * the correct value before the Flutter engine warms up (e.g. after reboot).
 *
 * The setter is the single funnel for all toggle paths. Whenever active flips:
 *   true  → fires ACTION_POST_RADAR_NOTIFICATION (CallStyle posted by receiver)
 *   false → cancels the notification immediately
 * This means the live-activity behaviour is identical regardless of whether
 * the toggle came from the Flutter UI, the QS tile, or the home widget.
 */
object RadarStateBridge {

    private var prefs: SharedPreferences? = null
    private var appContext: Context? = null
    private var eventSink: EventChannel.EventSink? = null

    /** Must be called once at process start (MainApplication.onCreate). */
    fun init(context: Context) {
        if (prefs == null) {
            appContext = context.applicationContext
            prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        }
    }

    var isActive: Boolean
        get() = prefs?.getBoolean(KEY_ACTIVE, false) ?: false
        set(value) {
            val previous = isActive
            prefs?.edit()?.putBoolean(KEY_ACTIVE, value)?.apply()
            // Push update to Flutter (no-op if no listener / UI dead).
            eventSink?.success(value)

            // Drive the CallStyle live-activity notification.
            val ctx = appContext ?: return
            if (value && !previous) {
                postLiveNotification(ctx)
            } else if (!value && previous) {
                cancelLiveNotification(ctx)
            }
        }

    private fun postLiveNotification(ctx: Context) {
        val intent = Intent(ACTION_POST_RADAR_NOTIFICATION).apply {
            putExtra(EXTRA_RADAR_BODY, "")
        }
        LocalBroadcastManager.getInstance(ctx).sendBroadcast(intent)
    }

    private fun cancelLiveNotification(ctx: Context) {
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(NOTIF_ID)
    }

    /** Registered by MainActivity when the EventChannel stream is listened to. */
    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
        // Immediately emit current state so Flutter gets it on first subscribe.
        sink?.success(isActive)
    }
}
