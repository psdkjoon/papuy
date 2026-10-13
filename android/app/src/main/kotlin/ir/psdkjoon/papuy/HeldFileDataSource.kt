package ir.psdkjoon.papuy

import android.net.Uri
import android.os.ParcelFileDescriptor
import androidx.media3.common.C
import androidx.media3.common.PlaybackException
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.BaseDataSource
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DataSourceException
import androidx.media3.datasource.DataSpec
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.channels.FileChannel

@androidx.annotation.OptIn(UnstableApi::class)
class HeldFileDataSource(private val channel: FileChannel) : BaseDataSource(false) {
    private var uri: Uri? = null
    private var position = 0L
    private var remaining = 0L
    private var opened = false

    override fun open(dataSpec: DataSpec): Long {
        uri = dataSpec.uri
        transferInitializing(dataSpec)
        val size = channel.size()
        if (dataSpec.position > size) {
            throw DataSourceException(PlaybackException.ERROR_CODE_IO_READ_POSITION_OUT_OF_RANGE)
        }
        position = dataSpec.position
        remaining = if (dataSpec.length != C.LENGTH_UNSET.toLong()) {
            dataSpec.length
        } else {
            size - position
        }
        opened = true
        transferStarted(dataSpec)
        return remaining
    }

    override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
        if (length == 0) return 0
        if (remaining == 0L) return C.RESULT_END_OF_INPUT
        val count = minOf(remaining, length.toLong()).toInt()
        val read = channel.read(ByteBuffer.wrap(buffer, offset, count), position)
        if (read < 0) return C.RESULT_END_OF_INPUT
        position += read
        remaining -= read
        bytesTransferred(read)
        return read
    }

    override fun getUri(): Uri? = uri

    override fun close() {
        uri = null
        if (opened) {
            opened = false
            transferEnded()
        }
    }

    class Factory(private val descriptor: ParcelFileDescriptor) : DataSource.Factory {
        private val channel: FileChannel = FileInputStream(descriptor.fileDescriptor).channel

        override fun createDataSource(): DataSource = HeldFileDataSource(channel)
    }
}
