package ir.psdkjoon.papuy

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Rect
import android.graphics.RectF
import androidx.core.graphics.ColorUtils
import androidx.core.graphics.PathParser
import android.widget.RemoteViews
import java.io.File

object WidgetState {
    private const val PREFS = "widgets"
    private const val ART_FILE = "widget_art.png"

    @Volatile var title = ""
    @Volatile var artist = ""
    @Volatile var album = ""
    @Volatile var playing = false
    @Volatile var shuffle = false
    @Volatile var repeat = 0
    @Volatile var durationMs = 0L
    @Volatile var positionMs = 0L
    @Volatile var active = false
    @Volatile var art: Bitmap? = null

    private var loaded = false

    fun set(
        context: Context,
        title: String,
        artist: String,
        album: String,
        playing: Boolean,
        shuffle: Boolean,
        repeat: Int,
        durationMs: Long,
        positionMs: Long,
        art: Bitmap?,
        artChanged: Boolean,
    ) {
        loaded = true
        this.title = title
        this.artist = artist
        this.album = album
        this.playing = playing
        this.shuffle = shuffle
        this.repeat = repeat
        this.durationMs = durationMs
        this.positionMs = positionMs
        this.active = true
        if (artChanged) {
            this.art = art?.let { Bitmap.createScaledBitmap(it, 256, 256, true) }
            saveArt(context)
        }
        save(context)
        PlayerWidgets.update(context)
    }

    fun clear(context: Context) {
        loaded = true
        active = false
        playing = false
        title = ""
        artist = ""
        album = ""
        art = null
        File(context.cacheDir, ART_FILE).delete()
        save(context)
        PlayerWidgets.update(context)
    }

    fun ensureLoaded(context: Context) {
        if (loaded) return
        loaded = true
        val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        active = prefs.getBoolean("active", false)
        title = prefs.getString("title", "") ?: ""
        artist = prefs.getString("artist", "") ?: ""
        album = prefs.getString("album", "") ?: ""
        playing = false
        shuffle = prefs.getBoolean("shuffle", false)
        repeat = prefs.getInt("repeat", 0)
        durationMs = prefs.getLong("duration", 0L)
        positionMs = prefs.getLong("position", 0L)
        val file = File(context.cacheDir, ART_FILE)
        art = if (file.isFile) BitmapFactory.decodeFile(file.absolutePath) else null
    }

    private fun save(context: Context) {
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean("active", active)
            .putString("title", title)
            .putString("artist", artist)
            .putString("album", album)
            .putBoolean("shuffle", shuffle)
            .putInt("repeat", repeat)
            .putLong("duration", durationMs)
            .putLong("position", positionMs)
            .apply()
    }

    private fun saveArt(context: Context) {
        val file = File(context.cacheDir, ART_FILE)
        val bitmap = art
        if (bitmap == null) {
            file.delete()
            return
        }
        try {
            file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        } catch (_: Exception) {
        }
    }
}

object PlayerWidgets {
    private val mocha = mapOf(
        "rosewater" to "f5e0dc", "flamingo" to "f2cdcd", "pink" to "f5c2e7", "mauve" to "cba6f7",
        "red" to "f38ba8", "peach" to "fab387", "yellow" to "f9e2af", "green" to "a6e3a1",
        "teal" to "94e2d5", "sky" to "89dceb", "blue" to "89b4fa", "lavender" to "b4befe",
    )
    private val latte = mapOf(
        "rosewater" to "dc8a78", "flamingo" to "dd7878", "pink" to "ea76cb", "mauve" to "8839ef",
        "red" to "d20f39", "peach" to "fe640b", "yellow" to "df8e1d", "green" to "40a02b",
        "teal" to "179299", "sky" to "04a5e5", "blue" to "1e66f5", "lavender" to "7287fd",
    )

    private val providers = listOf(
        WidgetSquare::class.java,
        WidgetBar::class.java,
        WidgetWide::class.java,
        WidgetButton::class.java,
    )

    fun update(context: Context) {
        val app = context.applicationContext
        WidgetState.ensureLoaded(app)
        val manager = AppWidgetManager.getInstance(app)
        for (provider in providers) {
            val ids = manager.getAppWidgetIds(ComponentName(app, provider))
            if (ids.isEmpty()) continue
            val views = when (provider) {
                WidgetSquare::class.java -> square(app)
                WidgetBar::class.java -> bar(app)
                WidgetWide::class.java -> wide(app)
                else -> button(app)
            }
            manager.updateAppWidget(ids, views)
        }
    }

    private fun themePrefs(context: Context) =
        context.getSharedPreferences("launcher_icon", Context.MODE_PRIVATE)

