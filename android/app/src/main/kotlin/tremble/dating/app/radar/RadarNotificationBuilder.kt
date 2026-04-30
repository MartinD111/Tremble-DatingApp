package tremble.dating.app.radar

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import tremble.dating.app.MainActivity
import tremble.dating.app.R

// New channel ID — Android channel importance is immutable after creation,
// so we cannot promote the legacy "tremble_background" LOW channel. The v2
// channel uses DEFAULT importance: high enough that the system never demotes
// or hides the ongoing notification, low enough that it makes no sound and
// produces no heads-up popup (correct for a passive background scanner).
const val CHANNEL_ID = "tremble_radar_v2"
const val NOTIF_ID = 888

/**
 * Builds the foreground-service ongoing notification for Tremble Radar.
 *
 * Design: standard ongoing notification — same pattern Uber, Spotify
 * use for active background sessions. No CallStyle (crashes on Android 14+
 * because the service is not a phoneCall), no Samsung proprietary extras
 * (undocumented and fragile), no full-screen intent (not eligible without
 * USE_FULL_SCREEN_INTENT special-permission grant).
 *
 * Properties that make this rock-solid:
 *   - setOngoing(true)               → user cannot swipe-dismiss; survives "Clear all"
 *   - foreground service backed      → OS keeps it alive as long as service runs
 *   - DecoratedCustomViewStyle       → custom body within standard system chrome
 *   - setColorized + brand colour    → rose tinted background on lock-screen and
 *                                      heads-up surfaces (when channel allows it)
 *   - explicit Stop action           → routes to RadarToggleReceiver with
 *                                      force_state=false → flips RadarStateBridge
 *                                      → cancels notif + syncs Dart UI + tile + widget
 *   - same NOTIF_ID as the plugin    → notify() atomically replaces the plain-text
 *                                      notification flutter_background_service posts
 */
object RadarNotificationBuilder {

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.notification_channel_name),
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Shows when Tremble Radar is scanning in the background."
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    fun build(context: Context, bodyText: String = ""): Notification {
        ensureChannel(context)

        // Tap → reopen MainActivity
        val tapIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val tapPending = PendingIntent.getActivity(
            context, 0, tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Stop Radar action — explicit OFF (force_state=false) so the receiver
        // can never accidentally re-enable a closed radar by toggling.
        val stopIntent = Intent(context, RadarToggleReceiver::class.java).apply {
            action = ACTION_RADAR_TOGGLE
            putExtra("force_state", false)
        }
        val stopPending = PendingIntent.getBroadcast(
            context, 1, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val body = bodyText.ifBlank {
            context.getString(R.string.notification_radar_scanning)
        }

        // Custom body inside standard system chrome (icon, app name, time).
        // DecoratedCustomViewStyle is fully supported on every Android version
        // we ship to and degrades gracefully — no special permission required.
        val collapsed = RemoteViews(
            context.packageName,
            R.layout.notification_radar_collapsed
        )
        val expanded = RemoteViews(
            context.packageName,
            R.layout.notification_radar_expanded
        )
        collapsed.setTextViewText(R.id.notif_body, body)
        expanded.setTextViewText(R.id.notif_expanded_body, body)
        // Bind the inline Stop affordance inside the expanded layout to the
        // same PendingIntent the addAction Stop button uses.
        expanded.setOnClickPendingIntent(R.id.notif_action_stop, stopPending)

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_tremble_qs_tile)
            .setContentTitle(context.getString(R.string.notification_radar_active))
            .setContentText(body)
            .setContentIntent(tapPending)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setColor(Color.parseColor("#F4436C"))
            .setColorized(true)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(collapsed)
            .setCustomBigContentView(expanded)
            .addAction(
                NotificationCompat.Action.Builder(
                    R.drawable.ic_tremble_qs_tile,
                    context.getString(R.string.notification_action_stop),
                    stopPending
                ).build()
            )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(
                NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE
            )
        }

        return builder.build()
    }

    fun update(context: Context, bodyText: String) {
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIF_ID, build(context, bodyText))
    }
}
