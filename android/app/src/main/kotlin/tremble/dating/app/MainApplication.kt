package tremble.dating.app

import android.app.Application
import tremble.dating.app.radar.RadarNotificationBuilder
import tremble.dating.app.radar.RadarStateBridge

/**
 * Application-scoped initialization that survives Activity death and runs in
 * every isolate's process (background isolate included, since it shares this
 * process).
 *
 * Direct callback mechanism is wired via [RadarStateBridge.onNotificationTrigger]
 * so any code in this process can trigger the CallStyle notification — even when
 * MainActivity is dead, avoiding deprecated LocalBroadcastManager.
 */
class MainApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        RadarStateBridge.init(applicationContext)
        // Pre-create the v2 channel so the system has it before any post.
        RadarNotificationBuilder.ensureChannel(this)

        // Set the notification trigger callback to update the live activity notification
        RadarStateBridge.onNotificationTrigger = { body ->
            RadarNotificationBuilder.update(this, body)
        }
    }
}
