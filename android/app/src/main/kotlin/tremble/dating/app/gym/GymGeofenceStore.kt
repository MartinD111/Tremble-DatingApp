package tremble.dating.app.gym

import android.content.Context

/**
 * Persists gym id→name mapping in SharedPreferences so the
 * BroadcastReceiver can resolve a human-readable name without
 * the Flutter engine being alive.
 */
internal object GymGeofenceStore {
    private const val PREFS = "gym_geofence_store"

    fun saveGymName(context: Context, gymId: String, gymName: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(gymId, gymName).apply()
    }

    fun getGymName(context: Context, gymId: String): String? =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(gymId, null)
}
