package com.stopit.app

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "stop_it/native"
    private var pendingResult: MethodChannel.Result? = null
    private val requestVpn = 7301

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "readState" -> result.success(AppStateStorage.read(getSharedPreferences("stop_it_private", MODE_PRIVATE)))
                "saveState" -> {
                    val json = call.argument<String>("json") ?: "{}"
                    AppStateStorage.save(getSharedPreferences("stop_it_private", MODE_PRIVATE), json)
                    result.success(true)
                }
                "protectionStatus" -> result.success(DnsFilterVpnService.isActive)
                "setDailyReminder" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    DailyReminderScheduler.setEnabled(this, enabled)
                    result.success(true)
                }
                "requestNotifications" -> {
                    if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                        requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 7302)
                    }
                    result.success(true)
                }
                "startProtection" -> {
                    if (pendingResult != null) { result.error("busy", "VPN permission request is already in progress", null); return@setMethodCallHandler }
                    val permissionIntent = VpnService.prepare(this)
                    if (permissionIntent == null) startVpn(result) else {
                        pendingResult = result
                        startActivityForResult(permissionIntent, requestVpn)
                    }
                }
                "stopProtection" -> {
                    try {
                        val intent = Intent(this, DnsFilterVpnService::class.java).setAction(DnsFilterVpnService.ACTION_STOP)
                        startService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("vpn_stop_failed", e.message, null)
                    }
                }
                "clearState" -> {
                    AppStateStorage.clear(getSharedPreferences("stop_it_private", MODE_PRIVATE))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startVpn(result: MethodChannel.Result) {
        try {
            val intent = Intent(this, DnsFilterVpnService::class.java).setAction(DnsFilterVpnService.ACTION_START)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent) else startService(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("vpn_start_failed", e.message, null)
        }
    }

    @Deprecated("Deprecated in Android API; retained for compatibility with FlutterActivity result flow")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == requestVpn) {
            val callback = pendingResult
            pendingResult = null
            if (resultCode == Activity.RESULT_OK && callback != null) startVpn(callback)
            else callback?.success(false)
        }
    }
}


/** Serializes app edits and VPN events so a fresh blocked record cannot be overwritten
 * by an app settings save that was prepared from an older snapshot. */
internal object AppStateStorage {
    private const val KEY = "state"
    val lock = Any()

    fun read(prefs: SharedPreferences): String = synchronized(lock) {
        prefs.getString(KEY, "{}") ?: "{}"
    }

    fun save(prefs: SharedPreferences, json: String) = synchronized(lock) {
        val incoming = try { JSONObject(json) } catch (_: Exception) { JSONObject() }
        val existing = try { JSONObject(prefs.getString(KEY, "{}") ?: "{}") } catch (_: Exception) { JSONObject() }
        val records = sortedMapOf<Pair<Long, String>, JSONObject>(compareBy<Pair<Long, String>> { it.first }.thenBy { it.second })
        for (root in listOf(existing, incoming)) {
            val attempts = root.optJSONArray("blockedAttempts") ?: JSONArray()
            for (i in 0 until attempts.length()) {
                val entry = attempts.optJSONObject(i) ?: continue
                val time = entry.optLong("at", 0L)
                if (time > 0) records[time to entry.optString("domain")] = entry
            }
        }
        val merged = JSONArray()
        for (record in records.values.toList().takeLast(150)) merged.put(record)
        incoming.put("blockedAttempts", merged)
        prefs.edit().putString(KEY, incoming.toString()).apply()
    }

    fun addBlocked(prefs: SharedPreferences, domain: String, at: Long) = synchronized(lock) {
        val root = try { JSONObject(prefs.getString(KEY, "{}") ?: "{}") } catch (_: Exception) { JSONObject() }
        val attempts = root.optJSONArray("blockedAttempts") ?: JSONArray()
        attempts.put(JSONObject().put("domain", domain).put("at", at))
        while (attempts.length() > 150) attempts.remove(0)
        root.put("blockedAttempts", attempts)
        prefs.edit().putString(KEY, root.toString()).apply()
    }

    fun clear(prefs: SharedPreferences) = synchronized(lock) { prefs.edit().clear().apply() }
}
