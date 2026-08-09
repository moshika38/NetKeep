package com.example.netkeep

import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.Intent
import android.net.NetworkCapabilities
import android.net.TrafficStats
import android.net.VpnService
import android.os.Build
import com.pravera.flutter_foreground_task.FlutterForegroundTaskLifecycleListener
import com.pravera.flutter_foreground_task.FlutterForegroundTaskPlugin
import com.pravera.flutter_foreground_task.FlutterForegroundTaskStarter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val networkStatsChannel = "netkeep/network_stats"
    private val dataUsageChannel = "com.netkeep.app/network_stats"
    private val statusBarIconChannel = "netkeep/status_bar_icon"
    private val vpnChannel = "netkeep/vpn"
    private val vpnEventsChannel = "netkeep/vpn/events"

    // Live TrafficStats counters (system-wide Rx/Tx bytes since boot).
    // Kept in the companion so it never captures a dead Activity.
    private val dataUsageHandler = MethodChannel.MethodCallHandler { call, result ->
        if (call.method != "getDeviceTotalData") {
            result.notImplemented()
            return@MethodCallHandler
        }

        val startTime = argumentLong(call, "startTime") ?: 0L
        val endTime = argumentLong(call, "endTime") ?: 0L
        val isMobile = when (val value = call.argument<Any>("isMobile")) {
            is Boolean -> value
            is Number -> value.toLong() != 0L
            is String -> value.toBoolean()
            else -> true
        }

        try {
            val bytes = getDeviceSummaryData(startTime, endTime, isMobile)
            result.success(bytes)
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }

    private val statusBarIconHandler = MethodChannel.MethodCallHandler { call, result ->
        when (call.method) {
            "setDownloadSpeed" -> {
                try {
                    val bytesPerSecond = argumentLong(call, "bytesPerSecond") ?: 0L
                    val title = call.argument<String>("title")
                    val text = call.argument<String>("text")
                    DynamicSpeedIcon.updateSmallIcon(
                        applicationContext, bytesPerSecond, title, text)
                } catch (_: Throwable) {
                    // Never let an icon update crash the main thread or fail
                    // the method channel.
                }
                result.success(null)
            }
            "setNotificationContent" -> {
                try {
                    val title = call.argument<String>("title") ?: "NetKeep"
                    val text = call.argument<String>("text") ?: ""
                    DynamicSpeedIcon.setNotificationContent(applicationContext, title, text)
                } catch (_: Throwable) {
                    // Never let an icon update crash the main thread or fail
                    // the method channel.
                }
                result.success(null)
            }
            "setSpeedIconEnabled" -> {
                try {
                    val enabled = when (val value = call.argument<Any>("enabled")) {
                        is Boolean -> value
                        is Number -> value.toInt() != 0
                        else -> false
                    }
                    DynamicSpeedIcon.setSpeedIconEnabled(applicationContext, enabled)
                } catch (_: Throwable) {
                    // Never let an icon update crash the main thread or fail
                    // the method channel.
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    init {
        if (!listenerRegistered) {
            listenerRegistered = true
            FlutterForegroundTaskPlugin.addTaskLifecycleListener(
                object : FlutterForegroundTaskLifecycleListener {
                    override fun onEngineCreate(flutterEngine: FlutterEngine?) {
                        // Registers the live stats channel on the background
                        // service engine so the keep-alive task can call
                        // TrafficStats from its own isolate.
                        if (flutterEngine == null) return
                        MethodChannel(
                            flutterEngine.dartExecutor.binaryMessenger,
                            networkStatsChannel
                        ).setMethodCallHandler(liveStatsHandler)
                        MethodChannel(
                            flutterEngine.dartExecutor.binaryMessenger,
                            statusBarIconChannel
                        ).setMethodCallHandler(statusBarIconHandler)
                    }

                    override fun onTaskStart(starter: FlutterForegroundTaskStarter) {}

                    override fun onTaskRepeatEvent() {}

                    override fun onTaskDestroy() {}

                    override fun onEngineWillDestroy() {}
                }
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, networkStatsChannel)
            .setMethodCallHandler(liveStatsHandler)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, dataUsageChannel)
            .setMethodCallHandler(dataUsageHandler)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, statusBarIconChannel)
            .setMethodCallHandler(statusBarIconHandler)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, vpnChannel)
            .setMethodCallHandler(vpnHandler)
        // Live stage/statistics pushed by HutchVpnService while the WireGuard
        // relay is up.
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, vpnEventsChannel)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    HutchVpnService.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    HutchVpnService.eventSink = null
                }
            })
    }

    private val vpnHandler = MethodChannel.MethodCallHandler { call, result ->
        when (call.method) {
            "startWireGuard" -> {
                val wgQuick = call.argument<String>("wgQuick")
                try {
                    if (wgQuick.isNullOrBlank()) {
                        result.error("VPN_ERROR", "Missing WireGuard config", null)
                        return@MethodCallHandler
                    }
                    val pending = VpnService.prepare(this)
                    if (pending != null) {
                        // User must approve the VPN connection first; the relay
                        // is launched from onActivityResult once approved.
                        pendingWgQuick = wgQuick
                        startActivityForResult(pending, WG_VPN_REQUEST_CODE)
                        result.success(mapOf(
                            "started" to false,
                            "consentRequired" to true
                        ))
                    } else {
                        launchWireGuardRelay(wgQuick)
                        result.success(mapOf(
                            "started" to HutchVpnService.isActive,
                            "consentRequired" to false
                        ))
                    }
                } catch (e: Exception) {
                    result.error("VPN_ERROR", e.message, null)
                }
            }
            "stopWireGuard" -> {
                try {
                    stopService(Intent(this, HutchVpnService::class.java))
                    result.success(true)
                } catch (e: Exception) {
                    result.error("VPN_ERROR", e.message, null)
                }
            }
            "checkVpnPermission" -> {
                result.success(try {
                    VpnService.prepare(this) == null
                } catch (e: Exception) {
                    false
                })
            }
            "getVpnStatus" -> {
                result.success(HutchVpnService.isActive)
            }
            "getWgStatus" -> {
                result.success(mapOf(
                    "stage" to HutchVpnService.stage,
                    "active" to HutchVpnService.isActive,
                    "rxBytes" to HutchVpnService.rxBytes,
                    "txBytes" to HutchVpnService.txBytes,
                    "handshakeAgeMs" to HutchVpnService.handshakeAgeMs
                ))
            }
            "getDeviceInfo" -> {
                result.success(mapOf(
                    "device" to Build.DEVICE,
                    "model" to Build.MODEL,
                    "android" to Build.VERSION.RELEASE,
                    "sdk" to Build.VERSION.SDK_INT
                ))
            }
            else -> result.notImplemented()
        }
    }

    private fun launchWireGuardRelay(wgQuick: String) {
        try {
            val vpnIntent = Intent(this, HutchVpnService::class.java)
                .setAction(HutchVpnService.ACTION_START)
                .putExtra(HutchVpnService.EXTRA_WG_QUICK, wgQuick)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(vpnIntent)
            } else {
                startService(vpnIntent)
            }
            android.util.Log.d("MainActivity", "WireGuard relay started")
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error starting WireGuard relay: ${e.message}")
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == WG_VPN_REQUEST_CODE) {
            if (resultCode == RESULT_OK) {
                pendingWgQuick?.let { launchWireGuardRelay(it) }
            }
            pendingWgQuick = null
        }
    }

    // Hardware Interface Level එකෙන් Total Device Data Usage එක ගන්නා Method එක
    private fun getDeviceSummaryData(startTime: Long, endTime: Long, isMobile: Boolean): Long {
        val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        val networkType = if (isMobile) NetworkCapabilities.TRANSPORT_CELLULAR else NetworkCapabilities.TRANSPORT_WIFI

        return try {
            val bucket = networkStatsManager.querySummaryForDevice(
                networkType,
                null,
                startTime,
                endTime
            )
            bucket.rxBytes + bucket.txBytes
        } catch (e: Exception) {
            0L
        }
    }

    companion object {
        private const val WG_VPN_REQUEST_CODE = 4201

        @Volatile
        private var listenerRegistered = false

        /** wg-quick profile awaiting VPN consent, launched on approval. */
        @Volatile
        private var pendingWgQuick: String? = null

        /**
         * Safely reads a Long-typed argument from a method call. Dart sends
         * platform ints that can arrive as Integer/Long, so raw `as Long` casts
         * throw ClassCastException. Accepts any Number or a numeric String.
         */
        private fun argumentLong(call: MethodCall, name: String): Long? =
            when (val value = call.argument<Any>(name)) {
                is Number -> value.toLong()
                is String -> value.toLongOrNull()
                else -> null
            }

        private val liveStatsHandler = MethodChannel.MethodCallHandler { call, result ->
            when (call.method) {
                "getRxBytes" -> {
                    val rxBytes = TrafficStats.getTotalRxBytes()
                    result.success(if (rxBytes == TrafficStats.UNSUPPORTED.toLong()) 0L else rxBytes)
                }
                "getTxBytes" -> {
                    val txBytes = TrafficStats.getTotalTxBytes()
                    result.success(if (txBytes == TrafficStats.UNSUPPORTED.toLong()) 0L else txBytes)
                }
                else -> result.notImplemented()
            }
        }
    }
}
