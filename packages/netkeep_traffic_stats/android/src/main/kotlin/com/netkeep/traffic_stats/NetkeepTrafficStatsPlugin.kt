package com.netkeep.traffic_stats

import android.content.Context
import android.net.TrafficStats
import id.flutter.flutter_background_service.BackgroundService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges several capabilities over method channels:
 *  - the `netkeep/network_stats` channel exposes Android's `TrafficStats` byte
 *    counters to the Dart speed monitor;
 *  - the `netkeep/speed_notification` channel posts/updates the real-time speed
 *    status-bar notification;
 *  - the `netkeep/wakelock` channel acquires/releases the keep-alive service's
 *    partial CPU wake lock. Battery Saver releases it so Android may sleep the
 *    CPU and defer the ping loop.
 *
 * Auto-registered on *every* Flutter engine in the process - including the
 * separate engine backing the `flutter_background_service` isolate - so the
 * wake lock can be balanced even when the service resumes after a reboot.
 */
class NetkeepTrafficStatsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var speedChannel: MethodChannel? = null
    private var wakeLockChannel: MethodChannel? = null
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }
        speedChannel = MethodChannel(binding.binaryMessenger, SPEED_CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }
        wakeLockChannel = MethodChannel(binding.binaryMessenger, WAKELOCK_CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        speedChannel?.setMethodCallHandler(null)
        speedChannel = null
        wakeLockChannel?.setMethodCallHandler(null)
        wakeLockChannel = null
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getRxBytes" -> {
                val rxBytes = TrafficStats.getTotalRxBytes()
                result.success(if (rxBytes == TrafficStats.UNSUPPORTED.toLong()) 0L else rxBytes)
            }
            "getTxBytes" -> {
                val txBytes = TrafficStats.getTotalTxBytes()
                result.success(if (txBytes == TrafficStats.UNSUPPORTED.toLong()) 0L else txBytes)
            }
            "updateSpeedIcon" -> {
                val ctx = context
                if (ctx != null) {
                    val download = argumentLong(call, "downloadBytesPerSecond") ?: 0L
                    val upload = argumentLong(call, "uploadBytesPerSecond") ?: 0L
                    SpeedNotificationManager.updateSpeedNotification(ctx, download, upload)
                }
                result.success(null)
            }
            "hideSpeedIcon" -> {
                val ctx = context
                if (ctx != null) {
                    SpeedNotificationManager.hideSpeedNotification(ctx)
                }
                result.success(null)
            }
            "updateContent" -> {
                val ctx = context
                if (ctx != null) {
                    val title = call.argument<String>("title") ?: "NetKeep Active"
                    val content = call.argument<String>("content") ?: ""
                    SpeedNotificationManager.updateContent(ctx, title, content)
                }
                result.success(null)
            }
            "setWakelock" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                setWakelock(enabled)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

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

    /**
     * Acquires (or releases) the partial CPU wake lock shared with the
     * `flutter_background_service` plugin. The plugin creates the lock lazily on
     * first start, so acquiring before the service runs is a harmless no-op.
     * `isHeld` guards keep the reference-counted lock balanced.
     */
    private fun setWakelock(enabled: Boolean) {
        val appContext = context ?: return
        try {
            val lock = BackgroundService.getLock(appContext)
            if (enabled) {
                if (!lock.isHeld) lock.acquire()
            } else {
                if (lock.isHeld) lock.release()
            }
        } catch (_: Exception) {
            // Wake lock unavailable - service not running yet / unsupported.
        }
    }

    companion object {
        private const val CHANNEL_NAME = "netkeep/network_stats"
        private const val SPEED_CHANNEL_NAME = "netkeep/speed_notification"
        private const val WAKELOCK_CHANNEL_NAME = "netkeep/wakelock"
    }
}
