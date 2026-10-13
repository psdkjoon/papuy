package ir.psdkjoon.papuy

import android.app.Application

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        EngineHolder.ensure(this)
    }
}
