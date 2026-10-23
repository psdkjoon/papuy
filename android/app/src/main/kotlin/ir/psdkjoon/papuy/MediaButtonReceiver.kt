package ir.psdkjoon.papuy

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent

class MediaButtonReceiver : BroadcastReceiver() {
    @Suppress("DEPRECATION")
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_MEDIA_BUTTON) return
        val event = if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(Intent.EXTRA_KEY_EVENT, KeyEvent::class.java)
        } else {
            intent.getParcelableExtra<KeyEvent>(Intent.EXTRA_KEY_EVENT)
        } ?: return
        if (event.action != KeyEvent.ACTION_DOWN) return
        val app = context.applicationContext
        val pending = goAsync()
        Handler(Looper.getMainLooper()).postDelayed({ pending.finish() }, WAIT_MS)
        when (event.keyCode) {
            KeyEvent.KEYCODE_MEDIA_PLAY,
            KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE,
            KeyEvent.KEYCODE_HEADSETHOOK,
            -> PlaybackService.resumeFromButton(app)
            KeyEvent.KEYCODE_MEDIA_NEXT -> WindowChannel.requestCommand(app, "next")
            KeyEvent.KEYCODE_MEDIA_PREVIOUS -> WindowChannel.requestCommand(app, "previous")
        }
    }

    private companion object {
        const val WAIT_MS = 8000L
    }
}
