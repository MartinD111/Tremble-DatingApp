package tremble.dating.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import io.flutter.app.FlutterApplication
import tremble.dating.app.radar.RadarNotificationBuilder
import tremble.dating.app.radar.RadarStateBridge

const val ACTION_POST_RADAR_NOTIFICATION =
    "app.tremble.action.POST_RADAR_NOTIFICATION"
const val EXTRA_RADAR_BODY = "body"

/**
 * Application-scoped initialization that survives Activity death and runs in
 * every isolate's process (background isolate included, since it shares this
 * process).
 *
 * The [RadarNotificationReceiver] is registered with [LocalBroadcastManager]
 * so any code in this process can fire ACTION_POST_RADAR_NOTIFICATION and
 * trigger the CallStyle notification — even when MainActivity is dead.
 *
 * The MethodChannel handler on "app.tremble/radar/notify" is wired by
 * [tremble.dating.app.radar.RadarBridgePlugin] which auto-attaches to every
 * FlutterEngine in this process (foreground Activity engine AND the
 * detached background-service engine). From that handler we fire the local
 * broadcast and the receiver does the actual notification post — entirely
 * in native code, no Flutter dependency.
 */
class MainApplication : FlutterApplication() {

    private val notificationReceiver = RadarNotificationReceiver()

    override fun onCreate() {
        super.onCreate()
        RadarStateBridge.init(applicationContext)
        // Pre-create the v2 channel so the system has it before any post.
        RadarNotificationBuilder.ensureChannel(this)

        LocalBroadcastManager.getInstance(this).registerReceiver(
            notificationReceiver,
            IntentFilter(ACTION_POST_RADAR_NOTIFICATION)
        )
    }
}

/**
 * In-process broadcast receiver that posts / refreshes the CallStyle
 * notification. Runs entirely in native Kotlin — no Flutter engine required —
 * so it works even if the UI isolate is dead and the background isolate is
 * the only thing keeping the process alive.
 */
class RadarNotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_POST_RADAR_NOTIFICATION) return
        val body = intent.getStringExtra(EXTRA_RADAR_BODY).orEmpty()
        RadarNotificationBuilder.update(context, body)
    }
}
