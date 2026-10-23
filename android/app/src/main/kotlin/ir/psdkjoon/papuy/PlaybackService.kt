package ir.psdkjoon.papuy

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadata
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.Bundle
import android.os.IBinder

class PlaybackService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        try {
            val notification = build(this)
            if (Build.VERSION.SDK_INT >= 29) {
                startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (_: RuntimeException) {
            running = false
            stopSelf()
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        running = false
        WidgetState.clear(applicationContext)
        releaseSession()
        if (Build.VERSION.SDK_INT >= 24) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        super.onDestroy()
    }

    class Update(
        val title: String,
        val music: Boolean,
        val artist: String,
        val album: String,
        val durationMs: Long,
        val positionMs: Long,
        val shuffle: Boolean,
        val repeat: Int,
        val speed: Float,
        val artChanged: Boolean,
        val art: ByteArray?,
    )

    companion object {
        private const val CHANNEL = "playback"
        private const val NOTIFICATION_ID = 200
        private const val ACTION_STOP = "ir.psdkjoon.papuy.STOP_PLAYBACK_SERVICE"
        private const val CUSTOM_SHUFFLE = "shuffle"
        private const val CUSTOM_REPEAT = "repeat"

        @Volatile
        private var running = false

        @Volatile
        private var info = Update("", false, "", "", 0L, 0L, false, 0, 1f, false, null)

        @Volatile
        private var art: Bitmap? = null

        private var session: MediaSession? = null

        fun start(context: Context, update: Update) {
            info = update
            if (update.artChanged) {
                art = update.art?.let { BitmapFactory.decodeByteArray(it, 0, it.size) }
            }
            WidgetState.set(
                context,
                info.title,
                info.artist,
                info.album,
                PlayerChannel.isPlaying(),
                info.shuffle,
                info.repeat,
                info.durationMs,
                if (PlayerChannel.hasPlayer()) PlayerChannel.position() else info.positionMs,
                art,
                update.artChanged,
            )
            if (running) {
                refresh(context)
                return
            }
            val intent = Intent(context, PlaybackService::class.java)
            try {
                if (Build.VERSION.SDK_INT >= 26) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                running = true
            } catch (_: RuntimeException) {
                running = false
            }
        }

        fun stop(context: Context) {
            if (!running) return
            running = false
            WidgetState.clear(context)
            context.stopService(Intent(context, PlaybackService::class.java))
        }

        fun refresh(context: Context) {
            if (!running) return
            val manager = context.getSystemService(NotificationManager::class.java) ?: return
            manager.notify(NOTIFICATION_ID, build(context))
            WidgetState.set(
                context,
                info.title,
                info.artist,
                info.album,
                PlayerChannel.isPlaying(),
                info.shuffle,
                info.repeat,
                info.durationMs,
                if (PlayerChannel.hasPlayer()) PlayerChannel.position() else info.positionMs,
                null,
                false,
            )
        }

        fun resumeFromButton(context: Context) {
            if (PlayerChannel.hasPlayer()) {
                PlayerChannel.resume()
                refresh(context)
            } else {
                WindowChannel.requestCommand(context, "play")
            }
        }

        private fun releaseSession() {
            session?.isActive = false
            session?.release()
            session = null
        }

        private fun ensureSession(context: Context): MediaSession {
            session?.let { return it }
            val created = MediaSession(context.applicationContext, "papuy")
            @Suppress("DEPRECATION")
            created.setFlags(
                MediaSession.FLAG_HANDLES_MEDIA_BUTTONS or MediaSession.FLAG_HANDLES_TRANSPORT_CONTROLS,
            )
            created.setCallback(
                object : MediaSession.Callback() {
                    override fun onPlay() {
                        resumeFromButton(context.applicationContext)
                    }

                    override fun onPause() {
                        PlayerChannel.pause()
                    }

                    override fun onSkipToNext() {
                        WindowChannel.sendCommand("next")
                    }

                    override fun onSkipToPrevious() {
                        WindowChannel.sendCommand("previous")
                    }

                    override fun onSeekTo(pos: Long) {
                        PlayerChannel.seekTo(pos)
                        refresh(context.applicationContext)
                    }

                    override fun onStop() {
                        WindowChannel.sendCommand("stop")
                    }

                    override fun onCustomAction(action: String, extras: Bundle?) {
                        if (action == CUSTOM_SHUFFLE || action == CUSTOM_REPEAT) {
                            WindowChannel.sendCommand(action)
                        }
                    }
                },
            )
            created.setMediaButtonReceiver(
                PendingIntent.getBroadcast(
                    context.applicationContext,
                    7,
                    Intent(Intent.ACTION_MEDIA_BUTTON)
                        .setComponent(ComponentName(context.applicationContext, MediaButtonReceiver::class.java)),
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                ),
            )
            created.isActive = true
            session = created
            return created
        }

        private fun updateSession(context: Context, playing: Boolean, position: Long): MediaSession {
            val current = ensureSession(context)
            val data = info
            val metadata = MediaMetadata.Builder()
                .putString(MediaMetadata.METADATA_KEY_TITLE, data.title)
                .putString(MediaMetadata.METADATA_KEY_ARTIST, data.artist)
                .putString(MediaMetadata.METADATA_KEY_ALBUM, data.album)
                .putLong(MediaMetadata.METADATA_KEY_DURATION, data.durationMs)
            art?.let { metadata.putBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART, it) }
            current.setMetadata(metadata.build())
            val actions = PlaybackState.ACTION_PLAY or
                PlaybackState.ACTION_PAUSE or
                PlaybackState.ACTION_PLAY_PAUSE or
                PlaybackState.ACTION_STOP or
                PlaybackState.ACTION_SKIP_TO_NEXT or
                PlaybackState.ACTION_SKIP_TO_PREVIOUS or
                PlaybackState.ACTION_SEEK_TO
            val state = PlaybackState.Builder()
                .setActions(actions)
                .setState(
                    if (playing) PlaybackState.STATE_PLAYING else PlaybackState.STATE_PAUSED,
                    position,
                    if (playing) data.speed else 0f,
                )
            state.addCustomAction(
                PlaybackState.CustomAction.Builder(
                    CUSTOM_SHUFFLE,
                    context.getString(R.string.playback_shuffle),
                    if (data.shuffle) R.drawable.ic_media_shuffle_on else R.drawable.ic_media_shuffle,
                ).build(),
            )
            state.addCustomAction(
                PlaybackState.CustomAction.Builder(
                    CUSTOM_REPEAT,
                    context.getString(R.string.playback_repeat),
                    when (data.repeat) {
                        2 -> R.drawable.ic_media_repeat_one
                        1 -> R.drawable.ic_media_repeat_on
                        else -> R.drawable.ic_media_repeat
                    },
                ).build(),
            )
            current.setPlaybackState(state.build())
            return current
        }

        @Suppress("DEPRECATION")
        private fun build(context: Context): Notification {
            val manager = context.getSystemService(NotificationManager::class.java)
            if (Build.VERSION.SDK_INT >= 26) {
                manager?.createNotificationChannel(
                    NotificationChannel(
                        CHANNEL,
                        context.getString(R.string.playback_channel),
                        NotificationManager.IMPORTANCE_LOW,
                    ),
                )
            }
            val data = info
            val open = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            fun intent(code: Int, name: String): PendingIntent = PendingIntent.getBroadcast(
                context,
                code,
                Intent(context, PlayerActionReceiver::class.java).setAction(name),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            fun action(icon: Int, label: Int, pending: PendingIntent) = Notification.Action.Builder(
                icon,
                context.getString(label),
                pending,
            ).build()

            val playing = PlayerChannel.isPlaying()
            val position = if (PlayerChannel.hasPlayer()) PlayerChannel.position() else data.positionMs
            val builder = if (Build.VERSION.SDK_INT >= 26) {
                Notification.Builder(context, CHANNEL)
            } else {
                Notification.Builder(context)
            }
            builder
                .setSmallIcon(R.drawable.ic_tile)
                .setContentTitle(data.title.ifEmpty { context.getString(R.string.app_name) })
                .setContentIntent(open)
                .setOngoing(true)
                .setShowWhen(false)
            if (data.music) {
                builder.setContentText(data.artist.ifEmpty { context.getString(if (playing) R.string.playback_playing else R.string.playback_paused) })
                if (data.album.isNotEmpty()) builder.setSubText(data.album)
                art?.let { builder.setLargeIcon(it) }
                builder.addAction(
                    action(
                        if (data.shuffle) R.drawable.ic_media_shuffle_on else R.drawable.ic_media_shuffle,
                        R.string.playback_shuffle,
                        intent(5, WindowChannel.ACTION_SHUFFLE),
                    ),
                )
                builder.addAction(
                    action(R.drawable.ic_media_previous, R.string.playback_previous, intent(3, WindowChannel.ACTION_PREVIOUS)),
                )
                builder.addAction(
                    action(
                        if (playing) R.drawable.ic_pip_pause else R.drawable.ic_pip_play,
                        if (playing) R.string.playback_pause else R.string.playback_play,
                        intent(2, WindowChannel.ACTION_TOGGLE),
                    ),
                )
                builder.addAction(
                    action(R.drawable.ic_media_next, R.string.playback_next, intent(4, WindowChannel.ACTION_NEXT)),
                )
                builder.addAction(
                    action(
                        when (data.repeat) {
                            2 -> R.drawable.ic_media_repeat_one
                            1 -> R.drawable.ic_media_repeat_on
                            else -> R.drawable.ic_media_repeat
                        },
                        R.string.playback_repeat,
                        intent(6, WindowChannel.ACTION_REPEAT),
                    ),
                )
                val current = updateSession(context, playing, position)
                builder.setStyle(
                    Notification.MediaStyle()
                        .setMediaSession(current.sessionToken)
                        .setShowActionsInCompactView(1, 2, 3),
                )
            } else {
                builder.setContentText(
                    context.getString(if (playing) R.string.playback_playing else R.string.playback_paused),
                )
                builder.addAction(
                    action(
                        if (playing) R.drawable.ic_pip_pause else R.drawable.ic_pip_play,
                        if (playing) R.string.playback_pause else R.string.playback_play,
                        intent(2, WindowChannel.ACTION_TOGGLE),
                    ),
                )
            }
            return builder.build()
        }
    }
}
