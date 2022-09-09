package com.otclient

import android.content.Context
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream

private const val GAME_DATA_FOLDER = "game_data"
private const val ZIP_LOG_FILE = "zip.log"

class GameDataManager {

    fun initialize(context: Context) {
        val gameDataFolder = "${context.filesDir.absolutePath}/$GAME_DATA_FOLDER"
        val logFile = File(gameDataFolder, ZIP_LOG_FILE)

        if (logFile.exists()) {
            return
        }

        try {
            val inputStream = context.assets.open("data.zip")
            unzip(inputStream, gameDataFolder)
            logFile.createNewFile()
        } catch (ex: IOException) {
            Log.e("OTClient", "Error when trying to unzip data.zip", ex)
        }
    }

    private fun unzip(stream: InputStream, destination: String) {
        makeDirsIfPossible(destination, "")

        val buffer = ByteArray(1024 * 10)
        val zin = ZipInputStream(stream)
        var zipEntry: ZipEntry?
        while (zin.nextEntry.also { zipEntry = it } != null) {
            if (zipEntry?.isDirectory == true) {
                makeDirsIfPossible(destination, zipEntry?.name ?: "")
            } else {
                val f = File(destination, zipEntry?.name ?: "")
                if (!f.exists()) {
                    val success: Boolean = f.createNewFile()
                    if (!success) {
                        throw IOException("Failed to create file " + f.name)
                    }
                    val fout = FileOutputStream(f)
                    var count: Int
                    while (zin.read(buffer).also { count = it } != -1) {
                        fout.write(buffer, 0, count)
                    }
                    zin.closeEntry()
                    fout.close()
                }
            }
        }
        zin.close()
    }

    private fun makeDirsIfPossible(destination: String, dir: String) {
        val f = File(destination, dir)
        if (!f.exists()) {
            val success = f.mkdirs()
            if (!success) {
                throw IOException("Failed to create folder " + f.name)
            }
        }
    }
}