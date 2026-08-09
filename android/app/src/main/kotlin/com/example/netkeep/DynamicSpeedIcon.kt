package com.example.netkeep

import android.app.Notification
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
 * Renders the live download speed as a small text bitmap that is used as the
 * dynamic status-bar small icon of the keep-alive foreground notification.
 *
 * Android status-bar icons are alpha-masked: every non-transparent pixel is
 * tinted by the OS, so the icon is produced as opaque white glyphs on a fully
 * transparent 48x48 px canvas. Font sizing is pure arithmetic based on the
 * label length (no text-bounds measurement, no scaling loops) so generating an
 * icon can never block or ANR the caller.
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

    // Status-bar small icons must be alpha-mask bitmaps. 48x48 px at ARGB_8888
    // matches the platform's canonical status-bar icon dimensions and keeps the
    // glyphs crisp without any scaling or density gymnastics.
    private const val BITMAP_SIZE_PX = 48
    private const val TEXT_CENTER_X = 24f

    // Standard readable font sizes chosen for the 48x48 canvas by label
    // length. 2-3 character labels ("0K", "1.2M") use 22f, 4 character labels
    // ("10.5M") drop to 18f so every glyph stays fully on-canvas.
    private fun textSizeForLength(length: Int): Float = when {
        length <= 3 -> 22f
        else -> 18f
    }

    /**
     * Compacts a bytes-per-second value into a 3-4 character label for the
     * status-bar icon: whole KB below 1 MB/s ("0K", "100K", "850K"), MB with
     * one decimal below 10 MB/s ("1.2M", "5.0M") and whole MB at 10 MB/s and
     * above ("15M", "20M").
     */
    fun formatShortSpeed(bytesPerSecond: Long): String {
        if (bytesPerSecond <= 0L) return "0K"

        val kb = bytesPerSecond / 1024.0
        if (kb < 1024.0) return "${kb.roundToInt()}K"

        val mb = kb / 1024.0
        if (mb < 10.0) return "${oneDecimal(mb)}M"
        if (mb < 1024.0) return "${mb.roundToInt()}M"

        val gb = mb / 1024.0
        return if (gb < 10.0) "${oneDecimal(gb)}G" else "${gb.roundToInt()}G"
    }

    private fun oneDecimal(value: Double): String =
        "${(value * 10.0).roundToInt() / 10.0}"

    /**
     * Generates a 48x48 px bitmap with the given speed text drawn in bold white
     * glyphs on a fully transparent background. White (alpha 255) on transparent
     * is exactly what Android's status-bar alpha masking expects, so the OS tints
     * the glyphs and never shows a black box. The whole generation is wrapped in
     * a try-catch so a draw failure falls back gracefully instead of crashing or
     * freezing the calling thread.
     */
    fun createSpeedIcon(speedText: String): IconCompat {
        return try {
            val label = if (speedText.isBlank()) "0K" else speedText

            val bitmap = Bitmap.createBitmap(
                BITMAP_SIZE_PX, BITMAP_SIZE_PX, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            // Clear the canvas to 100% transparency so no stale or background
            // pixel can ever appear as a black box in the status bar.
            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)

            val paint = Paint().apply {
                color = Color.WHITE
                isAntiAlias = true
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                textAlign = Paint.Align.CENTER
                textSize = textSizeForLength(label.length)
            }

            // Center vertically using static font metrics (single arithmetic
            // step, no bounds re-measurement) and horizontally with CENTER
            // alignment at the canvas midpoint.
            val yPos = (BITMAP_SIZE_PX / 2f) - ((paint.descent() + paint.ascent()) / 2f)
            canvas.drawText(label, TEXT_CENTER_X, yPos, paint)

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
            BITMAP_SIZE_PX, BITMAP_SIZE_PX, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
        val paint = Paint().apply {
            color = Color.WHITE
            isAntiAlias = true
            style = Paint.Style.FILL
        }
        canvas.drawCircle(BITMAP_SIZE_PX / 2f, BITMAP_SIZE_PX / 2f, 8f, paint)
        return IconCompat.createWithBitmap(bitmap)
    }

    // Single background thread so notification refreshes never run on the main
    // thread and never block foreground-service init or Flutter engine startup.
    private val iconUpdateExecutor = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "dynamic-speed-icon").apply { isDaemon = true }
    }

    /**
     * Rebuilds the running foreground notification with a fresh speed bitmap
     * as its small icon so the status bar reflects the live download speed.
     * Reads the service id, channel id and body text from the
     * flutter_foreground_task preferences so it stays in sync with the
     * notification the plugin manages. Returns immediately: the actual build
     * and notify run on a dedicated background thread.
     */
    fun updateSmallIcon(context: Context, bytesPerSecond: Long) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return

        val appContext = context.applicationContext
        val label = formatShortSpeed(bytesPerSecond)
        iconUpdateExecutor.execute {
            try {
                updateNotification(appContext, label)
            } catch (_: Throwable) {
                // Never let a status-bar refresh crash or block any thread.
            }
        }
    }

    private fun updateNotification(context: Context, label: String) {
        val prefs = context.getSharedPreferences(
            NOTIFICATION_OPTIONS_PREFS, Context.MODE_PRIVATE)
        val serviceId = prefs.getInt(
            SERVICE_ID, prefs.getInt(NOTIFICATION_ID, DEFAULT_SERVICE_ID))
        val channelId = prefs.getString(
            NOTIFICATION_CHANNEL_ID, null) ?: DEFAULT_CHANNEL_ID
        val title = prefs.getString(NOTIFICATION_CONTENT_TITLE, null) ?: "NetKeep"
        val text = prefs.getString(NOTIFICATION_CONTENT_TEXT, null) ?: ""

        // Always render the dynamic bitmap - even at 0 B/s - so the status bar
        // icon never blinks between the static app icon and the speed text.
        val icon = createSpeedIcon(label)
        val contentIntent = buildLaunchIntent(context)

        val notification: Notification
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val builder = Notification.Builder(context, channelId)
                .setSmallIcon(icon.toIcon())
                .setContentTitle(title)
                .setContentText(text)
                .setContentIntent(contentIntent)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setShowWhen(true)
            builder.style = Notification.BigTextStyle()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                builder.setForegroundServiceBehavior(
                    Notification.FOREGROUND_SERVICE_IMMEDIATE)
            }
            notification = builder.build()
        } else {
            notification = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(icon)
                .setContentTitle(title)
                .setContentText(text)
                .setContentIntent(contentIntent)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setShowWhen(true)
                .setStyle(NotificationCompat.BigTextStyle().bigText(text))
                .build()
        }

        val nm = context.getSystemService(NotificationManager::class.java)
        nm.notify(serviceId, notification)
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
