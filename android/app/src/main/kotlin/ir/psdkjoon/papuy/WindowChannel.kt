package ir.psdkjoon.papuy

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.media.AudioManager
import android.os.Build
import android.provider.Settings
import android.util.Rational
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt

object WindowChannel {
    private const val CHANNEL = "papuy/window"
    private const val MIN_RATIO = 1.0 / 2.39
    private const val MAX_RATIO = 2.39

    const val ACTION_TOGGLE = "ir.psdkjoon.papuy.TOGGLE_PLAYBACK"
    const val ACTION_NEXT = "ir.psdkjoon.papuy.NEXT_TRACK"
    const val ACTION_PREVIOUS = "ir.psdkjoon.papuy.PREVIOUS_TRACK"
    const val ACTION_SHUFFLE = "ir.psdkjoon.papuy.SHUFFLE_TRACKS"
    const val ACTION_REPEAT = "ir.psdkjoon.papuy.REPEAT_TRACKS"

    private lateinit var appContext: Context
    private lateinit var channel: MethodChannel

    private var pipWidth = 16
    private var pipHeight = 9
    private var pipButtons = true
    private var autoPip = false
    private var inPip = false

    @Volatile
    private var dartReady = false

    @Volatile
    private var pendingCommand: String? = null

    fun register(engine: FlutterEngine, context: Context) {
        appContext = context.applicationContext
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result -> handle(call, result) }
        PlayerChannel.onPlayingChanged = {
            refreshPip()
            PlaybackService.refresh(appContext)
        }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "ready" -> {
                dartReady = true
                val waiting = pendingCommand
                pendingCommand = null
                result.success(waiting)
            }
            "getBrightness" -> result.success(brightness())
            "setBrightness" -> {
                setBrightness((call.argument<Number>("value") ?: -1).toFloat())
                result.success(null)
            }
            "getVolume" -> result.success(volume())
            "setVolume" -> {
                setVolume((call.argument<Number>("value") ?: 0.5).toFloat())
                result.success(null)
            }
            "keepAwake" -> {
                keepAwake(call.argument<Boolean>("on") == true)
                result.success(null)
            }
            "enterPip" -> {
                readPip(call)
                enterPip()
                result.success(null)
            }
            "setAutoPip" -> {
                readPip(call)
                autoPip = call.argument<Boolean>("on") == true
                applyPipParams()
                result.success(null)
            }
            "setBackground" -> {
                if (call.argument<Boolean>("on") == true) {
                    PlaybackService.start(
                        appContext,
                        PlaybackService.Update(
                            title = call.argument<String>("title") ?: "",
                            music = call.argument<Boolean>("music") == true,
                            artist = call.argument<String>("artist") ?: "",
                            album = call.argument<String>("album") ?: "",
                            durationMs = (call.argument<Number>("durationMs") ?: 0).toLong(),
                            positionMs = (call.argument<Number>("positionMs") ?: 0).toLong(),
                            shuffle = call.argument<Boolean>("shuffle") == true,
                            repeat = (call.argument<Number>("repeat") ?: 0).toInt(),
                            speed = (call.argument<Number>("speed") ?: 1.0).toFloat(),
                            artChanged = call.argument<Boolean>("artChanged") == true,
                            art = call.argument<ByteArray>("art"),
                        ),
                    )
                } else {
                    PlaybackService.stop(appContext)
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun brightness(): Double {
        val host = EngineHolder.activity ?: return 0.5
        val current = host.window.attributes.screenBrightness
        if (current >= 0f) return current.toDouble()
        return try {
            Settings.System.getInt(appContext.contentResolver, Settings.System.SCREEN_BRIGHTNESS) / 255.0
        } catch (_: Settings.SettingNotFoundException) {
            0.5
        }
    }

    private fun setBrightness(value: Float) {
        val host = EngineHolder.activity ?: return
        val attributes = host.window.attributes
        attributes.screenBrightness = if (value < 0f) {
            WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
        } else {
            value.coerceIn(0.01f, 1f)
        }
        host.window.attributes = attributes
    }

    private fun audio(): AudioManager {
        return appContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    private fun volume(): Double {
        val manager = audio()
        val max = manager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        if (max <= 0) return 0.5
        return manager.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble() / max
    }

    private fun setVolume(value: Float) {
        val manager = audio()
        val max = manager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        manager.setStreamVolume(AudioManager.STREAM_MUSIC, (value * max).roundToInt().coerceIn(0, max), 0)
    }

    private fun keepAwake(on: Boolean) {
        val host = EngineHolder.activity ?: return
        if (on) {
            host.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            host.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    private fun readPip(call: MethodCall) {
        pipWidth = (call.argument<Number>("width") ?: 16).toInt().coerceAtLeast(1)
        pipHeight = (call.argument<Number>("height") ?: 9).toInt().coerceAtLeast(1)
        pipButtons = call.argument<Boolean>("buttons") != false
    }

    private fun pipParams(): PictureInPictureParams? {
        if (Build.VERSION.SDK_INT < 26) return null
        val ratio = (pipWidth.toDouble() / pipHeight).coerceIn(MIN_RATIO, MAX_RATIO)
        val builder = PictureInPictureParams.Builder()
            .setAspectRatio(Rational((ratio * 1000).roundToInt(), 1000))
            .setActions(if (pipButtons) listOf(toggleAction()) else emptyList())
        if (Build.VERSION.SDK_INT >= 31) builder.setAutoEnterEnabled(autoPip)
        return builder.build()
    }

    private fun toggleAction(): RemoteAction {
        val playing = PlayerChannel.isPlaying()
        val title = if (playing) "Pause" else "Play"
        val icon = Icon.createWithResource(
            appContext,
            if (playing) R.drawable.ic_pip_pause else R.drawable.ic_pip_play,
        )
        val intent = PendingIntent.getBroadcast(
            appContext,
            1,
            Intent(appContext, PlayerActionReceiver::class.java).setAction(ACTION_TOGGLE),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return RemoteAction(icon, title, title, intent)
    }

    private fun applyPipParams() {
        val host = EngineHolder.activity ?: return
        val params = pipParams() ?: return
        host.setPictureInPictureParams(params)
    }

    private fun enterPip() {
        val host = EngineHolder.activity ?: return
        val params = pipParams() ?: return
        host.enterPictureInPictureMode(params)
    }

    fun refreshPip() {
        if (inPip) applyPipParams()
    }

    fun onUserLeaveHint() {
        if (autoPip && Build.VERSION.SDK_INT in 26..30) enterPip()
    }

    fun requestCommand(context: Context, name: String) {
        EngineHolder.ensure(context)
        if (dartReady) {
            android.os.Handler(android.os.Looper.getMainLooper()).post { sendCommand(name) }
        } else {
            pendingCommand = name
        }
    }

    fun sendCommand(name: String) {
        if (!::channel.isInitialized) return
        channel.invokeMethod("command", name)
    }

    fun notifyPip(active: Boolean) {
        inPip = active
        if (!::channel.isInitialized) return
        channel.invokeMethod("pip", active)
    }
}
