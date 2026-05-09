package cn.suiguan.app

import io.flutter.embedding.android.FlutterActivity
import java.io.File
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            try {
                val dir = File(getExternalFilesDir(null), "crash_logs")
                if (!dir.exists()) dir.mkdirs()
                val timestamp = SimpleDateFormat("yyyy-MM-dd_HH-mm-ss", Locale.getDefault()).format(Date())
                val file = File(dir, "native_crash_$timestamp.txt")
                val writer = FileWriter(file, true)
                writer.write("Thread: $thread\n")
                writer.write("Time: $timestamp\n")
                writer.write("Exception: ${throwable.javaClass.name}\n")
                writer.write("Message: ${throwable.message}\n")
                writer.write("Stack:\n")
                throwable.stackTrace.forEach { writer.write("  $it\n") }
                val cause = throwable.cause
                if (cause != null) {
                    writer.write("Caused by: ${cause.javaClass.name}: ${cause.message}\n")
                    cause.stackTrace.forEach { writer.write("  $it\n") }
                }
                writer.flush()
                writer.close()
            } catch (_: Exception) {}
            android.os.Process.killProcess(android.os.Process.myPid())
        }
        super.onCreate(savedInstanceState)
    }
}
