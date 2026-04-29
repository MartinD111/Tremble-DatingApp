package tremble.dating.app.gym

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import tremble.dating.app.R

/**
 * Shows the dwell notification directly via NotificationManager.
 *
 * Called from GymGeofenceReceiver — the Flutter engine may not be running
 * at this point, so we cannot use flutter_local_notifications. We reuse
 * the existing "tremble_proximity" channel id (created by the Flutter plugin
 * on first run) and create it ourselves if the receiver fires before the
 * Flutter engine has ever started (unlikely but safe).
 */
internal object GymGeofenceBridge {
    private const val CHANNEL_ID = "tremble_proximity"
    private const val CHANNEL_NAME = "Tremble — V bližini"
    private const val NOTIF_ID = 9001

    fun sendDwellNotification(context: Context, gymName: String) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply { enableVibration(true) }
            )
        }

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Si v $gymName? 💪")
            .setContentText("Vklopiš Gym Mode in se poveži z drugimi!")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        nm.notify(NOTIF_ID, notification)
    }
}
