package ir.psdkjoon.papuy

import android.app.Activity
import android.content.Intent
import android.os.Bundle

class ViewRouterActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val target = if (QuickGate.enabled(this)) QuickActivity::class.java else MainActivity::class.java
        val forward = Intent(intent)
            .setClass(this, target)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        try {
            startActivity(forward)
        } catch (_: Exception) {
        }
        finish()
        @Suppress("DEPRECATION")
        overridePendingTransition(0, 0)
    }
}
