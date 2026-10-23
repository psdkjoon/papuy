package ir.psdkjoon.papuy

import android.content.Intent
import android.net.Uri

object DeepLinkHandler {
    val scheme = "papuy".replace('_', '-')

    @Volatile
    private var pending: String? = null

    fun uri(host: String, path: String): Uri =
        Uri.Builder().scheme(scheme).authority(host).appendPath(path).build()

    fun handle(intent: Intent?): Boolean {
        if (intent == null || intent.action != Intent.ACTION_VIEW) return false
        val data = intent.data ?: return false
        if (data.scheme != scheme) return false
        pending = data.toString()
        return true
    }

    fun consume(): String? {
        val link = pending
        pending = null
        return link
    }
}
