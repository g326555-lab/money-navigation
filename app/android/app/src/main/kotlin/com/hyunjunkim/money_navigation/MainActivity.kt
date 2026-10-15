package com.hyunjunkim.money_navigation

import android.Manifest
import android.content.ContentUris
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.provider.CalendarContract
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Read-only calendar access for Android. Only READ_CALENDAR is declared; nothing here
 * writes. iOS uses the device_calendar_plus plugin instead (see docs in NOTES.md).
 *
 * Channel "money_navigation/calendar":
 *  - hasPermission() -> Boolean
 *  - requestPermission() -> Boolean (true when READ_CALENDAR is granted)
 *  - eventsOn(startMillis: Long, endMillis: Long) -> List<Map> with title (String),
 *    location (String), begin (Long, epoch ms), end (Long, epoch ms), allDay (Boolean),
 *    sorted by begin. All-day instances are reported by Android in UTC midnight.
 */
class MainActivity : FlutterActivity() {
    private var pendingPermission: MethodChannel.Result? = null
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler(::onCalendarCall)
    }

    private fun granted() = ContextCompat.checkSelfPermission(
        this, Manifest.permission.READ_CALENDAR,
    ) == PackageManager.PERMISSION_GRANTED

    private fun onCalendarCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasPermission" -> result.success(granted())
            "requestPermission" -> {
                if (granted()) {
                    result.success(true)
                } else if (pendingPermission != null) {
                    result.error("IN_PROGRESS", "A permission request is already open", null)
                } else {
                    pendingPermission = result
                    ActivityCompat.requestPermissions(
                        this, arrayOf(Manifest.permission.READ_CALENDAR), REQUEST_CALENDAR,
                    )
                }
            }
            "eventsOn" -> {
                val start = (call.argument<Number>("startMillis"))?.toLong()
                val end = (call.argument<Number>("endMillis"))?.toLong()
                if (start == null || end == null) {
                    result.error("BAD_ARGS", "startMillis and endMillis are required", null)
                } else if (!granted()) {
                    result.error("PERMISSION_DENIED", "READ_CALENDAR is not granted", null)
                } else {
                    worker.execute {
                        try {
                            val events = queryEvents(start, end)
                            main.post { result.success(events) }
                        } catch (e: Exception) {
                            main.post { result.error("QUERY_FAILED", e.message, null) }
                        }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun queryEvents(start: Long, end: Long): List<Map<String, Any?>> {
        val uri = CalendarContract.Instances.CONTENT_URI.buildUpon().also {
            ContentUris.appendId(it, start)
            ContentUris.appendId(it, end)
        }.build()
        val projection = arrayOf(
            CalendarContract.Instances.TITLE,
            CalendarContract.Instances.EVENT_LOCATION,
            CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.END,
            CalendarContract.Instances.ALL_DAY,
        )
        val events = mutableListOf<Map<String, Any?>>()
        contentResolver.query(uri, projection, null, null, "${CalendarContract.Instances.BEGIN} ASC")
            ?.use { cursor ->
                while (cursor.moveToNext()) {
                    events.add(
                        mapOf(
                            "title" to (cursor.getString(0) ?: ""),
                            "location" to (cursor.getString(1) ?: ""),
                            "begin" to cursor.getLong(2),
                            "end" to cursor.getLong(3),
                            "allDay" to (cursor.getInt(4) == 1),
                        ),
                    )
                }
            }
        return events
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CALENDAR) {
            val ok = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermission?.success(ok)
            pendingPermission = null
        }
    }

    override fun onDestroy() {
        worker.shutdown()
        super.onDestroy()
    }

    private companion object {
        const val CHANNEL = "money_navigation/calendar"
        const val REQUEST_CALENDAR = 4711
    }
}
