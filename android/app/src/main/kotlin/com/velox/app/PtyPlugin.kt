package com.velox.app

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

class PtyPlugin(private val context: Context) {

    private var process: Process? = null
    private var outputThread: Thread? = null

    companion object {
        private const val METHOD_CHANNEL = "com.velox.app/pty"
        private const val EVENT_CHANNEL = "com.velox.app/pty_output"

        fun register(flutterEngine: FlutterEngine, context: Context) {
            val plugin = PtyPlugin(context)
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                METHOD_CHANNEL
            ).setMethodCallHandler { call, result ->
                when (call.method) {
                    "startPty" -> {
                        plugin.startPty()
                        result.success(null)
                    }
                    "write" -> {
                        val input = call.argument<String>("input") ?: ""
                        plugin.write(input)
                        result.success(null)
                    }
                    "resize" -> {
                        val cols = call.argument<Int>("cols") ?: 80
                        val rows = call.argument<Int>("rows") ?: 24
                        plugin.resize(cols, rows)
                        result.success(null)
                    }
                    "kill" -> {
                        plugin.kill()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

            EventChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                EVENT_CHANNEL
            ).setStreamHandler(plugin.createStreamHandler())
        }
    }

    private var eventSink: EventChannel.EventSink? = null

    private fun createStreamHandler() = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
            eventSink = sink
        }
        override fun onCancel(arguments: Any?) {
            eventSink = null
        }
    }

    private fun startPty() {
        // Try Termux shell first, fallback to system sh
        val shell = listOf(
            "/data/data/com.termux/files/usr/bin/bash",
            "/data/data/com.termux/files/usr/bin/sh",
            "/system/bin/sh"
        ).firstOrNull { File(it).exists() } ?: "/system/bin/sh"

        val home = context.getExternalFilesDir(null)?.absolutePath
            ?: "/sdcard"

        val pb = ProcessBuilder(shell).apply {
            environment().apply {
                put("TERM", "xterm-256color")
                put("HOME", home)
                put("PATH", "/data/data/com.termux/files/usr/bin:/system/bin:/system/xbin")
                put("LD_LIBRARY_PATH", "/data/data/com.termux/files/usr/lib")
                put("PREFIX", "/data/data/com.termux/files/usr")
                put("COLORTERM", "truecolor")
            }
            redirectErrorStream(true)
        }

        process = pb.start()

        outputThread = Thread {
            val buffer = ByteArray(4096)
            val inputStream = process!!.inputStream
            try {
                while (true) {
                    val n = inputStream.read(buffer)
                    if (n == -1) break
                    val text = String(buffer, 0, n, Charsets.UTF_8)
                    eventSink?.success(text)
                }
            } catch (_: Exception) {}
            eventSink?.endOfStream()
        }.also { it.start() }
    }

    private fun write(input: String) {
        try {
            process?.outputStream?.apply {
                write(input.toByteArray(Charsets.UTF_8))
                flush()
            }
        } catch (_: Exception) {}
    }

    private fun kill() {
        process?.destroy()
        outputThread?.interrupt()
        process = null
    }

    private fun resize(cols: Int, rows: Int) {
        // PTY resize via TIOCSWINSZ - requires native library
        // For now, just log the requested size
        android.util.Log.i("PtyPlugin", "Resize requested: ${cols}x${rows}")
        // TODO: Implement proper PTY resize using libpty or termios
    }
}