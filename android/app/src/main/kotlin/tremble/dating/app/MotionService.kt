package tremble.dating.app

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.ActivityRecognition
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.ActivityTransitionRequest
import com.google.android.gms.location.DetectedActivity
import io.flutter.plugin.common.EventChannel

object MotionService {
    private var eventSink: EventChannel.EventSink? = null

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    fun emitState(state: String) {
        eventSink?.success(state)
    }

    fun start(context: Context) {
        // We will setup ActivityRecognition API here
        val transitions = mutableListOf<ActivityTransition>()

        transitions.add(
            ActivityTransition.Builder()
                .setActivityType(DetectedActivity.RUNNING)
                .setActivityTransition(ActivityTransition.ACTIVITY_TRANSITION_ENTER)
                .build()
        )
        transitions.add(
            ActivityTransition.Builder()
                .setActivityType(DetectedActivity.STILL)
                .setActivityTransition(ActivityTransition.ACTIVITY_TRANSITION_ENTER)
                .build()
        )

        val request = ActivityTransitionRequest(transitions)
        
        val intent = Intent(context, MotionReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            123,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )

        try {
            ActivityRecognition.getClient(context)
                .requestActivityTransitionUpdates(request, pendingIntent)
        } catch (e: SecurityException) {
            // Permission not granted
        }
    }

    fun stop(context: Context) {
        val intent = Intent(context, MotionReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            123,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        try {
            ActivityRecognition.getClient(context)
                .removeActivityTransitionUpdates(pendingIntent)
        } catch (e: SecurityException) {
            // Permission not granted
        }
    }
}
