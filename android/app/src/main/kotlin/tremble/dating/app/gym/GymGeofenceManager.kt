package tremble.dating.app.gym

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices

/**
 * Registers and removes Gym Mode geofences via Android's GeofencingClient.
 *
 * The geofencing API is OS-native — it works when the app is killed (0 %
 * battery cost in idle state). On DWELL, the OS fires GymGeofenceReceiver
 * via the registered PendingIntent; no Flutter engine is needed.
 *
 * Requires: ACCESS_FINE_LOCATION + ACCESS_BACKGROUND_LOCATION (both declared).
 */
internal object GymGeofenceManager {
    private const val TAG = "GymGeofenceManager"
    private const val LOITERING_DELAY_MS = 10 * 60 * 1000 // 10 minutes
    private const val DEFAULT_RADIUS_M = 80f
    private const val PENDING_INTENT_ID = 9001

    fun startMonitoring(context: Context, gyms: List<Map<String, Any>>) {
        val client = LocationServices.getGeofencingClient(context)

        val geofences = gyms.mapNotNull { gym ->
            val id = gym["id"] as? String ?: return@mapNotNull null
            val lat = gym["lat"] as? Double ?: return@mapNotNull null
            val lng = gym["lng"] as? Double ?: return@mapNotNull null
            val radius = (gym["radiusMeters"] as? Number)
                ?.toFloat()
                ?.takeIf { it in 1f..200f }
                ?: DEFAULT_RADIUS_M
            val name = gym["name"] as? String ?: id

            GymGeofenceStore.saveGymName(context, id, name)

            Geofence.Builder()
                .setRequestId(id)
                .setCircularRegion(lat, lng, radius)
                .setExpirationDuration(Geofence.NEVER_EXPIRE)
                .setLoiteringDelay(LOITERING_DELAY_MS)
                .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_DWELL)
                .build()
        }

        if (geofences.isEmpty()) {
            Log.w(TAG, "startMonitoring: no valid gyms — skipping")
            return
        }

        val request = GeofencingRequest.Builder()
            // INITIAL_TRIGGER_ENTER: if the device is already inside a gym
            // when monitoring starts, fire ENTER immediately so the OS begins
            // the 10-minute loitering clock right away.
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            .addGeofences(geofences)
            .build()

        client.addGeofences(request, pendingIntent(context))
            .addOnSuccessListener {
                Log.d(TAG, "Registered ${geofences.size} geofence(s)")
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Geofence registration failed: $e")
            }
    }

    fun stopMonitoring(context: Context) {
        LocationServices.getGeofencingClient(context)
            .removeGeofences(pendingIntent(context))
            .addOnCompleteListener { Log.d(TAG, "Geofences removed") }
    }

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, GymGeofenceReceiver::class.java)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        else
            PendingIntent.FLAG_UPDATE_CURRENT
        return PendingIntent.getBroadcast(context, PENDING_INTENT_ID, intent, flags)
    }
}
