package ir.psdkjoon.papuy

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class PlayerActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            WindowChannel.ACTION_TOGGLE -> {
                if (PlayerChannel.hasPlayer()) {
                    PlayerChannel.toggle()
                    WindowChannel.refreshPip()
                    PlaybackService.refresh(context)
                } else {
                    WindowChannel.requestCommand(context, "play")
                }
            }
            WindowChannel.ACTION_NEXT -> WindowChannel.sendCommand("next")
            WindowChannel.ACTION_PREVIOUS -> WindowChannel.sendCommand("previous")
            WindowChannel.ACTION_SHUFFLE -> WindowChannel.sendCommand("shuffle")
            WindowChannel.ACTION_REPEAT -> WindowChannel.sendCommand("repeat")
        }
    }
}
