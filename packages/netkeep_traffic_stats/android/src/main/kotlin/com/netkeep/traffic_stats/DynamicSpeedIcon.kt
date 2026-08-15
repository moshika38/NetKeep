package com.netkeep.traffic_stats

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.Typeface
import kotlin.math.roundToInt

/**
 * Generates the dynamic speed glyph shown as the small icon of the keep-alive
 * foreground notification while "Display Network Speed" is on.
 *
 * Android status-bar small icons are alpha-masked: every non-transparent pixel
 * is tinted by the OS, so the icon is drawn as opaque white glyphs on a fully
 * transparent fixed 48x48 px canvas (24dp at 2x density - the OS shows it at
 * native size instead of auto-downscaling larger bitmaps, which is what made
 * the glyphs render tiny). The numeric value sits on the top line and the
 * unit ("kB/s"/"Mb/s") beneath it. Font sizes and positions are fixed, so
 * generating an icon is pure arithmetic with no text-bounds measurement or
 * scaling loops and can never block or ANR the caller.
 */
object DynamicSpeedIcon {

    // Exact 48x48 px canvas: Android's fixed 24dp status-bar slot at 2x
    // density, so the OS never auto-downscales the bitmap.
    private const val SIZE = 48
    private const val CENTER_X = 24f

    /**
     * Generates a fixed 48x48 px bitmap with the given download speed drawn as
     * two stacked rows: the bold numeric value on the top line (baseline y=25f)
     * and the unit beneath it (baseline y=45f), both horizontally
     * centered. The top text size is 32f so the font baseline clears the top
     * canvas boundary instead of clipping/blurring against it. Wrapped in a
     * try-catch so a draw failure falls back to a white dot instead of
     * crashing or freezing the caller.
     */
    fun createSpeedIcon(speedBytesPerSecond: Long): Bitmap {
        return try {
            val (numberString, unitString) = formatSpeed(speedBytesPerSecond)

            val bitmap = Bitmap.createBitmap(SIZE, SIZE, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            // Clear to 100% transparency so no stale or background pixel can
            // ever appear as a black box in the status bar.
            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)

            val paint = Paint().apply {
                isAntiAlias = true
                color = Color.WHITE
                typeface = Typeface.create("sans-serif-condensed", Typeface.BOLD)
                textAlign = Paint.Align.CENTER
            }

            // Top line (number): 32f with baseline y=25f keeps the glyphs clear
            // of the top canvas boundary.
            paint.textSize = 32f
            canvas.drawText(numberString, CENTER_X, 25f, paint)

            // Bottom line (unit): "kB/s"/"Mb/s".
            paint.textSize = 18f
            canvas.drawText(unitString, CENTER_X, 45f, paint)

            bitmap
        } catch (_: Throwable) {
            // Bitmap/draw failure: return a simple white dot so the status bar
            // never blanks out.
            val bitmap = Bitmap.createBitmap(SIZE, SIZE, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
            val paint = Paint().apply {
                isAntiAlias = true
                color = Color.WHITE
                style = Paint.Style.FILL
            }
            canvas.drawCircle(CENTER_X, CENTER_X, 8f, paint)
            bitmap
        }
    }

    /**
     * Splits a bytes-per-second value into the numeric value and the
     * unit for the two-line icon: whole kB/s below 1 Mb/s ("0", "100", "850"),
     * Mb/s with one decimal below 10 Mb/s ("1.2", "5.5") and whole Mb/s at 10 Mb/s
     * and above ("15", "20"). Values that round across a unit boundary (e.g.
     * 1023.8 kB/s) roll over to the next unit instead of producing an
     * over-wide value like "1024" that would clip at the fixed 32f size.
     */
    fun formatSpeed(bytesPerSecond: Long): Pair<String, String> {
        if (bytesPerSecond <= 0L) return "0" to "kB/s"

        val kb = bytesPerSecond / 1024.0
        // Round to the nearest KB but never truncate a positive speed to "0":
        // e.g. 500 bytes/s (~0.5 KB/s) must show "1", not "0". There is no
        // artificial minimum-speed threshold that would mask low speeds.
        val kbRounded = maxOf(1, kb.roundToInt())
        if (kbRounded < 1024) return "${kbRounded}" to "kB/s"

        val mb = kb / 1024.0
        if (mb < 10.0) return oneDecimalOrWhole(mb) to "Mb/s"
        val mbRounded = mb.roundToInt()
        if (mbRounded < 1024) return "${mbRounded}" to "Mb/s"

        val gb = mb / 1024.0
        if (gb < 10.0) return oneDecimalOrWhole(gb) to "Gb/s"
        return "${gb.roundToInt()}" to "Gb/s"
    }

    // Renders a sub-10 value with one decimal place, rolling over to a whole
    // number when rounding would reach 10 (e.g. "9.9", "10").
    private fun oneDecimalOrWhole(value: Double): String {
        val tenths = (value * 10.0).roundToInt()
        return if (tenths < 100) "${tenths / 10.0}" else "${tenths / 10}"
    }
}
