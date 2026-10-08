package com.example.signlang

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

/**
 * Keeps the running Flutter app alive when Android destroys this screen (e.g. Home was pressed with
 * "Don't keep activities" on, or the launcher opens a new activity). Coming back reattaches the same
 * engine, so the user lands where they were instead of on the splash screen.
 * How long that state is kept is decided on the Dart side (MyApp, 20 minutes).
 */
class MainActivity : FlutterActivity() {
    companion object {
        private const val ENGINE_ID = "signlang_main_engine"
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine {
        val cache = FlutterEngineCache.getInstance()
        return cache.get(ENGINE_ID) ?: FlutterEngine(context.applicationContext).also { cache.put(ENGINE_ID, it) }
    }

    // the engine outlives this activity; it's reused by the next one
    override fun shouldDestroyEngineWithHost(): Boolean = false
}
