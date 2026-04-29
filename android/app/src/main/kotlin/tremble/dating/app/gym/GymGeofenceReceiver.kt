package tremble.dating.app.gym

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent

/**
 * Receives OS geofence transition events for Gym Mode.
 *
 * Woken by Android's GeofencingClient via a PendingIntent — no Flutter
 * engine or foreground service required. Only handles DWELL transitions
 * (fires after the user has been inside the registered radius for 10 min).
 */
class GymGeofenceReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val event = GeofencingEvent.fromIntent(intent)
        if (event == null || event.hasError()) {
            Log.w(TAG, "Invalid geofence event (error=${event?.errorCode})")
            return
        }

        if (event.geofenceTransition == Geofence.GEOFENCE_TRANSITION_DWELL) {
            val gymId = event.triggeringGeofences?.firstOrNull()?.requestId ?: return
            val gymName = GymGeofenceStore.getGymName(context, gymId) ?: gymId
            Log.d(TAG, "DWELL fired for gym=$gymId ($gymName)")
            GymGeofenceBridge.sendDwellNotification(context, gymName)
        }
    }

    private companion object {
        const val TAG = "GymGeofenceReceiver"
    }
}
