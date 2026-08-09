package com.example.netkeep

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.Typeface
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.graphics.drawable.IconCompat
import java.util.concurrent.Executors
import kotlin.math.roundToInt

/**
 * Renders the live download speed as a compact two-line text bitmap that is
 * used as the dynamic status-bar small icon of the keep-alive foreground
 * notification: the numeric value on top and the lowercase unit ("kb"/"mb")
 * underneath, with no separator line so all vertical space goes to the glyphs.
 *
 * Android status-bar icons are alpha-masked: every non-transparent pixel is
 * tinted by the OS, so the icon is produced as opaque white glyphs on a fully
 * transparent fixed 48x48 px canvas. 48x48 px matches Android's 24dp
 * status-bar slot at 2x density, so the OS shows it at native size instead of
 * auto-downscaling larger bitmaps (which made the text render tiny). Font
 * sizes and positions are fixed, so generating an icon is pure arithmetic with
 * no text-bounds measurement or scaling loops and can never block or ANR the
 * caller.
 */
object DynamicSpeedIcon {

    // flutter_foreground_task stores its notification state here.
    private const val PREFS_PREFIX = "com.pravera.flutter_foreground_task.prefs."
    private const val NOTIFICATION_OPTIONS_PREFS = PREFS_PREFIX + "NOTIFICATION_OPTIONS"
    private const val SERVICE_ID = "serviceId"
    private const val NOTIFICATION_ID = "notificationId"
    private const val NOTIFICATION_CHANNEL_ID = "notificationChannelId"
    private const val NOTIFICATION_CONTENT_TITLE = "notificationContentTitle"
    private const val NOTIFICATION_CONTENT_TEXT = "notificationContentText"

    private const val DEFAULT_SERVICE_ID = 1000
    private const val DEFAULT_CHANNEL_ID = "foreground_service"

    // Status-bar small icons must be alpha-mask bitmaps. A fixed 48x48 px
    // ARGB_8888 canvas matches Android's 24dp status-bar slot at 2x density,
    // so the OS shows it at native size instead of auto-downscaling larger
    // bitmaps, which is what made the glyphs render tiny.
    private const val BITMAP_SIZE_PX = 48
    private const val TEXT_CENTER_X = 24f

    // Fallback white-dot icon uses the same 48x48 status-bar slot.
    private const val FALLBACK_SIZE_PX = 48

    /**
     * Compacts a bytes-per-second value into a lowercase short label for the
     * status-bar icon: whole KB below 1 MB/s ("0kb", "100kb", "850kb"), MB
     * with one decimal below 10 MB/s ("1.2mb", "5.5mb") and whole MB at
     * 10 MB/s and above ("15mb", "20mb"). Values that round across a unit
     * boundary (e.g. 1023.8 KB/s) roll over to the next unit instead of
     * producing an over-wide label like "1024kb" that would clip.
     */
    fun formatShortSpeed(bytesPerSecond: Long): String {
        val (value, unit) = speedParts(bytesPerSecond)
        return "$value$unit"
    }

    /**
     * Splits a bytes-per-second value into the numeric value and the lowercase
     * unit so the two-line status-bar icon can draw them as separate rows.
     * Uses the same compaction/roll-over rules as [formatShortSpeed]: whole KB
     * below 1 MB/s ("0", "100", "850"), one decimal below 10 MB/s ("1.2",
     * "5.5") and whole MB at 10 MB/s and above ("15", "20"). Values that round
     * across a unit boundary (e.g. 1023.8 KB/s) roll over to the next unit
     * instead of producing an over-wide value like "1024" that would clip.
     */
    private fun speedParts(bytesPerSecond: Long): Pair<String, String> {
        if (bytesPerSecond <= 0L) return "0" to "kb"

        val kb = bytesPerSecond / 1024.0
        val kbRounded = kb.roundToInt()
        if (kbRounded < 1024) return "${kbRounded}" to "kb"

        val mb = kb / 1024.0
        if (mb < 10.0) return oneDecimalOrWhole(mb) to "mb"
        val mbRounded = mb.roundToInt()
        if (mbRounded < 1024) return "${mbRounded}" to "mb"

        val gb = mb / 1024.0
        if (gb < 10.0) return oneDecimalOrWhole(gb) to "gb"
        return "${gb.roundToInt()}" to "gb"
    }

