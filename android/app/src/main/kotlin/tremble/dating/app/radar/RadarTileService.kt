package tremble.dating.app.radar

import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import tremble.dating.app.R

/**
 * Quick Settings tile that toggles the Tremble Radar on/off.
 *
 * Icon colouring is handled entirely by the Android system:
 *   - ACTIVE  → system tints the icon with the device accent colour (Material You)
 *   - INACTIVE → system renders the icon grey
 * We must NOT apply any brand colour ourselves — the system enforces this for
 * tiles that pass Play Store review.
 *
 * State persistence is via RadarStateBridge → SharedPreferences, so the tile
 * renders correctly even before the Flutter engine is running.
 */
class RadarTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        RadarStateBridge.init(applicationContext)
        syncTile()
    }

    override fun onClick() {
        super.onClick()
        RadarStateBridge.init(applicationContext)
        val newState = !RadarStateBridge.isActive
        RadarStateBridge.isActive = newState
        // Update widget to match
        RadarWidgetProvider.updateAll(applicationContext)
        syncTile()
    }

    private fun syncTile() {
        val tile = qsTile ?: return
        if (RadarStateBridge.isActive) {
            tile.state = Tile.STATE_ACTIVE
            tile.label = getString(R.string.qs_tile_label)
            tile.contentDescription = "Radar on"
        } else {
            tile.state = Tile.STATE_INACTIVE
            tile.label = getString(R.string.qs_tile_label)
            tile.contentDescription = "Radar off"
        }
        tile.updateTile()
    }
}
