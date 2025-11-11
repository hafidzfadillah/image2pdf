package com.example.image_to_pdf

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.OutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "image_to_pdf/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "savePdfToDownloads" -> {
                    val filePath = call.argument<String>("filePath")
                    val fileName = call.argument<String>("fileName")
                    if (filePath != null && fileName != null) {
                        try {
                            val savedUri = savePdfToDownloads(filePath, fileName)
                            result.success(savedUri?.toString())
                        } catch (e: Exception) {
                            result.error("SAVE_ERROR", "Failed to save PDF: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "filePath and fileName are required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun savePdfToDownloads(filePath: String, fileName: String): android.net.Uri? {
        val file = File(filePath)
        if (!file.exists()) {
            throw Exception("Source file does not exist")
        }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10+ (API 29+): Use MediaStore API
            val contentValues = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            }

            val resolver = contentResolver
            var outputStream: OutputStream? = null
            var inputStream: FileInputStream? = null

            try {
                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                    ?: throw Exception("Failed to create file in Downloads")

                outputStream = resolver.openOutputStream(uri)
                    ?: throw Exception("Failed to open output stream")

                inputStream = FileInputStream(file)
                inputStream.copyTo(outputStream)

                uri
            } finally {
                outputStream?.close()
                inputStream?.close()
            }
        } else {
            // Android 9 and below: Direct file access
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!downloadsDir.exists()) {
                downloadsDir.mkdirs()
            }

            val destFile = File(downloadsDir, fileName)
            file.copyTo(destFile, overwrite = true)

            // Notify media scanner
            android.media.MediaScannerConnection.scanFile(
                this,
                arrayOf(destFile.absolutePath),
                arrayOf("application/pdf"),
                null
            )

            android.net.Uri.fromFile(destFile)
        }
    }
}
