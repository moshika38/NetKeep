package com.example.netkeep

import android.app.usage.NetworkStatsManager
import android.content.Context
import android.net.NetworkCapabilities
import android.net.TrafficStats
import com.pravera.flutter_foreground_task.FlutterForegroundTaskLifecycleListener
import com.pravera.flutter_foreground_task.FlutterForegroundTaskPlugin
import com.pravera.flutter_foreground_task.FlutterForegroundTaskStarter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val networkStatsChannel = "netkeep/network_stats"
    private val dataUsageChannel = "com.netkeep.app/network_stats"
    private val statusBarIconChannel = "netkeep/status_bar_icon"

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
                    DynamicSpeedIcon.updateSmallIcon(applicationContext, bytesPerSecond)
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
        @Volatile
        private var listenerRegistered = false

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
