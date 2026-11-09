package com.stopit.app

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONObject
import java.util.Calendar

/** User-opted-in daily local reminder. Inexact alarms avoid exact-alarm special access. */
object DailyReminderScheduler {
    const val ACTION = "com.stopit.app.DAILY_REMINDER"
    private const val REQUEST_ID = 430
    private const val NOTIFICATION_ID = 43
    private const val CHANNEL_ID = "stop_it_protection"

    fun setEnabled(context: Context, enabled: Boolean) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val operation = pendingIntent(context)
        if (!enabled) {
            alarmManager.cancel(operation)
            operation.cancel()
            return
        }
        schedule(context, alarmManager, operation)
    }

    fun schedule(context: Context, alarmManager: AlarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager, operation: PendingIntent = pendingIntent(context)) {
        val next = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 9)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (!after(Calendar.getInstance())) add(Calendar.DAY_OF_YEAR, 1)
        }
        alarmManager.setInexactRepeating(AlarmManager.RTC_WAKEUP, next.timeInMillis, AlarmManager.INTERVAL_DAY, operation)
    }

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, DailyReminderReceiver::class.java).setAction(ACTION)
        return PendingIntent.getBroadcast(context, REQUEST_ID, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    @Suppress("DEPRECATION")
    internal fun showReminder(context: Context) {
        ensureChannel(context)
        val state = try { JSONObject(AppStateStorage.read(context.getSharedPreferences("stop_it_private", Context.MODE_PRIVATE))) } catch (_: Exception) { JSONObject() }
        if (!state.optBoolean("dailyReminderEnabled", false)) return
        val (title, text) = when (state.optString("language", "en")) {
            "ur" -> "روزانہ یاد دہانی" to "کیا اس نے نہیں جانا کہ اللہ تعالیٰ اسے خوب دیکھ رہا ہے؟ (قرآن 96:14، ترجمہ محمد جوناگڑھی)"
            "ar" -> "تذكير يومي" to "أَلَمْ يَعْلَمْ بِأَنَّ اللَّهَ يَرَىٰ — القرآن 96:14"
            else -> "A moment to remember" to "Does he not know that Allah sees? Quran 96:14, Saheeh International."
        }
        val openApp = PendingIntent.getActivity(context, REQUEST_ID, Intent(context, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_lock).setContentTitle(title).setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text)).setContentIntent(openApp).setAutoCancel(true).build()
        else Notification.Builder(context).setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentTitle(title).setContentText(text).setContentIntent(openApp).setAutoCancel(true).build()
        try { (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).notify(NOTIFICATION_ID, notification) } catch (_: SecurityException) { }
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= 26) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(NotificationChannel(CHANNEL_ID, "Protection and reminders", NotificationManager.IMPORTANCE_DEFAULT))
        }
    }
}

@Suppress("DEPRECATION")
class DailyReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            DailyReminderScheduler.ACTION -> DailyReminderScheduler.showReminder(context)
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED -> {
                val state = try { JSONObject(AppStateStorage.read(context.getSharedPreferences("stop_it_private", Context.MODE_PRIVATE))) } catch (_: Exception) { JSONObject() }
                if (state.optBoolean("dailyReminderEnabled", false)) DailyReminderScheduler.schedule(context)
            }
        }
    }
}
