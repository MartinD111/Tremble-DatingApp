package tremble.dating.app.radar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

const val ACTION_RADAR_TOGGLE = "app.tremble.action.RADAR_TOGGLE"

/**
 * Receives toggle intents fired by the home/lock-screen widget tap.
 * Flips RadarStateBridge state and requests a widget redraw.
 * The EventChannel sink (if Flutter is live) propagates the change to Dart.
 */
class RadarToggleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_RADAR_TOGGLE) return
        RadarStateBridge.init(context)
        // If the intent carries an explicit force_state, honour it (used by
        // the CallStyle notification's Stop action so it can never re-enable
        // a previously-off radar by accident). Otherwise toggle.
        RadarStateBridge.isActive = if (intent.hasExtra("force_state")) {
            intent.getBooleanExtra("force_state", false)
        } else {
            !RadarStateBridge.isActive
        }
        RadarWidgetProvider.updateAll(context)
    }
}
