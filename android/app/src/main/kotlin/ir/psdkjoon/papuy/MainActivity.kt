package ir.psdkjoon.papuy

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
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
            announceOpenPlayer(intent)
            handleIncoming(intent)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        MediaChannel.deliver(intent)
        announceHandoff(intent)
        announceOpenPlayer(intent)
        handleIncoming(intent)
    }

    override fun onPostResume() {
        super.onPostResume()
        EngineHolder.activity = this
        EngineHolder.installIfWaiting()
    }

    private var taskLabel: String? = null
    private var taskColor = 0

    @Suppress("DEPRECATION")
    override fun setTaskDescription(taskDescription: ActivityManager.TaskDescription?) {
        if (taskDescription != null) {
            taskLabel = taskDescription.label
            taskColor = taskDescription.primaryColor
        }
        super.setTaskDescription(withIcon(taskLabel, taskColor))
    }

    fun refreshTaskDescription() {
        super.setTaskDescription(withIcon(taskLabel, taskColor))
    }

    @Suppress("DEPRECATION")
    private fun withIcon(label: String?, color: Int): ActivityManager.TaskDescription {
        val icon = LauncherIcon.currentIconRes(this)
        return if (android.os.Build.VERSION.SDK_INT >= 33) {
            ActivityManager.TaskDescription.Builder()
                .setLabel(label)
                .setIcon(icon)
                .setPrimaryColor(color)
                .build()
        } else {
            ActivityManager.TaskDescription(label, icon, color)
        }
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
        FileService.onResult(this, requestCode, resultCode, data)
        super.onActivityResult(requestCode, resultCode, data)
        MediaChannel.onActivityResult(requestCode, resultCode, data)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        PermissionService.onResult(requestCode, grantResults)
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == MediaChannel.REQUEST_PERMISSION) {
            MediaChannel.onPermissionResult(
                grantResults.isNotEmpty() &&
                    grantResults.all { it == android.content.pm.PackageManager.PERMISSION_GRANTED },
            )
        }
    }

    override fun onDestroy() {
        if (EngineHolder.activity === this) EngineHolder.activity = null
        super.onDestroy()
    }

    private fun announceHandoff(intent: Intent?) {
        if (intent?.getBooleanExtra(EXTRA_HANDOFF, false) == true) {
            intent.removeExtra(EXTRA_HANDOFF)
            WindowChannel.sendCommand("handoff")
        }
    }

    private fun announceOpenPlayer(intent: Intent?) {
        if (intent?.getBooleanExtra(EXTRA_OPEN_PLAYER, false) == true) {
            intent.removeExtra(EXTRA_OPEN_PLAYER)
            WindowChannel.requestCommand(this, "openPlayer")
        }
    }

    private fun handleIncoming(intent: Intent?) {
        DeepLinkHandler.handle(intent)
        ShareService.handle(this, intent)
    }

    companion object {
        const val EXTRA_HANDOFF = "ir.psdkjoon.papuy.HANDOFF"
        const val EXTRA_OPEN_PLAYER = "ir.psdkjoon.papuy.OPEN_PLAYER"
    }
}
