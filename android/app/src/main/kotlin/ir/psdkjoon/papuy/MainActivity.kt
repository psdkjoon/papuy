package ir.psdkjoon.papuy

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return EngineHolder.ensure(context)
    }

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        Hosts.claim(this)
        super.onCreate(savedInstanceState)
        EngineHolder.activity = this
        if (savedInstanceState == null) {
            if (EngineHolder.takeFirstLaunch()) {
                MediaChannel.setLaunch(intent)
            } else {
                WindowChannel.sendCommand("home")
                MediaChannel.deliver(intent)
            }
            announceHandoff(intent)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        MediaChannel.deliver(intent)
        announceHandoff(intent)
    }

    private fun announceHandoff(intent: Intent?) {
        if (intent?.getBooleanExtra(EXTRA_HANDOFF, false) == true) {
            intent.removeExtra(EXTRA_HANDOFF)
            WindowChannel.sendCommand("handoff")
        }
    }

    companion object {
        const val EXTRA_HANDOFF = "ir.psdkjoon.papuy.HANDOFF"
    }

    override fun onPostResume() {
        super.onPostResume()
        EngineHolder.activity = this
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        WindowChannel.onUserLeaveHint()
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration,
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        WindowChannel.notifyPip(isInPictureInPictureMode)
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        MediaChannel.onActivityResult(requestCode, resultCode, data)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == MediaChannel.REQUEST_PERMISSION) {
            MediaChannel.onPermissionResult(
                grantResults.isNotEmpty() &&
                    grantResults.all { it == PackageManager.PERMISSION_GRANTED },
            )
        }
    }

    override fun onDestroy() {
        if (EngineHolder.activity === this) EngineHolder.activity = null
        super.onDestroy()
    }
}
