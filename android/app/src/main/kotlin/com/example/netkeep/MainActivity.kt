package com.sapm.netkeep

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val dataUsageChannel = "com.netkeep.app/network_stats"

    // Bridges a few small platform capabilities the pure-Dart keep-alive
    // service cannot reach on its own: notification permission (so the
    // persistent foreground notification is visible on Android 13+) and
    // battery-optimization status/settings.
    private val platformChannel = "netkeep/platform"

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

    private val platformHandler = MethodChannel.MethodCallHandler { call, result ->
        when (call.method) {
            "ensureNotificationPermission" -> ensureNotificationPermission(result)
            "isNotificationPermissionGranted" -> result.success(notificationsEnabled())
            "isIgnoringBatteryOptimizations" -> {
                val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                result.success(pm.isIgnoringBatteryOptimizations(packageName))
            }
            "openBatteryOptimizationSettings" -> {
                try {
                    startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                    result.success(null)
                } catch (_: Exception) {
                    result.error("UNSUPPORTED", "Battery optimization settings unavailable", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private var pendingNotificationPermission: ((Boolean) -> Unit)? = null

    /**
     * Ensures the Android 13+ notification permission is granted so the
     * keep-alive foreground notification can actually be shown. On API < 33 the
     * permission is implicitly granted, so this resolves true immediately.
     * Denied - or the dialog not answered - resolves false, and the Dart side
     * refuses to start the service (the persistent notification is part of the
     * keep-alive UX).
     */
    private fun ensureNotificationPermission(result: MethodChannel.Result) {
        if (notificationsEnabled()) {
            result.success(true)
            return
        }
        pendingNotificationPermission = { granted -> result.success(granted) }
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_NOTIFICATION_PERMISSION,
        )
    }

    private fun notificationsEnabled(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            NotificationManagerCompat.from(this).areNotificationsEnabled()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createKeepAliveNotificationChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, dataUsageChannel)
            .setMethodCallHandler(dataUsageHandler)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, platformChannel)
            .setMethodCallHandler(platformHandler)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_NOTIFICATION_PERMISSION) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingNotificationPermission?.invoke(granted)
            pendingNotificationPermission = null
        }
    }

    /**
     * Creates the notification channel the Dart keep-alive service posts to.
     * flutter_background_service requires the channel to exist before
     * configure() runs, which happens from Dart main() after the activity is
     * created - so this always runs first.
     */
    private fun createKeepAliveNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            KEEP_ALIVE_CHANNEL_ID,
            "NetKeep Keep-Alive Service",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps the connection alive and reports latency."
            setShowBadge(false)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
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
        private const val REQUEST_NOTIFICATION_PERMISSION = 1001
        const val KEEP_ALIVE_CHANNEL_ID = "netkeep_keepalive_channel"

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
    }
}