    private fun dark(context: Context): Boolean = when (themePrefs(context).getString("mode", "system")) {
        "dark" -> true
        "light" -> false
        else -> (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
            Configuration.UI_MODE_NIGHT_YES
    }

    private fun accent(context: Context): Int {
        val name = themePrefs(context).getString("accent", "mauve") ?: "mauve"
        val table = if (dark(context)) mocha else latte
        return Color.parseColor("#" + (table[name] ?: table.getValue("mauve")))
    }

    private fun onAccent(context: Context): Int =
        if (dark(context)) Color.parseColor("#1e1e2e") else Color.parseColor("#ffffff")

    private fun foreground(context: Context): Int =
        if (dark(context)) Color.parseColor("#cdd6f4") else Color.parseColor("#4c4f69")

    private fun card(context: Context): Int {
        val base = if (dark(context)) Color.parseColor("#1e1e2e") else Color.parseColor("#eff1f5")
        return ColorUtils.blendARGB(base, accent(context), if (dark(context)) 0.18f else 0.22f)
    }

    private fun artBackground(context: Context): Int =
        ColorUtils.blendARGB(card(context), accent(context), 0.3f)

    private fun circle(color: Int): Bitmap {
        val size = 96
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color }
        Canvas(bitmap).drawCircle(size / 2f, size / 2f, size / 2f, paint)
        return bitmap
    }

    private fun roundedArt(source: Bitmap, background: Int): Bitmap {
        val size = 256
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val radius = size * 0.16f
        val clip = Path().apply {
            addRoundRect(RectF(0f, 0f, size.toFloat(), size.toFloat()), radius, radius, Path.Direction.CW)
        }
        canvas.clipPath(clip)
        canvas.drawColor(background)
        val side = minOf(source.width, source.height)
        val from = Rect((source.width - side) / 2, (source.height - side) / 2, (source.width + side) / 2, (source.height + side) / 2)
        canvas.drawBitmap(source, from, Rect(0, 0, size, size), Paint(Paint.FILTER_BITMAP_FLAG))
        return output
    }

