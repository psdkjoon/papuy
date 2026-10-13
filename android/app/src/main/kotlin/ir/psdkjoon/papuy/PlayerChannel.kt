package ir.psdkjoon.papuy

import android.content.Context
import android.net.Uri
import android.view.Surface
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.common.VideoSize
import androidx.media3.common.text.CueGroup
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.audio.DefaultAudioSink
import androidx.media3.exoplayer.SeekParameters
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry
import java.util.Locale

object PlayerChannel {
    private const val CHANNEL = "papuy/player"
    private const val BOOST_GAIN_MB = 1500

    private lateinit var appContext: Context
    private lateinit var textures: TextureRegistry
    private lateinit var channel: MethodChannel

    private var player: ExoPlayer? = null
    private var entry: TextureRegistry.SurfaceTextureEntry? = null
    private var surface: Surface? = null
    private var enhancer: android.media.audiofx.LoudnessEnhancer? = null
    private var held: android.os.ParcelFileDescriptor? = null
    private var boost = false
    private var pendingOpen: MethodChannel.Result? = null

    var onPlayingChanged: (() -> Unit)? = null

    fun register(engine: FlutterEngine, context: Context) {
        appContext = context.applicationContext
        textures = engine.renderer
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result -> handle(call, result) }
    }

    fun isPlaying(): Boolean {
        val exo = player ?: return false
        return exo.playWhenReady && exo.playbackState != Player.STATE_ENDED
    }

    fun toggle() {
        val exo = player ?: return
        if (isPlaying()) {
            exo.pause()
        } else {
            if (exo.playbackState == Player.STATE_ENDED) exo.seekTo(0)
            exo.play()
        }
    }

    fun pause() {
        player?.pause()
    }

    fun resume() {
        val exo = player ?: return
        if (exo.playbackState == Player.STATE_ENDED) exo.seekTo(0)
        exo.play()
    }

    fun seekTo(ms: Long) {
        player?.seekTo(ms)
    }

    fun hasPlayer(): Boolean = player != null

    fun position(): Long = player?.currentPosition ?: 0L

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "open" -> open(call, result)
            "play" -> {
                player?.play()
                result.success(null)
            }
            "pause" -> {
                player?.pause()
                result.success(null)
            }
            "seek" -> {
                player?.seekTo((call.argument<Number>("ms") ?: 0).toLong())
                result.success(null)
            }
            "speed" -> {
                player?.setPlaybackSpeed((call.argument<Number>("value") ?: 1.0).toFloat())
                result.success(null)
            }
            "mute" -> {
                player?.volume = if (call.argument<Boolean>("on") == true) 0f else 1f
                result.success(null)
            }
            "selectTrack" -> {
                selectTrack(
                    call.argument<String>("type") ?: "",
                    (call.argument<Number>("group") ?: -1).toInt(),
                    (call.argument<Number>("index") ?: -1).toInt(),
                )
                result.success(null)
            }
            "state" -> result.success(state())
            "bands" -> result.success(Spectrum.bars)
            "close" -> {
                release()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    @androidx.annotation.OptIn(UnstableApi::class)
    private fun open(call: MethodCall, result: MethodChannel.Result) {
        release()
        val uriText = call.argument<String>("uri")
        if (uriText == null) {
            result.error("bad_uri", "No video address.", null)
            return
        }
        val startMs = (call.argument<Number>("startMs") ?: 0).toLong()
        val speed = (call.argument<Number>("speed") ?: 1.0).toFloat()
        val audioLang = call.argument<String>("audioLang") ?: "auto"
        val subtitleLang = call.argument<String>("subtitleLang") ?: "auto"
        boost = call.argument<Boolean>("boost") == true
        val audioOnly = call.argument<Boolean>("audio") == true

        Spectrum.clear()
        val factory = object : DefaultRenderersFactory(appContext) {
            override fun buildAudioSink(
                context: Context,
                enableFloatOutput: Boolean,
                enableAudioTrackPlaybackParams: Boolean,
            ): AudioSink {
                val builder = DefaultAudioSink.Builder(context)
                    .setEnableFloatOutput(enableFloatOutput)
                    .setEnableAudioTrackPlaybackParams(enableAudioTrackPlaybackParams)
                if (audioOnly) {
                    builder.setAudioProcessors(arrayOf<AudioProcessor>(SpectrumProcessor()))
                }
                return builder.build()
            }
        }
        val heldFactory = holdExternal(Uri.parse(uriText))
        val builder = ExoPlayer.Builder(appContext, factory)
        if (heldFactory != null) {
            builder.setMediaSourceFactory(
                androidx.media3.exoplayer.source.DefaultMediaSourceFactory(appContext)
                    .setDataSourceFactory(heldFactory),
            )
        }
        val exo = builder
            .setHandleAudioBecomingNoisy(call.argument<Boolean>("pauseNoisy") != false)
            .build()
        exo.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(C.USAGE_MEDIA)
                .setContentType(if (audioOnly) C.AUDIO_CONTENT_TYPE_MUSIC else C.AUDIO_CONTENT_TYPE_MOVIE)
                .build(),
            true,
        )
        exo.setWakeMode(
            if (uriText.startsWith("http")) C.WAKE_MODE_NETWORK else C.WAKE_MODE_LOCAL,
        )
        exo.setSeekParameters(
            if (call.argument<Boolean>("exactSeek") == true) {
                SeekParameters.EXACT
            } else {
                SeekParameters.CLOSEST_SYNC
            },
        )
        exo.skipSilenceEnabled = call.argument<Boolean>("skipSilence") == true

        val selection = exo.trackSelectionParameters.buildUpon()
        if (audioLang != "auto") selection.setPreferredAudioLanguage(audioLang)
        when (subtitleLang) {
            "auto" -> Unit
            "off" -> selection.setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
            else -> selection.setPreferredTextLanguage(subtitleLang)
        }
        if (audioOnly) {
            selection.setTrackTypeDisabled(C.TRACK_TYPE_VIDEO, true)
            selection.setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
        }
        exo.trackSelectionParameters = selection.build()

        if (!audioOnly) {
            val created = textures.createSurfaceTexture()
            val target = Surface(created.surfaceTexture())
            entry = created
            surface = target
            exo.setVideoSurface(target)
        }
        exo.setPlaybackSpeed(speed)
        exo.setMediaItem(MediaItem.fromUri(Uri.parse(uriText)), startMs)
        exo.playWhenReady = call.argument<Boolean>("play") != false
        exo.addListener(listener)
        player = exo
        pendingOpen = result
        exo.prepare()
    }

    private val listener = object : Player.Listener {
        override fun onPlaybackStateChanged(state: Int) {
            when (state) {
                Player.STATE_READY -> finishOpen()
                Player.STATE_ENDED -> channel.invokeMethod("completed", null)
                else -> Unit
            }
            onPlayingChanged?.invoke()
        }

        override fun onPlayWhenReadyChanged(playWhenReady: Boolean, reason: Int) {
            onPlayingChanged?.invoke()
        }

        override fun onVideoSizeChanged(videoSize: VideoSize) {
            if (pendingOpen != null) return
            channel.invokeMethod("size", sizeMap(videoSize))
        }

        override fun onTracksChanged(tracks: Tracks) {
            if (pendingOpen != null) return
            channel.invokeMethod("tracks", trackList())
        }

        override fun onCues(cueGroup: CueGroup) {
            val text = cueGroup.cues.mapNotNull { it.text?.toString() }.joinToString("\n")
            channel.invokeMethod("cue", text)
        }

        override fun onAudioSessionIdChanged(audioSessionId: Int) {
            setUpBoost(audioSessionId)
        }

        override fun onPlayerError(error: PlaybackException) {
            val waiting = pendingOpen
            if (waiting != null) {
                pendingOpen = null
                waiting.error("open_failed", error.errorCodeName, null)
            } else {
                channel.invokeMethod("error", error.errorCodeName)
            }
        }
    }

    private fun finishOpen() {
        val waiting = pendingOpen ?: return
        val exo = player ?: return
        pendingOpen = null
        val data = HashMap<String, Any?>(sizeMap(exo.videoSize))
        data["texture"] = entry?.id() ?: 0L
        data["durationMs"] = durationMs()
        data["tracks"] = trackList()
        waiting.success(data)
    }

    private fun sizeMap(size: VideoSize): Map<String, Any> = mapOf(
        "width" to size.width,
        "height" to size.height,
        "ratio" to size.pixelWidthHeightRatio.toDouble(),
        "rotation" to size.unappliedRotationDegrees,
    )

    private fun durationMs(): Long {
        val duration = player?.duration ?: return 0L
        return if (duration == C.TIME_UNSET || duration < 0) 0L else duration
    }

    private fun state(): Map<String, Any>? {
        val exo = player ?: return null
        return mapOf(
            "pos" to exo.currentPosition,
            "playing" to isPlaying(),
            "buffering" to (exo.playbackState == Player.STATE_BUFFERING),
            "durationMs" to durationMs(),
        )
    }

    private fun setUpBoost(sessionId: Int) {
        enhancer?.release()
        enhancer = null
        if (!boost || sessionId == C.AUDIO_SESSION_ID_UNSET) return
        try {
            val created = android.media.audiofx.LoudnessEnhancer(sessionId)
            created.setTargetGain(BOOST_GAIN_MB)
            created.enabled = true
            enhancer = created
        } catch (_: RuntimeException) {
            enhancer = null
        }
    }

    private fun trackList(): List<Map<String, Any>> {
        val exo = player ?: return emptyList()
        val out = ArrayList<Map<String, Any>>()
        exo.currentTracks.groups.forEachIndexed { groupIndex, group ->
            val type = when (group.type) {
                C.TRACK_TYPE_AUDIO -> "audio"
                C.TRACK_TYPE_TEXT -> "text"
                C.TRACK_TYPE_VIDEO -> "video"
                else -> return@forEachIndexed
            }
            for (trackIndex in 0 until group.length) {
                if (!group.isTrackSupported(trackIndex)) continue
                out.add(
                    mapOf(
                        "type" to type,
                        "group" to groupIndex,
                        "index" to trackIndex,
                        "label" to label(type, group.getTrackFormat(trackIndex), trackIndex),
                        "selected" to group.isTrackSelected(trackIndex),
                    ),
                )
            }
        }
        return out
    }

    private fun label(type: String, format: Format, index: Int): String {
        if (type == "video") {
            val rate = if (format.bitrate > 0) " · %.1f Mbps".format(format.bitrate / 1_000_000.0) else ""
            return if (format.height > 0) "${format.height}p$rate" else "Track ${index + 1}"
        }
        val language = format.language
            ?.takeIf { it != C.LANGUAGE_UNDETERMINED }
            ?.let { Locale.forLanguageTag(it).getDisplayLanguage(Locale.ENGLISH) }
            ?.takeIf { it.isNotEmpty() }
        val name = format.label ?: language ?: "Track ${index + 1}"
        return if (type == "audio" && format.channelCount > 2) {
            "$name · ${format.channelCount}ch"
        } else {
            name
        }
    }

    private fun selectTrack(type: String, group: Int, index: Int) {
        val exo = player ?: return
        val trackType = when (type) {
            "audio" -> C.TRACK_TYPE_AUDIO
            "text" -> C.TRACK_TYPE_TEXT
            "video" -> C.TRACK_TYPE_VIDEO
            else -> return
        }
        val builder = exo.trackSelectionParameters.buildUpon()
        if (group < 0) {
            if (trackType == C.TRACK_TYPE_TEXT) {
                builder.setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
            } else {
                builder.clearOverridesOfType(trackType)
            }
        } else {
            val target = exo.currentTracks.groups.getOrNull(group) ?: return
            builder.setTrackTypeDisabled(trackType, false)
            builder.setOverrideForType(TrackSelectionOverride(target.mediaTrackGroup, index))
        }
        exo.trackSelectionParameters = builder.build()
    }

    @androidx.annotation.OptIn(UnstableApi::class)
    private fun holdExternal(uri: Uri): HeldFileDataSource.Factory? {
        if (uri.scheme != "content" || uri.authority == "media") return null
        return try {
            val descriptor = appContext.contentResolver.openFileDescriptor(uri, "r") ?: return null
            if (descriptor.statSize < 0) {
                descriptor.close()
                return null
            }
            held = descriptor
            HeldFileDataSource.Factory(descriptor)
        } catch (_: Exception) {
            null
        }
    }

    private fun release() {
        pendingOpen?.error("open_failed", "Closed.", null)
        pendingOpen = null
        enhancer?.release()
        enhancer = null
        player?.removeListener(listener)
        player?.release()
        player = null
        try {
            held?.close()
        } catch (_: Exception) {
        }
        held = null
        Spectrum.clear()
        surface?.release()
        surface = null
        entry?.release()
        entry = null
        onPlayingChanged?.invoke()
    }
}
