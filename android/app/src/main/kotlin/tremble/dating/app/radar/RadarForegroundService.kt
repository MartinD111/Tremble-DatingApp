package tremble.dating.app.radar

import android.app.Service
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.content.ContextCompat

/**
 * Trampoline foreground service that fixes Android 14+
 * ForegroundServiceDidNotStartInTimeException raised by
 * flutter_background_service.
 *
 * The plugin's BackgroundService.onStartCommand boots a Dart isolate before
 * calling startForeground(). On Samsung One UI / Xiaomi MIUI / Android 14+ the
 * isolate boot occasionally exceeds the 5-second deadline → process is killed.
 *
 * This service is what the Dart side (and tile / widget) actually start.
 * Its onStartCommand calls startForeground(NOTIF_ID, build()) on the FIRST
 * line — guaranteed <100ms, well within deadline. NOTIF_ID 888 + channel
 * tremble_radar_v2 are the SAME constants the plugin uses, so when the plugin
 * service later posts its own notification on 888, Android atomically replaces
 * the entry with no flicker (identical builder, identical channel).
 *
 * After startForeground succeeds we relay-start the plugin service via plain
 * Context.startService(...) — it inherits foreground status from our process
 * because we're already in foreground state on the same NOTIF_ID. We then
 * stopSelf(): notification ownership transfers cleanly to the plugin service
 * (stopForeground(STOP_FOREGROUND_DETACH) keeps the visible entry alive).
 *
 * START handling is idempotent — repeated starts while already running are
 * no-ops, preventing duplicate plugin-service launches.
 */
class RadarForegroundService : Service() {

    companion object {
        const val ACTION_START = "app.tremble.action.RADAR_FGS_START"
        const val ACTION_STOP = "app.tremble.action.RADAR_FGS_STOP"

        @Volatile
        private var running = false

        /** Idempotent entry-point used from MainActivity MethodChannel. */
        fun start(context: Context) {
            val intent = Intent(context, RadarForegroundService::class.java).apply {
                action = ACTION_START
            }
            ContextCompat.startForegroundService(context, intent)
        }

        /** Stop the trampoline AND the downstream plugin service. */
        fun stop(context: Context) {
            // Stop plugin service first.
            val pluginIntent = Intent().apply {
                component = ComponentName(
                    context.packageName,
                    "id.flutter.flutter_background_service.BackgroundService"
                )
            }
            try {
                context.stopService(pluginIntent)
            } catch (_: Throwable) { /* plugin not running */ }

            // Then stop ourselves (no-op if already stopped).
            val intent = Intent(context, RadarForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            try {
                context.stopService(intent)
            } catch (_: Throwable) { /* already stopped */ }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // ── PRIORITY 1: satisfy the OS contract within the 5s deadline ──────
        // Build a rich notification on the SAME channel + ID the plugin will
        // use, so the eventual hand-off is invisible. ensureChannel is a
        // no-op after first call (channel created in MainApplication.onCreate).
        val notification = RadarNotificationBuilder.build(this)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIF_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC or
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION or
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
            )
        } else {
            startForeground(NOTIF_ID, notification)
        }

        if (intent?.action == ACTION_STOP) {
            detachAndStop()
            return START_NOT_STICKY
        }

        // Idempotent: if a second START arrives (UI re-toggle race) skip the
        // plugin relaunch — it's already running.
        if (running) return START_NOT_STICKY
        running = true

        // ── Relay-start the flutter_background_service plugin service ──────
        // Plain startService (NOT startForegroundService): we are already in
        // foreground state for this process, so the plugin service inherits
        // it and is not subject to the 5s deadline on its own startForeground
        // call. When the plugin eventually posts its notification on
        // NOTIF_ID 888, the system atomically swaps the entry — no flicker.
        try {
            val pluginIntent = Intent().apply {
                component = ComponentName(
                    packageName,
                    "id.flutter.flutter_background_service.BackgroundService"
                )
            }
            startService(pluginIntent)
        } catch (t: Throwable) {
            // If plugin start fails, abort cleanly — better to have no radar
            // than a zombie foreground service.
            running = false
            detachAndStop()
            return START_NOT_STICKY
        }

        // Hand off notification ownership to the plugin service and exit.
        // STOP_FOREGROUND_DETACH keeps the visible notification alive; the
        // plugin service's own startForeground(888) will adopt and refresh it.
        detachAndStop()
        return START_NOT_STICKY
    }

    private fun detachAndStop() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_DETACH)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(false)
        }
        stopSelf()
    }

    override fun onDestroy() {
        running = false
        super.onDestroy()
    }
}