    private fun placeholder(context: Context): Bitmap {
        val size = 256
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val radius = size * 0.16f
        canvas.drawRoundRect(
            RectF(0f, 0f, size.toFloat(), size.toFloat()),
            radius,
            radius,
            Paint(Paint.ANTI_ALIAS_FLAG).apply { color = artBackground(context) },
        )
        val note = PathParser.createPathFromPathData(
            "M12,3v10.55c-0.59,-0.34 -1.27,-0.55 -2,-0.55 -2.21,0 -4,1.79 -4,4s1.79,4 4,4 4,-1.79 4,-4V7h4V3h-6z",
        )
        val scale = size * 0.5f / 24f
        canvas.save()
        canvas.translate(size * 0.25f, size * 0.25f)
        canvas.scale(scale, scale)
        canvas.drawPath(
            note,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = foreground(context)
                alpha = 150
            },
        )
        canvas.restore()
        return output
    }

    private fun progressBitmap(context: Context, fraction: Float): Bitmap {
        val width = 400
        val height = 8
        val output = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.color = ColorUtils.setAlphaComponent(foreground(context), 51)
        canvas.drawRoundRect(RectF(0f, 0f, width.toFloat(), height.toFloat()), 4f, 4f, paint)
        if (fraction > 0f) {
            paint.color = foreground(context)
            val end = maxOf(height.toFloat(), width * fraction)
            canvas.drawRoundRect(RectF(0f, 0f, end, height.toFloat()), 4f, 4f, paint)
        }
        return output
    }

    private fun styleBase(context: Context, views: RemoteViews, bg: Int, vararg texts: Int) {
        views.setInt(bg, "setColorFilter", card(context))
        for ((index, id) in texts.withIndex()) {
            val color = foreground(context)
            views.setTextColor(id, if (index == 0) color else ColorUtils.setAlphaComponent(color, 190))
        }
    }

    private fun action(context: Context, name: String, code: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            code,
            Intent(context, PlayerActionReceiver::class.java).setAction(name),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

    private fun playIcon(): Int = if (WidgetState.playing) R.drawable.ic_pip_pause else R.drawable.ic_pip_play

    private fun repeatIcon(): Int = when (WidgetState.repeat) {
        2 -> R.drawable.ic_media_repeat_one
        1 -> R.drawable.ic_media_repeat_on
        else -> R.drawable.ic_media_repeat
    }

    private fun shuffleIcon(): Int =
        if (WidgetState.shuffle) R.drawable.ic_media_shuffle_on else R.drawable.ic_media_shuffle

    private fun titleText(context: Context): String =
        if (WidgetState.active && WidgetState.title.isNotEmpty()) {
            WidgetState.title
        } else {
            context.getString(R.string.app_name)
        }

    private fun subText(context: Context): String = when {
        !WidgetState.active -> context.getString(R.string.widget_idle)
        WidgetState.artist.isNotEmpty() -> WidgetState.artist
        WidgetState.album.isNotEmpty() -> WidgetState.album
        else -> context.getString(if (WidgetState.playing) R.string.playback_playing else R.string.playback_paused)
    }

    private fun setArt(context: Context, views: RemoteViews, id: Int) {
        val art = WidgetState.art
        val bitmap = if (WidgetState.active && art != null) {
            roundedArt(art, artBackground(context))
        } else {
            placeholder(context)
        }
        views.setImageViewBitmap(id, bitmap)
    }

    private fun tint(views: RemoteViews, id: Int, color: Int) {
        views.setInt(id, "setColorFilter", color)
    }

    private fun playButton(context: Context, views: RemoteViews, disc: Int, icon: Int) {
        views.setImageViewBitmap(disc, circle(accent(context)))
        views.setImageViewResource(icon, playIcon())
        tint(views, icon, onAccent(context))
        views.setOnClickPendingIntent(icon, action(context, WindowChannel.ACTION_TOGGLE, 21))
        views.setOnClickPendingIntent(disc, action(context, WindowChannel.ACTION_TOGGLE, 21))
    }

    private fun control(context: Context, views: RemoteViews, id: Int, icon: Int, name: String, code: Int) {
        views.setImageViewResource(id, icon)
        tint(views, id, foreground(context))
        views.setOnClickPendingIntent(id, action(context, name, code))
    }

    private fun progress(context: Context, views: RemoteViews, id: Int) {
        val total = WidgetState.durationMs
        val fraction = if (total > 0) (WidgetState.positionMs.toFloat() / total).coerceIn(0f, 1f) else 0f
        views.setImageViewBitmap(id, progressBitmap(context, fraction))
    }

    private fun square(context: Context): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_square)
        setArt(context, views, R.id.square_art)
        views.setTextViewText(R.id.square_title, titleText(context))
        views.setTextViewText(R.id.square_sub, subText(context))
        styleBase(context, views, R.id.square_bg, R.id.square_title, R.id.square_sub)
        playButton(context, views, R.id.square_disc, R.id.square_play)
        views.setOnClickPendingIntent(R.id.square_root, NotificationHelper.openPlayer(context))
        views.setOnClickPendingIntent(R.id.square_art, NotificationHelper.openPlayer(context))
        return views
    }

    private fun bar(context: Context): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_bar)
        setArt(context, views, R.id.bar_art)
        views.setTextViewText(R.id.bar_title, titleText(context))
        views.setTextViewText(R.id.bar_sub, subText(context))
        styleBase(context, views, R.id.bar_bg, R.id.bar_title, R.id.bar_sub)
        playButton(context, views, R.id.bar_disc, R.id.bar_play)
        control(context, views, R.id.bar_next, R.drawable.ic_media_next, WindowChannel.ACTION_NEXT, 22)
        views.setOnClickPendingIntent(R.id.bar_root, NotificationHelper.openPlayer(context))
        return views
    }

    private fun wide(context: Context): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_wide)
        setArt(context, views, R.id.wide_art)
        views.setTextViewText(R.id.wide_title, titleText(context))
        views.setTextViewText(R.id.wide_sub, subText(context))
        styleBase(context, views, R.id.wide_bg, R.id.wide_title, R.id.wide_sub)
        progress(context, views, R.id.wide_progress)
        playButton(context, views, R.id.wide_disc, R.id.wide_play)
        control(context, views, R.id.wide_previous, R.drawable.ic_media_previous, WindowChannel.ACTION_PREVIOUS, 23)
        control(context, views, R.id.wide_next, R.drawable.ic_media_next, WindowChannel.ACTION_NEXT, 22)
        control(context, views, R.id.wide_shuffle, shuffleIcon(), WindowChannel.ACTION_SHUFFLE, 24)
        control(context, views, R.id.wide_repeat, repeatIcon(), WindowChannel.ACTION_REPEAT, 25)
        views.setOnClickPendingIntent(R.id.wide_root, NotificationHelper.openPlayer(context))
        return views
    }

    private fun button(context: Context): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_button)
        styleBase(context, views, R.id.button_bg)
        playButton(context, views, R.id.button_disc, R.id.button_play)
        views.setOnClickPendingIntent(R.id.button_root, NotificationHelper.openPlayer(context))
        return views
    }
}

open class PlayerWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        PlayerWidgets.update(context)
    }

    override fun onEnabled(context: Context) {
        PlayerWidgets.update(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == Intent.ACTION_CONFIGURATION_CHANGED) PlayerWidgets.update(context)
    }
}

class WidgetSquare : PlayerWidgetProvider()

class WidgetBar : PlayerWidgetProvider()

class WidgetWide : PlayerWidgetProvider()

class WidgetButton : PlayerWidgetProvider()