    // Renders a sub-10 value with one decimal place, rolling over to a whole
    // number when rounding would reach 10 (e.g. "9.9", "10").
    private fun oneDecimalOrWhole(value: Double): String {
        val tenths = (value * 10.0).roundToInt()
        return if (tenths < 100) "${tenths / 10.0}" else "${tenths / 10}"
    }

    /**
     * Generates a fixed 48x48 px bitmap with the given speed text drawn as two
     * stacked rows: the bold numeric value near the top and the lowercase unit
     * beneath it, with no separator line so every pixel of vertical space goes
     * to the glyphs. White (alpha 255) on transparent is exactly what Android's
     * status-bar alpha masking expects, so the OS tints the glyphs and never
     * shows a black box. Both rows use the condensed Sans-Serif-Condensed Bold
     * face so wide values and units stay crisp and fully on-canvas at the
     * native status-bar size. The whole generation is wrapped in a try-catch so
     * a draw failure falls back gracefully instead of crashing or freezing the
     * calling thread.
     */
    fun createSpeedIcon(context: Context, speedText: String): IconCompat {
        return try {
            val label = if (speedText.isBlank()) "0kb" else speedText
            // Speed labels always end in a two-letter unit ("kb"/"mb"/"gb"),
            // so the value and unit rows can be split by position.
            val value = label.dropLast(2)
            val unit = label.takeLast(2)

            // Exact 48x48 px canvas: this matches Android's fixed 24dp
            // status-bar slot at 2x density, so the OS never auto-downscales
            // the bitmap (which is what made larger canvases render tiny).
            val bitmap = Bitmap.createBitmap(
                BITMAP_SIZE_PX, BITMAP_SIZE_PX, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            // Clear the canvas to 100% transparency so no stale or background
            // pixel can ever appear as a black box in the status bar.
            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)

            val paint = Paint().apply {
                color = Color.WHITE
                isAntiAlias = true
                isFakeBoldText = false
                textAlign = Paint.Align.CENTER
            }

            // Numeric value row: largest text, drawn on the top line at the
            // canvas midline x (24f) with baseline y = 23f. The condensed bold
            // face keeps wide values ("450", "10.5") inside the 48px width.
            paint.textSize = 31f
            paint.typeface = Typeface.create("sans-serif-condensed", Typeface.BOLD)
            canvas.drawText(value, TEXT_CENTER_X, 23f, paint)

            // Unit row: smaller text, drawn on the bottom line at the canvas
            // midline x (24f) with baseline y = 45f.
            paint.textSize = 20f
            canvas.drawText(unit, TEXT_CENTER_X, 45f, paint)

            IconCompat.createWithBitmap(bitmap)
        } catch (_: Throwable) {
            // Bitmap/draw failure: return a simple white dot icon instead so the
            // status bar never blanks out or the app never freezes/crashes.
            runCatching { fallbackIcon() }.getOrNull() ?: IconCompat.createWithBitmap(
                Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888))
        }
    }

    private fun fallbackIcon(): IconCompat {
        val bitmap = Bitmap.createBitmap(
            FALLBACK_SIZE_PX, FALLBACK_SIZE_PX, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
        val paint = Paint().apply {
            color = Color.WHITE
            isAntiAlias = true
            style = Paint.Style.FILL
        }
        canvas.drawCircle(FALLBACK_SIZE_PX / 2f, FALLBACK_SIZE_PX / 2f, 8f, paint)
        return IconCompat.createWithBitmap(bitmap)
    }

    // Cached state for the status-bar small icon. Both fields are only read
    // and written from the single icon-update thread below, so they never need
    // locking. `lastSpeedText` is the most recently rendered speed label: when
    // a new tick formats the same label (e.g. it stays "0kb") the bitmap is
    // NOT regenerated and the notification is NOT re-notified, which stops the
    // status-bar icon from flickering/re-rendering on every tick.
    private var lastSpeedText = ""
    private var lastContentTitle: String? = null
    private var lastContentText: String? = null
    private var speedIconActive = true

    // The exact small icon currently shown in the status bar. Kept so a
    // content-only refresh (e.g. a ping text change with an unchanged speed
    // label) can re-notify with the same bitmap instead of regenerating it.
    private var currentSmallIcon: IconCompat? = null

    // Single persistent NotificationCompat.Builder reused across every status
    // bar update so the notification is never torn down and recreated (which
    // is what made the icon blink). It is the ONLY builder that ever calls
    // notify() for the service id: the plugin's own updateService() path is
    // deliberately never used for live updates, so no competing
    // notification (different visibility/group config) can race it. Its static
    // config (PUBLIC visibility, no group keys) matches the plugin's initial
    // foreground notification exactly, so even at service start there is no
    // conflicting builder in play. Only rebuilt when the underlying channel id
    // changes. All fields here are only touched from the single icon-update
    // thread below, so they never need locking.
    private var persistentBuilder: NotificationCompat.Builder? = null
    private var persistentBuilderChannelId = ""
    private var persistentServiceId = DEFAULT_SERVICE_ID

    // Single background thread so notification refreshes never run on the main
    // thread and never block foreground-service init or Flutter engine startup.
    private val iconUpdateExecutor = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "dynamic-speed-icon").apply { isDaemon = true }
    }

    /**
     * Rebuilds the running foreground notification with a fresh speed bitmap
     * as its small icon so the status bar reflects the live download speed.
     * Optional title/text carry the visible notification content (speed line +
     * ISP/ping) from the Dart task; when present they are persisted first so
     * the unified builder below is the ONLY code path that ever calls notify()
     * for the service id (the plugin's updateService() is never used for live
     * updates, which would fire a competing notify() with a different
     * visibility/group config). Returns immediately: the actual build and
     * notify run on a dedicated background thread.
     */
    fun updateSmallIcon(context: Context, bytesPerSecond: Long, title: String? = null, text: String? = null) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return

        val appContext = context.applicationContext
        val label = formatShortSpeed(bytesPerSecond)
        iconUpdateExecutor.execute {
            try {
                if (!speedIconActive) return@execute
                // Persist any new visible content so the unified builder (and
                // any service restart) reads the latest title/text.
                val contentProvided = title != null && text != null
                if (contentProvided) {
                    persistNotificationContent(appContext, title!!, text!!)
                }
                val contentChanged = contentProvided &&
                    (title != lastContentTitle || text != lastContentText)
                // Skip regenerating the bitmap and re-notifying when BOTH the
                // speed label and the visible content are unchanged, so the
                // status-bar icon is not re-rendered every tick (flickering).
                if (!contentChanged && label == lastSpeedText) return@execute
                if (contentProvided) {
                    lastContentTitle = title
                    lastContentText = text
                }
                lastSpeedText = label
                val icon = createSpeedIcon(appContext, label)
                currentSmallIcon = icon
                buildAndNotify(appContext, icon)
            } catch (_: Throwable) {
                // Never let a status-bar refresh crash or block any thread.
            }
        }
    }

    /**
     * Updates only the visible notification content (title/text) through the
     * unified builder, keeping the current small icon intact. Used when the
     * speed display is disabled so the plugin's updateService() -- which would
     * fire a competing notify() with default settings -- is never called.
     */
    fun setNotificationContent(context: Context, title: String, text: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return

        val appContext = context.applicationContext
        iconUpdateExecutor.execute {
            try {
                if (title == lastContentTitle && text == lastContentText) return@execute
                lastContentTitle = title
                lastContentText = text
                persistNotificationContent(appContext, title, text)
                val icon = currentSmallIcon
                    ?: IconCompat.createWithResource(appContext, R.mipmap.ic_launcher)
                buildAndNotify(appContext, icon)
            } catch (_: Throwable) {
                // Never let a status-bar refresh crash or block any thread.
            }
        }
    }

    // Writes the notification content back to the same prefs file the plugin
    // reads, so a service restart or the plugin's own notification still sees
    // the latest title/text.
    private fun persistNotificationContent(context: Context, title: String, text: String) {
        context.getSharedPreferences(NOTIFICATION_OPTIONS_PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(NOTIFICATION_CONTENT_TITLE, title)
            .putString(NOTIFICATION_CONTENT_TEXT, text)
            .apply()
    }

    /**
     * Switches the status-bar small icon between the live speed bitmap and the
     * static app icon. Called when the "Show Network Speed" setting changes:
     * disabling reverts the icon to the launcher icon so no blank/black
     * transparent placeholder is ever left in the status bar, and enabling
     * forces the next tick to re-render the speed bitmap (and shows "0kb"
     * immediately when coming back from the static app icon).
     */
    fun setSpeedIconEnabled(context: Context, enabled: Boolean) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return

        val appContext = context.applicationContext
        iconUpdateExecutor.execute {
            try {
                if (enabled) {
                    val wasInactive = !speedIconActive
                    speedIconActive = true
                    // Force the next updateSmallIcon to render even if the same
                    // text was rendered before the icon was swapped away.
                    lastSpeedText = ""
                    if (wasInactive) {
                        // Returning from the static app icon: show a speed
                        // bitmap right away instead of waiting for the next tick.
                        val icon = createSpeedIcon(appContext, formatShortSpeed(0L))
                        currentSmallIcon = icon
                        buildAndNotify(appContext, icon)
                    }
                } else if (speedIconActive) {
                    speedIconActive = false
                    lastSpeedText = ""
                    val icon = IconCompat.createWithResource(appContext, R.mipmap.ic_launcher)
                    currentSmallIcon = icon
                    buildAndNotify(appContext, icon)
                }
            } catch (_: Throwable) {
                // Never let a status-bar refresh crash or block any thread.
            }
        }
    }

    private fun buildAndNotify(context: Context, smallIcon: IconCompat) {
        val prefs = context.getSharedPreferences(
            NOTIFICATION_OPTIONS_PREFS, Context.MODE_PRIVATE)
        val serviceId = prefs.getInt(
            SERVICE_ID, prefs.getInt(NOTIFICATION_ID, DEFAULT_SERVICE_ID))
        val channelId = prefs.getString(
            NOTIFICATION_CHANNEL_ID, null) ?: DEFAULT_CHANNEL_ID
        val title = prefs.getString(NOTIFICATION_CONTENT_TITLE, null) ?: "NetKeep"
        val text = prefs.getString(NOTIFICATION_CONTENT_TEXT, null) ?: ""

        // Reuse the single persistent builder unless the underlying channel id
        // changed, so speed ticks never allocate a new builder or re-apply the
        // static visibility/category/priority flags. This is the ONLY notify()
        // path for the service id -- the plugin's updateService() is never used
        // for live updates, so no competing builder config can race it.
        if (persistentBuilder == null ||
            channelId != persistentBuilderChannelId
        ) {
            persistentBuilder = buildPersistentBuilder(context, channelId)
            persistentBuilderChannelId = channelId
            persistentServiceId = serviceId
        }

        // Per-tick updates only swap the content and small icon on the existing
        // builder and re-notify with the same service id so Android updates the
        // notification IN-PLACE instead of tearing it down and recreating it,
        // which is what caused the icon to blink/disappear. startForeground()
        // is never called here: the foreground-service framework already did it
        // once when the service started, and re-calling it on every tick
        // triggers SystemUI's animation/blink of the icon slot.
        val builder = persistentBuilder ?: return
        builder.setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(smallIcon)
        val nm = context.getSystemService(NotificationManager::class.java)
        nm.notify(serviceId, builder.build())
    }

    // Creates the persistent notification builder once. All static metadata is
    // locked down here -- PUBLIC visibility, service category, ongoing,
    // only-alert-once, no timestamp, fixed sort key, LOW priority -- and NEVER
    // switches between PRIVATE/PUBLIC or group/no-group across updates. Group
    // keys are deliberately NOT set so the notification carries exactly the
    // same config (PUBLIC visibility, no group) as the plugin's initial
    // foreground notification, leaving no conflicting settings to race.
    // Per-tick updates only touch title/text/small icon on this same builder
    // instance.
    private fun buildPersistentBuilder(
        context: Context,
        channelId: String
    ): NotificationCompat.Builder {
        return NotificationCompat.Builder(context, channelId)
            .setContentIntent(buildLaunchIntent(context))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            // Keep the icon pinned in place: PUBLIC visibility, no timestamp
            // re-sorting, a fixed sort key, and a low-priority ongoing service
            // category so Android never re-orders the status bar entry and
            // SystemUI never animates/blinks the icon slot on update. No group
            // key is set so this config exactly matches the plugin's initial
            // foreground notification (PUBLIC visibility, no group).
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setShowWhen(false)
            .setSortKey("0_netkeep")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    setForegroundServiceBehavior(
                        NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
                }
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
