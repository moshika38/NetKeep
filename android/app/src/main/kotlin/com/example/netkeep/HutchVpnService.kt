package com.example.netkeep

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import com.wireguard.android.backend.GoBackend
import com.wireguard.android.backend.Tunnel
import com.wireguard.config.Config
import io.flutter.plugin.common.EventChannel
import java.io.ByteArrayInputStream

/**
 * Native WireGuard client relay.
 *
 * Drives the official WireGuard Go runtime (com.wireguard.android:tunnel) with
 * a `wg-quick` profile. The Go backend spins up its own VpnService
 * (`GoBackend$VpnService`, auto-declared by the library manifest) which:
 *
 *  - establishes the TUN via `VpnService.Builder` using the profile's
 *    AllowedIPs (0.0.0.0/0) as `addRoute` and DNS 1.1.1.1 as `addDnsServer`,
 *  - calls `protect()` on the WireGuard UDP socket so encrypted handshakes and
 *    data frames go out the real network interface and never loop back into
 *    the TUN,
 *  - pumps IP packets between the TUN file descriptor and the encrypted
 *    WireGuard socket.
 *
 * Because AllowedIPs covers 0.0.0.0/0, the OS routes ALL app traffic - HTTP
 * keep-alive pings from the Pinger/KeepAlive included - through the tunnel
 * automatically, resolving 403 blocks and connection timeouts.
 *
 * The service stays in the foreground (with a notification) for as long as the
 * relay is up, mirrors live stage/statistics state into the companion object
 * and pushes them to Flutter over an EventChannel.
 */
