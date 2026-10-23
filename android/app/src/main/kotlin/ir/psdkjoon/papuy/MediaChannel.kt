package ir.psdkjoon.papuy

import android.Manifest
import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.util.Size
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors

object MediaChannel {
    private const val CHANNEL = "papuy/media"
    private const val ALBUM = "Papuy"
    private const val MAX_SUBTITLE_BYTES = 5 * 1024 * 1024

    const val REQUEST_PERMISSION = 1
    const val REQUEST_DELETE = 2
    const val REQUEST_SUBTITLE = 3

    private lateinit var appContext: Context
    private lateinit var channel: MethodChannel

    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    private var launch: Map<String, String>? = null
    private var pendingPermission: MethodChannel.Result? = null
    private var pendingDelete: MethodChannel.Result? = null
    private var pendingSubtitle: MethodChannel.Result? = null
    private var pickingPlaylist = false

    fun register(engine: FlutterEngine, context: Context) {
        appContext = context.applicationContext
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun permissions(): Array<String> {
        return if (Build.VERSION.SDK_INT >= 33) {
            arrayOf(Manifest.permission.READ_MEDIA_VIDEO, Manifest.permission.READ_MEDIA_AUDIO)
        } else {
            arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
        }
    }

    private fun hasPermission(): Boolean {
        return permissions().all {
            appContext.checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasPermission" -> result.success(hasPermission())
            "requestPermission" -> requestPermission(result)
            "queryVideos" -> background(result) { queryVideos() }
            "queryAudio" -> background(result) { queryAudio() }
            "albumArt" -> background(result) {
                albumArt(
                    (call.argument<Number>("id") ?: 0).toLong(),
                    (call.argument<Number>("albumId") ?: 0).toLong(),
                    (call.argument<Number>("size") ?: 256).toInt(),
                    call.argument<String>("uri") ?: "",
                )
            }
            "savePlaylist" -> background(result) {
                savePlaylist(
                    call.argument<String>("name") ?: "playlist",
                    call.argument<String>("text") ?: "",
                    call.argument<Boolean>("share") == true,
                )
            }
            "thumbnail" -> background(result) {
                thumbnail(
                    (call.argument<Number>("id") ?: 0).toLong(),
                    (call.argument<Number>("width") ?: 320).toInt(),
                    (call.argument<Number>("height") ?: 180).toInt(),
                )
            }
            "takeLaunch" -> {
                val value = launch
                launch = null
                result.success(value)
            }
            "share" -> result.success(
                share(call.argument<String>("uri"), call.argument<String>("type") ?: "video/*"),
            )
            "delete" -> delete(call.argument<String>("uri"), result)
            "screenshot" -> {
                val uri = call.argument<String>("uri")
                val position = (call.argument<Number>("positionMs") ?: 0).toLong()
                background(result) { if (uri == null) false else screenshot(uri, position) }
            }
            "pickSubtitle" -> {
                pickingPlaylist = false
                pickSubtitle(result)
            }
            "pickPlaylist" -> {
                pickingPlaylist = true
                pickSubtitle(result)
            }
            else -> result.notImplemented()
        }
    }

    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        worker.execute {
            val value = try {
                work()
            } catch (_: Exception) {
                null
            }
            main.post { result.success(value) }
        }
    }

    private fun requestPermission(result: MethodChannel.Result) {
        val host = EngineHolder.activity
        if (hasPermission() || host == null) {
            result.success(hasPermission())
            return
        }
        pendingPermission?.success(false)
        pendingPermission = result
        host.requestPermissions(permissions(), REQUEST_PERMISSION)
    }

    fun onPermissionResult(granted: Boolean) {
        pendingPermission?.success(granted)
        pendingPermission = null
    }

