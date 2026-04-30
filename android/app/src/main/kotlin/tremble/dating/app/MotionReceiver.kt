package tremble.dating.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.ActivityTransitionResult
import com.google.android.gms.location.DetectedActivity

class MotionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (ActivityTransitionResult.hasResult(intent)) {
            val result = ActivityTransitionResult.extractResult(intent)
            result?.let {
                for (event in it.transitionEvents) {
                    val state = when (event.activityType) {
                        DetectedActivity.RUNNING -> "RUNNING"
                        DetectedActivity.STILL -> "STATIONARY"
                        else -> "UNKNOWN"
                    }
                    if (state != "UNKNOWN") {
                        MotionService.emitState(state)
                    }
                }
            }
        }
    }
}
