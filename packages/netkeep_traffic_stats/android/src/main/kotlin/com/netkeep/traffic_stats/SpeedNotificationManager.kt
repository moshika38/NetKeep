package com.netkeep.traffic_stats

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.graphics.drawable.IconCompat

/**
 * Owns the foreground-service notification (id 1000) for ALL live status-bar
 * updates while the keep-alive service is running.
 *
 * This is the ONLY code path that touches notification 1000 after the service
 * has started. The flutter_background_service plugin posts it once at startup
 * (that is how the service becomes foreground), after which every update - the
 * speed glyph every second and the keep-alive title/content on ping changes -
 * flows through the single persistent builder below. The Dart side
 * deliberately never calls the plugin's setForegroundNotificationInfo(), so no
 * competing builder (different visibility/group/priority) can ever re-post the
 * notification.
 *
 * Static metadata (PUBLIC visibility, STATUS category, MAX priority, hidden
 * zero timestamp, ten-zero sort key, fixed "netkeep_group") is locked down ONCE
 * when the builder is created and never re-applied or switched between
 * PRIVATE/PUBLIC or group/no-group across updates. Per-second updates only swap
 * the small-icon bitmap and the content text in place on the same builder
 * instance, so Android updates the notification instead of tearing it down and
 * recreating it (the status-bar icon blinking bug).
 */
object SpeedNotificationManager {

    // Same channel the keep-alive foreground service posts to, so the merged
    // notification is created and updated on the service channel. It is created
    // by MainActivity and by the background plugin on boot.
    const val KEEP_ALIVE_CHANNEL_ID = "netkeep_keepalive_channel"

    // The foreground-service notification id (matches the plugin's config), so
    // the speed glyph and the service icon share ONE notification and there is
    // no dual owner of id 1000.
    const val NOTIFICATION_ID = 1000

    private const val GROUP_KEY = "netkeep_group"

    // Ten leading zeros give the absolute highest sorting order so the icon
    // snaps to the left-most status-bar slot and other app notifications
    // cannot displace it.
    private const val SORT_KEY = "0000000000"

    private var persistentBuilder: NotificationCompat.Builder? = null

    private var speedActive = false
    private var lastRenderedText: String? = null
    private var lastTitle = "NetKeep Active"
    private var lastContent = "Keeping connection alive"

    @Synchronized
    private fun getOrCreateBuilder(context: Context, initialIcon: IconCompat): NotificationCompat.Builder {
        ensureChannel(context)
        var builder = persistentBuilder
        if (builder == null) {
            builder = NotificationCompat.Builder(context, KEEP_ALIVE_CHANNEL_ID)
                .setSmallIcon(initialIcon)
                .setContentIntent(buildLaunchIntent(context))
                // Static metadata - applied exactly once at creation, never
                // re-applied or switched between PRIVATE/PUBLIC.
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setCategory(NotificationCompat.CATEGORY_STATUS)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setShowWhen(false)
                .setWhen(0)
                .setSortKey(SORT_KEY)
                .setGroup(GROUP_KEY)
                .setPriority(NotificationCompat.PRIORITY_MAX)
            persistentBuilder = builder
        }
        return builder
    }

    @Synchronized
    fun updateSpeedNotification(context: Context, downloadBps: Long, uploadBps: Long) {
        val (numberString, unitString) = DynamicSpeedIcon.formatSpeed(downloadBps)
        val (upNumber, upUnit) = DynamicSpeedIcon.formatSpeed(uploadBps)
        val currentTextKey = "$numberString|$unitString|$upNumber|$upUnit"

        // Cache check: skip re-rendering and re-notifying when the speed text
        // did not change since the last tick, so the status-bar icon does not
        // flicker every second.
        if (speedActive && currentTextKey == lastRenderedText && persistentBuilder != null) {
            return
        }
        lastRenderedText = currentTextKey
        speedActive = true

        val icon = IconCompat.createWithBitmap(DynamicSpeedIcon.createSpeedIcon(downloadBps))
        val builder = getOrCreateBuilder(context, icon)

        val contentText = if (uploadBps > 0L) {
            "Download: $numberString $unitString   Upload: $upNumber $upUnit"
        } else {
            "$numberString $unitString"
        }

        // In-place update only: swap the dynamic parts on the SAME persistent
        // builder and re-notify the same id. Static visibility/category/sort
        // flags are deliberately NOT touched here.
        builder.setSmallIcon(icon)
        builder.setContentTitle(lastTitle)
        builder.setContentText(contentText)
        NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, builder.build())
    }

    /**
     * Updates the keep-alive title/content through the unified builder. While
     * the speed readout is active the speed line is shown instead, so the
     * content is only remembered here until the speed readout is turned off.
     */
    @Synchronized
    fun updateContent(context: Context, title: String, content: String) {
        if (title == lastTitle && content == lastContent && persistentBuilder != null) {
            return
        }
        lastTitle = title
        lastContent = content
        if (speedActive) return

        val icon = wifiIcon(context)
        val builder = getOrCreateBuilder(context, icon)
        builder.setSmallIcon(icon)
        builder.setContentTitle(title)
        builder.setContentText(content)
        NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, builder.build())
    }

    /**
     * Turns the speed readout off: the icon reverts to the static wifi glyph
     * and the last keep-alive title/content is shown again. The foreground
     * notification itself is NEVER cancelled - it belongs to the running
     * foreground service and must stay visible.
     */
    @Synchronized
    fun hideSpeedNotification(context: Context) {
        speedActive = false
        lastRenderedText = null

        val icon = wifiIcon(context)
        val builder = getOrCreateBuilder(context, icon)
        builder.setSmallIcon(icon)
        builder.setContentTitle(lastTitle)
        builder.setContentText(lastContent)
        NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, builder.build())
    }

    // The static wifi glyph used whenever the live speed readout is off. The
    // plugin ships its own copy of the app's wifi vector so the OFF state never
    // depends on the app's resource namespace.
    private fun wifiIcon(context: Context): IconCompat =
        IconCompat.createWithResource(context, R.drawable.ic_stat_netkeep)

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(KEEP_ALIVE_CHANNEL_ID) == null) {
            nm.createNotificationChannel(
                NotificationChannel(
                    KEEP_ALIVE_CHANNEL_ID,
                    "NetKeep Keep-Alive Service",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = "Keeps the connection alive and reports latency."
                    setShowBadge(false)
                }
            )
        }
    }

    private fun buildLaunchIntent(context: Context): PendingIntent? {
        return try {
            val intent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
                ?: return null
            var flags = PendingIntent.FLAG_UPDATE_CURRENT
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                flags = flags or PendingIntent.FLAG_IMMUTABLE
            }
            PendingIntent.getActivity(context, 0, intent, flags)
        } catch (_: Exception) {
            null
        }
    }
}