    private fun queryVideos(): List<Map<String, Any>> {
        val collection = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DISPLAY_NAME,
            MediaStore.Video.Media.BUCKET_DISPLAY_NAME,
            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.WIDTH,
            MediaStore.Video.Media.HEIGHT,
            MediaStore.Video.Media.SIZE,
            MediaStore.Video.Media.DATE_ADDED,
        )
        val rows = ArrayList<Map<String, Any>>()
        appContext.contentResolver.query(
            collection,
            projection,
            null,
            null,
            "${MediaStore.Video.Media.DATE_ADDED} DESC",
        )?.use { cursor ->
            val id = cursor.getColumnIndexOrThrow(MediaStore.Video.Media._ID)
            val name = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DISPLAY_NAME)
            val folder = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.BUCKET_DISPLAY_NAME)
            val duration = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DURATION)
            val width = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.WIDTH)
            val height = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.HEIGHT)
            val size = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.SIZE)
            val added = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_ADDED)
            while (cursor.moveToNext()) {
                val videoId = cursor.getLong(id)
                rows.add(
                    mapOf(
                        "id" to videoId,
                        "name" to (cursor.getString(name) ?: ""),
                        "folder" to (cursor.getString(folder) ?: "Unknown"),
                        "durationMs" to cursor.getLong(duration),
                        "width" to cursor.getInt(width),
                        "height" to cursor.getInt(height),
                        "size" to cursor.getLong(size),
                        "added" to cursor.getLong(added),
                        "uri" to ContentUris.withAppendedId(collection, videoId).toString(),
                    ),
                )
            }
        }
        return rows
    }

    private fun queryAudio(): List<Map<String, Any>> {
        val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DATE_ADDED,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.DATA,
        )
        val rows = ArrayList<Map<String, Any>>()
        appContext.contentResolver.query(
            collection,
            projection,
            "${MediaStore.Audio.Media.IS_MUSIC} != 0",
            null,
            "${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC",
        )?.use { cursor ->
            val id = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val name = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)
            val title = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artist = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val album = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val albumId = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
            val duration = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val size = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
            val added = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
            val track = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TRACK)
            val data = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            while (cursor.moveToNext()) {
                val trackId = cursor.getLong(id)
                rows.add(
                    mapOf(
                        "id" to trackId,
                        "name" to (cursor.getString(name) ?: ""),
                        "title" to (cursor.getString(title) ?: ""),
                        "artist" to knownTag(cursor.getString(artist)),
                        "album" to knownTag(cursor.getString(album)),
                        "albumId" to cursor.getLong(albumId),
                        "durationMs" to cursor.getLong(duration),
                        "size" to cursor.getLong(size),
                        "added" to cursor.getLong(added),
                        "track" to cursor.getInt(track),
                        "path" to (cursor.getString(data) ?: ""),
                        "uri" to ContentUris.withAppendedId(collection, trackId).toString(),
                    ),
                )
            }
        }
        return rows
    }

    private fun knownTag(value: String?): String {
        if (value == null || value == MediaStore.UNKNOWN_STRING) return ""
        return value
    }

    @Suppress("DEPRECATION")
    private fun albumArt(id: Long, albumId: Long, size: Int, uriText: String): ByteArray? {
        val resolver = appContext.contentResolver
        val source = if (id >= 0) {
            ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
        } else {
            Uri.parse(uriText)
        }
        var bitmap: Bitmap? = null
        if (id >= 0 && Build.VERSION.SDK_INT >= 29) {
            bitmap = try {
                resolver.loadThumbnail(source, Size(size, size), null)
            } catch (_: Exception) {
                null
            }
        }
        if (bitmap == null) bitmap = embeddedArt(source, size)
        if (bitmap == null && id >= 0 && albumId > 0 && Build.VERSION.SDK_INT < 29) {
            val art = ContentUris.withAppendedId(Uri.parse("content://media/external/audio/albumart"), albumId)
            bitmap = try {
                resolver.openInputStream(art)?.use { BitmapFactory.decodeStream(it) }
            } catch (_: Exception) {
                null
            }
        }
        if (bitmap == null) return null
        val output = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 85, output)
        return output.toByteArray()
    }

    private fun embeddedArt(source: Uri, size: Int): Bitmap? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(appContext, source)
            val bytes = retriever.embeddedPicture ?: return null
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
            var sample = 1
            while (bounds.outWidth / (sample * 2) >= size && bounds.outHeight / (sample * 2) >= size) {
                sample *= 2
            }
            val options = BitmapFactory.Options().apply { inSampleSize = sample }
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
        } catch (_: Exception) {
            null
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
            }
        }
    }

    private fun savePlaylist(name: String, text: String, share: Boolean): Boolean {
        val safe = name.replace(Regex("[\\\\/:*?\"<>|]"), "_").trim().ifEmpty { "playlist" }
        val file = "$safe.m3u8"
        val bytes = text.toByteArray(Charsets.UTF_8)
        if (!share) {
            return FileService.saveToDownloads(appContext, bytes, file, "audio/x-mpegurl") != null
        }
        val folder = File(appContext.cacheDir, "exports").apply { mkdirs() }
        val target = File(folder, file)
        target.writeBytes(bytes)
        return ShareService.shareFiles(appContext, listOf(target.absolutePath), "audio/x-mpegurl")
    }

    private fun thumbnail(id: Long, width: Int, height: Int): ByteArray? {
        val uri = ContentUris.withAppendedId(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id)
        val bitmap = loadThumbnail(uri, id, width, height) ?: return null
        val output = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 80, output)
        return output.toByteArray()
    }

    @Suppress("DEPRECATION")
    private fun loadThumbnail(uri: Uri, id: Long, width: Int, height: Int): Bitmap? {
        val resolver = appContext.contentResolver
        if (Build.VERSION.SDK_INT >= 29) {
            return resolver.loadThumbnail(uri, Size(width, height), null)
        }
        return MediaStore.Video.Thumbnails.getThumbnail(
            resolver,
            id,
            MediaStore.Video.Thumbnails.MINI_KIND,
            null,
        )
    }

    private fun share(uriText: String?, type: String): Boolean {
        if (uriText == null) return false
        val send = Intent(Intent.ACTION_SEND)
            .setType(type)
            .putExtra(Intent.EXTRA_STREAM, Uri.parse(uriText))
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        val chooser = Intent.createChooser(send, null).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            appContext.startActivity(chooser)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun delete(uriText: String?, result: MethodChannel.Result) {
        if (uriText == null) {
            result.success(false)
            return
        }
        val uri = Uri.parse(uriText)
        val resolver = appContext.contentResolver
        val host = EngineHolder.activity
        try {
            if (Build.VERSION.SDK_INT >= 30) {
                if (host == null) {
                    result.success(false)
                    return
                }
                val sender = MediaStore.createDeleteRequest(resolver, listOf(uri)).intentSender
                pendingDelete = result
                host.startIntentSenderForResult(sender, REQUEST_DELETE, null, 0, 0, 0)
            } else {
                result.success(resolver.delete(uri, null, null) > 0)
            }
        } catch (e: RecoverableSecurityException) {
            if (host == null) {
                result.success(false)
                return
            }
            pendingDelete = result
            host.startIntentSenderForResult(
                e.userAction.actionIntent.intentSender,
                REQUEST_DELETE,
                null,
                0,
                0,
                0,
            )
        } catch (_: Exception) {
            pendingDelete = null
            result.success(false)
        }
    }

    private fun screenshot(uriText: String, positionMs: Long): Boolean {
        val retriever = MediaMetadataRetriever()
        try {
            val uri = Uri.parse(uriText)
            if (uri.scheme == "http" || uri.scheme == "https") {
                retriever.setDataSource(uriText, HashMap())
            } else {
                retriever.setDataSource(appContext, uri)
            }
            val frame = retriever.getFrameAtTime(
                positionMs * 1000,
                MediaMetadataRetriever.OPTION_CLOSEST,
            ) ?: return false
            return saveImage(frame)
        } finally {
            retriever.release()
        }
    }

    private fun saveImage(bitmap: Bitmap): Boolean {
        val name = "${ALBUM}_${System.currentTimeMillis()}.jpg"
        val resolver = appContext.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, name)
            put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
        }
        if (Build.VERSION.SDK_INT >= 29) {
            values.put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/$ALBUM")
            values.put(MediaStore.Images.Media.IS_PENDING, 1)
            val target = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: return false
            resolver.openOutputStream(target)?.use { bitmap.compress(Bitmap.CompressFormat.JPEG, 95, it) }
                ?: return false
            val done = ContentValues().apply { put(MediaStore.Images.Media.IS_PENDING, 0) }
            resolver.update(target, done, null, null)
            return true
        }
        @Suppress("DEPRECATION")
        val folder = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), ALBUM)
        if (!folder.exists() && !folder.mkdirs()) return false
        val file = File(folder, name)
        file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.JPEG, 95, it) }
        values.put(MediaStore.Images.Media.DATA, file.absolutePath)
        resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
        return true
    }

    private fun pickSubtitle(result: MethodChannel.Result) {
        val host = EngineHolder.activity
        if (host == null) {
            result.success(null)
            return
        }
        pendingSubtitle?.success(null)
        pendingSubtitle = result
        val pick = Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("*/*")
        @Suppress("DEPRECATION")
        host.startActivityForResult(pick, REQUEST_SUBTITLE)
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        when (requestCode) {
            REQUEST_DELETE -> {
                pendingDelete?.success(resultCode == Activity.RESULT_OK)
                pendingDelete = null
            }
            REQUEST_SUBTITLE -> {
                val waiting = pendingSubtitle
                pendingSubtitle = null
                val asPlaylist = pickingPlaylist
                pickingPlaylist = false
                val uri = data?.data
                if (waiting == null) return
                if (resultCode != Activity.RESULT_OK || uri == null) {
                    waiting.success(null)
                    return
                }
                background(waiting) {
                    val text = readText(uri)
                    if (asPlaylist) {
                        text?.let { mapOf("name" to displayName(uri), "text" to it) }
                    } else {
                        text
                    }
                }
            }
        }
    }

    private fun readText(uri: Uri): String? {
        val bytes = appContext.contentResolver.openInputStream(uri)?.use { input ->
            input.readBytes()
        } ?: return null
        if (bytes.size > MAX_SUBTITLE_BYTES) return null
        return String(bytes, Charsets.UTF_8)
    }

    fun setLaunch(intent: Intent?, quick: Boolean = false) {
        launch = describe(intent)?.let { if (quick) it + ("quick" to "1") else it }
    }

    fun deliver(intent: Intent?, quick: Boolean = false) {
        val described = describe(intent) ?: return
        channel.invokeMethod("intent", if (quick) described + ("quick" to "1") else described)
    }

    private fun describe(intent: Intent?): Map<String, String>? {
        if (intent == null) return null
        val uri: Uri? = when (intent.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> streamExtra(intent)
            else -> null
        }
        if (uri == null) return null
        val mime = intent.type ?: try {
            appContext.contentResolver.getType(uri)
        } catch (_: Exception) {
            null
        }
        return mapOf("uri" to uri.toString(), "name" to displayName(uri), "mime" to (mime ?: ""))
    }

    @Suppress("DEPRECATION")
    private fun streamExtra(intent: Intent): Uri? {
        return intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
    }

    private fun displayName(uri: Uri): String {
        if (uri.scheme == "content") {
            try {
                appContext.contentResolver.query(
                    uri,
                    arrayOf(OpenableColumns.DISPLAY_NAME),
                    null,
                    null,
                    null,
                )?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val value = cursor.getString(0)
                        if (!value.isNullOrEmpty()) return value
                    }
                }
            } catch (_: Exception) {
            }
        }
        return uri.lastPathSegment ?: uri.toString()
    }
}
