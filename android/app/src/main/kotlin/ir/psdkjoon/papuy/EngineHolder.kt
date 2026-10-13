package ir.psdkjoon.papuy

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

object EngineHolder {
    private const val NOTIFICATION_CHANNEL = "general"

    private lateinit var appContext: Context

    private var engine: FlutterEngine? = null
    private var tileChannel: MethodChannel? = null
    private var pendingToggle = false
    private var notificationId = 100

    @Volatile
    var activity: android.app.Activity? = null

    private var firstLaunch = true

    fun takeFirstLaunch(): Boolean {
        val value = firstLaunch
        firstLaunch = false
        return value
    }

    fun ensure(context: Context): FlutterEngine {
        engine?.let { return it }
        appContext = context.applicationContext
        val created = FlutterEngine(appContext)
        setUpChannels(created)
        created.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault(),
        )
        engine = created
        return created
    }

    fun toggleFromTile(context: Context) {
        if (engine != null) {
            tileChannel?.invokeMethod("toggleRequested", null)
            return
        }
        pendingToggle = true
        ensure(context)
    }

    private fun setUpChannels(e: FlutterEngine) {
        val messenger = e.dartExecutor.binaryMessenger

        PlayerChannel.register(e, appContext)
        MediaChannel.register(e, appContext)
        WindowChannel.register(e, appContext)

        MethodChannel(messenger, "papuy/paths").setMethodCallHandler { call, result ->
            when (call.method) {
                "resolve" -> result.success(
                    mapOf(
                        "nativeLibraryDir" to appContext.applicationInfo.nativeLibraryDir,
                        "filesDir" to appContext.filesDir.absolutePath,
                    ),
                )
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "papuy/launcher_icon").setMethodCallHandler { call, result ->
            when (call.method) {
                "set" -> {
                    setLauncherIcon(call.argument<Boolean>("dark") ?: true)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "papuy/system").setMethodCallHandler { call, result ->
            when (call.method) {
                "openUrl" -> openUrl(call.argument<String>("url"), result)
                "abi" -> result.success(Build.SUPPORTED_ABIS.firstOrNull())
                "setQuickPlay" -> {
                    QuickGate.set(appContext, call.argument<Boolean>("on") != false)
                    result.success(null)
                }
                "closeQuick" -> {
                    (activity as? QuickActivity)?.finish()
                    result.success(null)
                }
                "openFull" -> {
                    openFull()
                    result.success(null)
                }
                "requestNotifications" -> {
                    requestNotifications()
                    result.success(null)
                }
                "notify" -> {
                    notify(
                        call.argument<String>("title") ?: "",
                        call.argument<String>("body") ?: "",
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        val tile = MethodChannel(messenger, "papuy/tile")
        tileChannel = tile
        tile.setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> {
                    setTileEnabled(true)
                    result.success(null)
                }
                "setState" -> {
                    QuickTileService.setState(
                        appContext,
                        call.argument<String>("state") ?: "off",
                    )
                    result.success(null)
                }
                "consumeToggle" -> {
                    val value = pendingToggle
                    pendingToggle = false
                    result.success(value)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openFull() {
        val host = activity ?: return
        val intent = Intent(appContext, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            .putExtra(MainActivity.EXTRA_HANDOFF, true)
        appContext.startActivity(intent)
        if (host is QuickActivity) host.finish()
    }

    private fun openUrl(url: String?, result: MethodChannel.Result) {
        if (url == null) {
            result.error("bad_url", "No URL.", null)
            return
        }
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            appContext.startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error("no_browser", "No app can open this link.", null)
        }
    }

    private fun requestNotifications() {
        if (Build.VERSION.SDK_INT < 33) return
        val host = activity ?: return
        if (host.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        host.requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 0)
    }

    private fun notify(title: String, body: String) {
        val manager = appContext.getSystemService(NotificationManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(
                NotificationChannel(
                    NOTIFICATION_CHANNEL,
                    appContext.getString(R.string.notification_channel),
                    NotificationManager.IMPORTANCE_DEFAULT,
                ),
            )
        }
        val open = PendingIntent.getActivity(
            appContext,
            0,
            Intent(appContext, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val builder = if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(appContext, NOTIFICATION_CHANNEL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(appContext)
        }
        val notification = builder
            .setSmallIcon(R.drawable.ic_tile)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(open)
            .setAutoCancel(true)
            .build()
        try {
            manager.notify(notificationId++, notification)
        } catch (_: SecurityException) {
        }
    }

    private fun setTileEnabled(enabled: Boolean) {
        appContext.packageManager.setComponentEnabledSetting(
            ComponentName(appContext, "ir.psdkjoon.papuy.QuickTileService"),
            if (enabled) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            },
            PackageManager.DONT_KILL_APP,
        )
    }

    private fun setLauncherIcon(dark: Boolean) {
        val pm = appContext.packageManager
        val mocha = ComponentName(appContext, "ir.psdkjoon.papuy.IconMocha")
        val latte = ComponentName(appContext, "ir.psdkjoon.papuy.IconLatte")
        val enable = if (dark) mocha else latte
        val disable = if (dark) latte else mocha
        pm.setComponentEnabledSetting(
            enable,
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )
        pm.setComponentEnabledSetting(
            disable,
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP,
        )
    }
}