class HutchVpnService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                startRelay(intent.getStringExtra(EXTRA_WG_QUICK))
                return START_STICKY
            }
            ACTION_STOP -> {
                stopRelay()
                return START_NOT_STICKY
            }
            else -> {
                // START_STICKY restart with a null intent: never resurrect the
                // tunnel without a config.
                stopRelay()
                return START_NOT_STICKY
            }
        }
    }

    override fun onDestroy() {
        stopRelay()
        super.onDestroy()
    }

    // ------------------------------------------------------------ lifecycle

    private fun startRelay(wgQuick: String?) {
        if (isActive) return
        if (wgQuick.isNullOrBlank()) {
            failRelay("Missing WireGuard config")
            return
        }

        stage = STAGE_CONNECTING
        isActive = true
        pushStage()
        startForeground(NOTIFICATION_ID, buildNotification("Connecting..."))

        Thread {
            try {
                val backend = backend ?: GoBackend(applicationContext).also { backend = it }
                val relayTunnel = tunnel ?: createTunnel().also { tunnel = it }
                val config = Config.parse(ByteArrayInputStream(wgQuick.toByteArray()))
                backend.setState(relayTunnel, Tunnel.State.UP, config)
                if (isActive) {
                    handler.post(statsPollingRunnable)
                }
            } catch (e: Exception) {
                Log.e(TAG, "WireGuard relay failed: ${e.message}", e)
                handler.post {
                    if (isActive) failRelay(e.message ?: "WireGuard relay failed")
                }
            }
        }.apply { isDaemon = true }.start()
    }

    private fun stopRelay() {
        if (!isActive) {
            stopSelf()
            return
        }
        isActive = false
        handler.removeCallbacks(statsPollingRunnable)
        Thread {
            try {
                tunnel?.let { backend?.setState(it, Tunnel.State.DOWN, null) }
            } catch (e: Exception) {
                Log.e(TAG, "Error tearing down relay: ${e.message}")
            }
        }.apply { isDaemon = true }.start()

        stage = STAGE_DISCONNECTED
        rxBytes = 0L
        txBytes = 0L
        handshakeAgeMs = -1L
        pushStage()
        stopForegroundCompat()
        stopSelf()
    }

    private fun failRelay(reason: String) {
        Log.e(TAG, "Relay failed: $reason")
        isActive = false
        stage = STAGE_ERROR
        pushStage()
        stopForegroundCompat()
        stopSelf()
    }

    // ---------------------------------------------------------------- tunnel

    private fun createTunnel(): Tunnel = object : Tunnel {
        override fun getName(): String = TUNNEL_NAME

        override fun onStateChange(newState: Tunnel.State) {
            when (newState) {
                Tunnel.State.UP -> {
                    if (isActive) {
                        stage = STAGE_CONNECTED
                        pushStage()
                        handler.post(statsPollingRunnable)
                    }
                }
                Tunnel.State.DOWN -> {
                    if (isActive) {
                        isActive = false
                        handler.removeCallbacks(statsPollingRunnable)
                        stage = STAGE_DISCONNECTED
                        pushStage()
                    }
                }
                else -> Unit
            }
        }
    }

    // ----------------------------------------------------------------- stats

    private val statsPollingRunnable = object : Runnable {
        override fun run() {
            if (!isActive) return
            pollStats()
            handler.postDelayed(this, STATS_POLL_MS)
        }
    }

    private fun pollStats() {
        try {
            val stats = backend?.getStatistics(tunnel) ?: return
            rxBytes = stats.totalRx()
            txBytes = stats.totalTx()
            var latestHandshake = 0L
            for (peer in stats.peers()) {
                val epoch = stats.peer(peer)?.latestHandshakeEpochMillis() ?: 0L
                if (epoch > latestHandshake) latestHandshake = epoch
            }
            handshakeAgeMs =
                if (latestHandshake > 0) System.currentTimeMillis() - latestHandshake else -1L
        } catch (e: Exception) {
            // Tunnel is down or statistics are unavailable; keep last values.
        }
        pushStats()
    }

    // -------------------------------------------------------------- flutter

    private fun pushStage() {
        handler.post {
            eventSink?.success(
                mapOf("type" to "stage", "stage" to stage)
            )
        }
    }

    private fun pushStats() {
        handler.post {
            eventSink?.success(
                mapOf(
                    "type" to "stats",
                    "rxBytes" to rxBytes,
                    "txBytes" to txBytes,
                    "handshakeAgeMs" to handshakeAgeMs,
                )
            )
        }
    }

    // ----------------------------------------------------------- notification

    private fun buildNotification(content: String): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE
            } else {
                0
            }
        val pendingIntent = PendingIntent.getActivity(this, 0, intent, flags)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val channel = NotificationChannel(
                CHANNEL_ID,
                "VPN Tunnel",
                NotificationManager.IMPORTANCE_LOW
            )
            manager.createNotificationChannel(channel)
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("NetKeep VPN")
            .setContentText(content)
            .setSmallIcon(R.drawable.ic_vpn_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    // -------------------------------------------------------------- companion

    companion object {
        const val ACTION_START = "START_VPN"
        const val ACTION_STOP = "STOP_VPN"
        const val EXTRA_WG_QUICK = "wg_quick"

        const val STAGE_DISCONNECTED = "disconnected"
        const val STAGE_CONNECTING = "connecting"
        const val STAGE_CONNECTED = "connected"
        const val STAGE_ERROR = "error"

        private const val TAG = "HutchVPN"
        private const val CHANNEL_ID = "netkeep_vpn"
        private const val NOTIFICATION_ID = 101
        private const val TUNNEL_NAME = "netkeep0"
        private const val STATS_POLL_MS = 1000L

        private val handler = Handler(Looper.getMainLooper())

        /** Live tunnel stage: disconnected / connecting / connected / error. */
        @Volatile
        var stage: String = STAGE_DISCONNECTED
            private set

        /** Whether the relay has been told to run (connecting or connected). */
        @Volatile
        var isActive: Boolean = false
            private set

        /** Cumulative bytes pushed through the tunnel since it came up. */
        @Volatile
        var rxBytes: Long = 0L
            private set

        @Volatile
        var txBytes: Long = 0L
            private set

        /** Milliseconds since the peer's last successful handshake, or -1. */
        @Volatile
        var handshakeAgeMs: Long = -1L
            private set

        /** Sink for the `netkeep/vpn/events` EventChannel, set by MainActivity. */
        @Volatile
        var eventSink: EventChannel.EventSink? = null

        private var backend: GoBackend? = null
        private var tunnel: Tunnel? = null
    }
}
