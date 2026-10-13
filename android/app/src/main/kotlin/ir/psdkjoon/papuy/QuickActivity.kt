package ir.psdkjoon.papuy

import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs
import io.flutter.embedding.engine.FlutterEngine

class QuickActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return EngineHolder.ensure(context)
    }

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun getBackgroundMode(): FlutterActivityLaunchConfigs.BackgroundMode {
        return FlutterActivityLaunchConfigs.BackgroundMode.transparent
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        Hosts.claim(this)
        super.onCreate(savedInstanceState)
        EngineHolder.activity = this
        if (savedInstanceState == null) {
            if (EngineHolder.takeFirstLaunch()) {
                MediaChannel.setLaunch(intent, quick = true)
            } else {
                MediaChannel.deliver(intent, quick = true)
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        MediaChannel.deliver(intent, quick = true)
    }

    override fun onPostResume() {
        super.onPostResume()
        EngineHolder.activity = this
    }

    override fun onDestroy() {
        if (EngineHolder.activity === this) EngineHolder.activity = null
        WindowChannel.sendCommand("quickClosed")
        super.onDestroy()
    }
}
