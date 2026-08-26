package app.walletmelt.wallet_melt

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyStore
import javax.crypto.KeyGenerator
import javax.crypto.Mac
import javax.crypto.SecretKey

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WINDOW_SECURITY_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSecureScreenEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled")
                    if (enabled == null) {
                        result.error(
                            "INVALID_ARGUMENT",
                            "enabled must be a boolean",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    if (enabled) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            KEYSTORE_MAC_CHANNEL,
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "sign" -> {
                        val payload = call.argument<ByteArray>("payload")
                        if (payload == null) {
                            result.error("INVALID_ARGUMENT", "payload is required", null)
                            return@setMethodCallHandler
                        }
                        val mac = getOrCreateHmac()
                        val tag = mac.doFinal(payload)
                        result.success(tag)
                    }
                    "verify" -> {
                        val payload = call.argument<ByteArray>("payload")
                        val signature = call.argument<ByteArray>("signature")
                        if (payload == null || signature == null) {
                            result.error("INVALID_ARGUMENT", "payload and signature required", null)
                            return@setMethodCallHandler
                        }
                        val mac = getOrCreateHmac()
                        val computed = mac.doFinal(payload)
                        result.success(computed.contentEquals(signature))
                    }
                    "resetKey" -> {
                        val keyStore = KeyStore.getInstance("AndroidKeyStore")
                        keyStore.load(null)
                        if (keyStore.containsAlias(KEYSTORE_ALIAS)) {
                            keyStore.deleteEntry(KEYSTORE_ALIAS)
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("KEYSTORE_ERROR", e.message, null)
            }
        }
    }

    private fun getOrCreateHmac(): Mac {
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        if (!keyStore.containsAlias(KEYSTORE_ALIAS)) {
            val keyGenerator = KeyGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_HMAC_SHA256,
                "AndroidKeyStore"
            )
            keyGenerator.init(
                KeyGenParameterSpec.Builder(
                    KEYSTORE_ALIAS,
                    KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
                ).build()
            )
            keyGenerator.generateKey()
        }
        val secretKey = keyStore.getKey(KEYSTORE_ALIAS, null) as SecretKey
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(secretKey)
        return mac
    }

    companion object {
        private const val WINDOW_SECURITY_CHANNEL =
            "app.walletmelt.wallet_melt/window_security"
        private const val KEYSTORE_MAC_CHANNEL =
            "app.walletmelt.wallet_melt/keystore_mac"
        private const val KEYSTORE_ALIAS = "walletmelt_ledger_hmac"
    }
}

