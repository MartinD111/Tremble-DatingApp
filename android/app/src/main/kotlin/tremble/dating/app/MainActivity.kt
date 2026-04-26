package tremble.dating.app

import android.app.StatusBarManager
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import tremble.dating.app.radar.RadarStateBridge
import tremble.dating.app.radar.RadarWidgetProvider
import tremble.dating.app.radar.RadarTileService

private const val METHOD_CHANNEL = "app.tremble/radar"
private const val EVENT_CHANNEL = "app.tremble/radar/events"

class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        RadarStateBridge.init(applicationContext)

        // ── EventChannel: push Radar state changes to Dart ───────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    RadarStateBridge.setEventSink(events)
                }
                override fun onCancel(arguments: Any?) {
                    RadarStateBridge.setEventSink(null)
                }
            })

        // ── MethodChannel: Dart → native commands ─────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setRadarActive" -> {
                        val active = call.argument<Boolean>("active") ?: false
                        RadarStateBridge.isActive = active
                        RadarWidgetProvider.updateAll(applicationContext)
                        result.success(null)
                    }
                    "getRadarActive" -> {
                        result.success(RadarStateBridge.isActive)
                    }
                    "requestAddQsTile" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            val statusBarManager =
                                getSystemService(StatusBarManager::class.java)
                            statusBarManager?.requestAddTileService(
                                ComponentName(this, RadarTileService::class.java),
                                getString(R.string.qs_tile_label),
                                android.graphics.drawable.Icon.createWithResource(
                                    this, R.drawable.ic_tremble_qs_tile
                                ),
                                mainExecutor
                            ) { tileResult ->
                                // tileResult codes: TILE_RESULT_ADDED,
                                // TILE_RESULT_ALREADY_ADDED, TILE_RESULT_UNAVAILABLE
                                result.success(tileResult)
                            }
                        } else {
                            // Pre-Android 13: user must drag tile manually.
                            result.success(-1)
                        }
                    }
                    "requestPinWidget" -> {
                        val widgetManager = AppWidgetManager.getInstance(this)
                        val provider = ComponentName(this, RadarWidgetProvider::class.java)
                        if (widgetManager.isRequestPinAppWidgetSupported) {
                            widgetManager.requestPinAppWidget(provider, null, null)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Bring Flutter to foreground when the user taps the notification
        if (intent.action == Intent.ACTION_MAIN) {
            flutterEngine?.navigationChannel?.pushRoute("/")
        }
    }
}
