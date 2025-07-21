package app.twake.android.chat

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import org.unifiedpush.flutter.connector.UnifiedPushService

import android.content.Context

class UnifiedPushReceiver : UnifiedPushService() {
    override fun getEngine(context: Context): FlutterEngine {
        var engine = MainActivity.engine
        if (engine == null) {
            engine = MainActivity.provideEngine(context)
            engine.localizationPlugin.sendLocalesToFlutter(
                context.resources.configuration
            )
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
        }
        return engine
    }
}