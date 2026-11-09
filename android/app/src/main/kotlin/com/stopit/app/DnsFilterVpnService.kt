package com.stopit.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.pm.ServiceInfo
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLPeerUnverifiedException
import javax.net.ssl.SSLSocket
import javax.net.ssl.SSLSocketFactory
import java.util.concurrent.atomic.AtomicBoolean
import org.json.JSONArray
import org.json.JSONObject

/** Local DNS-only VPN. It does not proxy, inspect, or store page URLs/content. */
class DnsFilterVpnService : VpnService() {
    companion object {
        const val ACTION_START = "com.stopit.app.START_FILTER"
        const val ACTION_STOP = "com.stopit.app.STOP_FILTER"
        private const val CHANNEL_ID = "stop_it_protection"
        @Volatile var isActive: Boolean = false
            private set
        private val stopping = AtomicBoolean(false)
        private val builtIn = setOf(
            "pornhub.com", "xvideos.com", "xnxx.com", "xhamster.com", "redtube.com",
            "youporn.com", "youjizz.com", "tube8.com", "spankbang.com", "chaturbate.com",
            "aturbate.com", "onlyfans.com", "fansly.com", "motherless.com", "brazzers.com",
            "thisvid.com", "rule34.xxx", "nhentai.net", "e621.net", "porn.com",
            "pornmd.com", "porntube.com", "tnaflix.com", "drtuber.com", "empflix.com",
            "eporner.com", "beeg.com", "hclips.com", "faphouse.com", "sex.com",
            "sexvid.xxx", "redgifs.com", "manyvids.com", "modelhub.com", "cam4.com",
            "livejasmin.com", "myfreecams.com", "bongacams.com", "stripchat.com",
            "camsoda.com", "imlive.com", "sextube.com", "javhd.com", "javmost.com",
            "jav.guru", "javlibrary.com", "adultempire.com", "xart.com", "hentaihaven.xxx",
            "rule34video.com", "gelbooru.com", "danbooru.donmai.us", "sankakucomplex.com",
            "8muses.com", "literotica.com", "adultwork.com", "ashleymadison.com"
        )
    }

