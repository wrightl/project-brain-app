package com.dotdash.projectbrain

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Journal, chat and profile content is sensitive: keep it out of the
        // recents thumbnail and block screenshots/screen recording. Android
        // captures the thumbnail before Flutter can draw the app lock cover.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
    }
}