    private var tunnel: ParcelFileDescriptor? = null
    private var worker: Thread? = null
    private var lastReminderAt = 0L
    private var blockedEventCounter = 0

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            // A VPN can remain system-bound after stopService(), so release its TUN file
            // descriptor here immediately rather than waiting for onDestroy().
            stopFiltering()
            stopSelfResult(startId)
            return START_NOT_STICKY
        }
        if ((intent?.action == ACTION_START || intent == null) && tunnel == null) startFiltering()
        return START_STICKY
    }

    private fun startFiltering() {
        createChannel()
        if (Build.VERSION.SDK_INT >= 34) startForeground(41, ongoingNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        else startForeground(41, ongoingNotification())
        try {
            tunnel = Builder()
                .setSession("STOP IT! DNS protection")
                .setMtu(1500)
                .addAddress("10.111.0.2", 32)
                .addDnsServer("10.111.0.1")
                // Route only the configured DNS resolver through this VPN. Other traffic remains direct.
                .addRoute("10.111.0.1", 32)
                .setBlocking(true)
                .establish()
            if (tunnel == null) { stopFiltering(); stopSelf(); return }
            stopping.set(false)
            isActive = true
            worker = Thread({ dnsLoop() }, "stop-it-dns-filter").also { it.start() }
            updateOngoingNotification("Protection is on")
        } catch (_: Exception) {
            stopFiltering()
            stopSelf()
        }
    }

    /** Releases the VPN interface immediately, even if Android still binds this service. */
    private fun stopFiltering() {
        stopping.set(true)
        isActive = false
        try { tunnel?.close() } catch (_: Exception) { }
        tunnel = null
        worker?.interrupt()
        worker = null
        try { (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).apply { cancel(41); cancel(42) } } catch (_: Exception) { }
        if (Build.VERSION.SDK_INT >= 24) stopForeground(STOP_FOREGROUND_REMOVE) else stopForeground(true)
    }

    private fun dnsLoop() {
        val fd = tunnel ?: return
        val input = FileInputStream(fd.fileDescriptor)
        val output = FileOutputStream(fd.fileDescriptor)
        val packetBuffer = ByteArray(32767)
        while (!stopping.get()) {
            try {
                val size = input.read(packetBuffer)
                if (size < 28) continue
                val packet = packetBuffer.copyOf(size)
                val ipHeader = (packet[0].toInt() and 0x0f) * 4
                if ((packet[0].toInt() ushr 4 and 0x0f) != 4 || ipHeader < 20 || (packet[9].toInt() and 0xff) != 17) continue
                if (size < ipHeader + 8) continue
                val udpLength = u16(packet, ipHeader + 4)
                if (udpLength < 8 || size < ipHeader + udpLength) continue
                val dns = packet.copyOfRange(ipHeader + 8, ipHeader + udpLength)
                if (dns.size < 12) continue
                val domain = queryDomain(dns) ?: continue
                val custom = customDomains()
                if (isBlocked(domain, custom)) {
                    recordBlocked(domain)
                    val response = makeDnsError(dns)
                    val reply = makeIpUdpReply(packet, ipHeader, response)
                    output.write(reply)
                    maybeNotify()
                } else {
                    val forwarded = forwardDns(dns)
                    val response = if (forwarded == null || forwarded.size + ipHeader + 8 > 1500) makeDnsError(dns, 2) else forwarded
                    output.write(makeIpUdpReply(packet, ipHeader, response))
                }
            } catch (_: Exception) {
                if (stopping.get()) break
            }
        }
    }

    private fun queryDomain(message: ByteArray): String? {
        if (message.size < 17 || u16(message, 4) == 0) return null
        var index = 12
        val labels = mutableListOf<String>()
        while (index < message.size) {
            val length = message[index++].toInt() and 0xff
            if (length == 0) break
            if (length > 63 || index + length > message.size) return null
            labels.add(String(message, index, length, Charsets.US_ASCII).lowercase())
            index += length
        }
        return labels.joinToString(".").takeIf { it.isNotBlank() }
    }

    private fun isBlocked(domain: String, custom: Set<String>): Boolean {
        return (builtIn + custom).any { domain == it || domain.endsWith(".$it") }
    }

    private fun customDomains(): Set<String> {
        return try {
            val state = JSONObject(AppStateStorage.read(getSharedPreferences("stop_it_private", MODE_PRIVATE)))
            val array = state.optJSONArray("customDomains") ?: JSONArray()
            (0 until array.length()).mapNotNull { array.optString(it).lowercase().trim().trimEnd('.').takeIf(String::isNotBlank) }.toSet()
        } catch (_: Exception) { emptySet() }
    }

    private fun forwardDns(query: ByteArray): ByteArray? {
        var raw: Socket? = null
        var secure: SSLSocket? = null
        return try {
            // Cloudflare DNS over TLS. The socket is protected from this VPN to avoid a loop.
            // Connect by IP to avoid resolving the resolver hostname through this same tunnel;
            // pass the certificate hostname separately for TLS SNI and hostname verification.
            raw = Socket()
            if (!protect(raw)) return null
            raw.connect(InetSocketAddress(InetAddress.getByName("1.1.1.1"), 853), 2500)
            raw.soTimeout = 2500
            secure = (SSLSocketFactory.getDefault() as SSLSocketFactory)
                .createSocket(raw, "cloudflare-dns.com", 853, true) as SSLSocket
            secure.soTimeout = 2500
            if (Build.VERSION.SDK_INT >= 24) {
                val tlsParameters = secure.sslParameters
                tlsParameters.endpointIdentificationAlgorithm = "HTTPS"
                secure.sslParameters = tlsParameters
            }
            secure.startHandshake()
            // API 23 has no endpoint-identification SSLParameters setter; always verify explicitly too.
            if (!HttpsURLConnection.getDefaultHostnameVerifier().verify("cloudflare-dns.com", secure.session)) {
                throw SSLPeerUnverifiedException("DNS resolver hostname did not match the TLS certificate")
            }
            val out = DataOutputStream(secure.getOutputStream())
            out.writeShort(query.size)
            out.write(query)
            out.flush()
            val input = DataInputStream(secure.getInputStream())
            val responseSize = input.readUnsignedShort()
            if (responseSize < 12 || responseSize > 4096) return null
            ByteArray(responseSize).also { input.readFully(it) }
        } catch (_: Exception) { null } finally {
            try { secure?.close() } catch (_: Exception) { }
            try { raw?.close() } catch (_: Exception) { }
        }
    }

    private fun makeDnsError(query: ByteArray, rcode: Int = 3): ByteArray {
        val answer = query.copyOf()
        if (answer.size >= 12) {
            answer[2] = ((answer[2].toInt() and 0x79) or 0x80).toByte() // QR, opcode, and RD
            answer[3] = ((answer[3].toInt() and 0xf0) or 0x80 or rcode).toByte() // RA + RCODE
            for (i in 6..11) answer[i] = 0
        }
        return answer
    }

    private fun makeIpUdpReply(request: ByteArray, ipHeader: Int, dns: ByteArray): ByteArray {
        val udpSize = 8 + dns.size
        val reply = ByteArray(ipHeader + udpSize)
        System.arraycopy(request, 0, reply, 0, ipHeader)
        // IPv4 source and destination are reversed.
        System.arraycopy(request, 16, reply, 12, 4)
        System.arraycopy(request, 12, reply, 16, 4)
        reply[2] = (reply.size ushr 8).toByte(); reply[3] = reply.size.toByte()
        reply[6] = 0; reply[7] = 0; reply[10] = 0; reply[11] = 0
        write16(reply, 10, checksum(reply, 0, ipHeader))
        write16(reply, ipHeader, u16(request, ipHeader + 2))
        write16(reply, ipHeader + 2, u16(request, ipHeader))
        write16(reply, ipHeader + 4, udpSize)
        write16(reply, ipHeader + 6, 0)
        System.arraycopy(dns, 0, reply, ipHeader + 8, dns.size)
        return reply
    }

    private fun checksum(bytes: ByteArray, start: Int, length: Int): Int {
        var sum = 0L; var i = start
        while (i < start + length) {
            sum += (((bytes[i].toInt() and 0xff) shl 8) or (if (i + 1 < start + length) bytes[i + 1].toInt() and 0xff else 0)).toLong()
            i += 2
        }
        while (sum shr 16 != 0L) sum = (sum and 0xffff) + (sum shr 16)
        return sum.inv().toInt() and 0xffff
    }
    private fun u16(b: ByteArray, i: Int) = ((b[i].toInt() and 0xff) shl 8) or (b[i + 1].toInt() and 0xff)
    private fun write16(b: ByteArray, i: Int, value: Int) { b[i] = (value ushr 8).toByte(); b[i + 1] = value.toByte() }

    private fun recordBlocked(domain: String) {
        AppStateStorage.addBlocked(getSharedPreferences("stop_it_private", MODE_PRIVATE), domain, System.currentTimeMillis())
    }

    @Suppress("DEPRECATION")
    private fun maybeNotify() {
        val now = System.currentTimeMillis()
        if (now - lastReminderAt < 30_000) return
        lastReminderAt = now
        blockedEventCounter++
        val lang = try { JSONObject(AppStateStorage.read(getSharedPreferences("stop_it_private", MODE_PRIVATE))).optString("language", "en") } catch (_: Exception) { "en" }
        val english = listOf(
            "Allah sees you. Pause and choose a better next step. “Does he not know that Allah sees?” Quran 96:14.",
            "You are not powerless. Breathe, step away, and choose again. Quran 96:14 reminds us that Allah sees.",
            "This urge will pass. Choose patience over a passing moment. “Does he not know that Allah sees?” Quran 96:14."
        )
        val urdu = listOf(
            "اللہ دیکھ رہا ہے۔ ایک لمحہ رکیں اور بہتر قدم چنیں۔ قرآن 96:14۔",
            "آپ بےبس نہیں۔ سانس لیں اور دوبارہ انتخاب کریں۔ اللہ دیکھ رہا ہے؛ قرآن 96:14۔",
            "یہ خواہش گزر جائے گی۔ صبر کا انتخاب کریں۔ قرآن 96:14۔"
        )
        val arabic = listOf(
            "الله يراك. تمهّل واختر خطوة أفضل. تذكّر القرآن 96:14.",
            "لست عاجزًا. تنفّس وابتعد واختر مجددًا. الله يراك، القرآن 96:14.",
            "ستمر هذه الرغبة. اختر الصبر. القرآن 96:14."
        )
        val title = when (lang) { "ur" -> "اب رک جائیں"; "ar" -> "توقّف الآن"; else -> "STOP NOW!" }
        val messages = when (lang) { "ur" -> urdu; "ar" -> arabic; else -> english }
        val body = messages[(blockedEventCounter - 1) % messages.size]
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        val notification = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_lock).setContentTitle(title).setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body)).setAutoCancel(true).build()
        else Notification.Builder(this).setSmallIcon(android.R.drawable.ic_lock_lock).setContentTitle(title).setContentText(body).build()
        try { manager.notify(42, notification) } catch (_: SecurityException) { }
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= 26) {
            val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(NotificationChannel(CHANNEL_ID, "Protection and reminders", NotificationManager.IMPORTANCE_DEFAULT))
        }
    }
    private fun ongoingNotification(): Notification = buildNotification("Protection is starting")
    private fun updateOngoingNotification(text: String) {
        try { (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).notify(41, buildNotification(text)) } catch (_: Exception) { }
    }
    @Suppress("DEPRECATION")
    private fun buildNotification(text: String): Notification {
        val openApp = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        return if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, CHANNEL_ID).setSmallIcon(android.R.drawable.ic_lock_lock).setContentTitle("STOP IT! protection").setContentText(text).setOngoing(true).setContentIntent(openApp).build()
        else @Suppress("DEPRECATION") Notification.Builder(this).setSmallIcon(android.R.drawable.ic_lock_lock).setContentTitle("STOP IT! protection").setContentText(text).setOngoing(true).setContentIntent(openApp).build()
    }

    override fun onRevoke() { stopFiltering(); stopSelf(); super.onRevoke() }
    override fun onDestroy() {
        stopFiltering()
        super.onDestroy()
    }
}
