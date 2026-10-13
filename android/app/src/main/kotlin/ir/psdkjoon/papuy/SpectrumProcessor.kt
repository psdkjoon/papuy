package ir.psdkjoon.papuy

import androidx.media3.common.C
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.audio.BaseAudioProcessor
import androidx.media3.common.util.UnstableApi
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.log10
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.math.sqrt

object Spectrum {
    const val BANDS = 40

    @Volatile
    var bars: ByteArray = ByteArray(BANDS)

    fun clear() {
        bars = ByteArray(BANDS)
    }
}

@androidx.annotation.OptIn(UnstableApi::class)
class SpectrumProcessor : BaseAudioProcessor() {
    private val size = 2048
    private val half = size / 2
    private val window = FloatArray(size) { (0.5 - 0.5 * cos(2.0 * PI * it / (size - 1))).toFloat() }
    private val cosTable = FloatArray(half) { cos(2.0 * PI * it / size).toFloat() }
    private val sinTable = FloatArray(half) { -sin(2.0 * PI * it / size).toFloat() }
    private val ring = FloatArray(size)
    private val re = FloatArray(size)
    private val im = FloatArray(size)
    private var edges = IntArray(Spectrum.BANDS + 1)
    private var position = 0
    private var sinceLast = 0
    private var hop = 1470
    private var channels = 2
    private var encoding = C.ENCODING_PCM_16BIT

    override fun onConfigure(inputAudioFormat: AudioProcessor.AudioFormat): AudioProcessor.AudioFormat {
        val supported = when (inputAudioFormat.encoding) {
            C.ENCODING_PCM_16BIT,
            C.ENCODING_PCM_24BIT,
            C.ENCODING_PCM_32BIT,
            C.ENCODING_PCM_FLOAT,
            -> true
            else -> false
        }
        if (!supported || inputAudioFormat.channelCount < 1 || inputAudioFormat.sampleRate <= 0) {
            return AudioProcessor.AudioFormat.NOT_SET
        }
        channels = inputAudioFormat.channelCount
        encoding = inputAudioFormat.encoding
        hop = max(256, inputAudioFormat.sampleRate / 30)
        buildEdges(inputAudioFormat.sampleRate)
        return inputAudioFormat
    }

    private fun buildEdges(rate: Int) {
        val binHz = rate.toDouble() / size
        val low = 40.0
        val high = min(16000.0, rate / 2.0 * 0.92)
        val next = IntArray(Spectrum.BANDS + 1)
        next[0] = max(1, (low / binHz).roundToInt())
        for (band in 1..Spectrum.BANDS) {
            val frequency = low * (high / low).pow(band.toDouble() / Spectrum.BANDS)
            val bin = (frequency / binHz).roundToInt()
            next[band] = min(half, max(next[band - 1] + 1, bin))
        }
        edges = next
    }

    override fun queueInput(inputBuffer: ByteBuffer) {
        val remaining = inputBuffer.remaining()
        if (remaining == 0) return
        analyze(inputBuffer.duplicate().order(ByteOrder.LITTLE_ENDIAN))
        val output = replaceOutputBuffer(remaining)
        output.put(inputBuffer)
        output.flip()
    }

    private fun analyze(buffer: ByteBuffer) {
        val bytes = when (encoding) {
            C.ENCODING_PCM_16BIT -> 2
            C.ENCODING_PCM_24BIT -> 3
            else -> 4
        }
        val frame = bytes * channels
        while (buffer.remaining() >= frame) {
            var sum = 0f
            for (channel in 0 until channels) {
                sum += when (encoding) {
                    C.ENCODING_PCM_16BIT -> buffer.short / 32768f
                    C.ENCODING_PCM_24BIT -> {
                        val low = buffer.get().toInt() and 0xff
                        val mid = buffer.get().toInt() and 0xff
                        val top = buffer.get().toInt()
                        ((top shl 16) or (mid shl 8) or low) / 8388608f
                    }
                    C.ENCODING_PCM_32BIT -> buffer.int / 2147483648f
                    else -> buffer.float
                }
            }
            ring[position] = sum / channels
            position = (position + 1) % size
            sinceLast++
            if (sinceLast >= hop) {
                sinceLast = 0
                transform()
            }
        }
    }

    private fun transform() {
        for (index in 0 until size) {
            re[index] = ring[(position + index) % size] * window[index]
            im[index] = 0f
        }
        fft()
        val scale = size / 4f
        val out = ByteArray(Spectrum.BANDS)
        for (band in 0 until Spectrum.BANDS) {
            val from = edges[band]
            val to = max(from + 1, edges[band + 1])
            var peak = 0f
            for (bin in from until min(to, half)) {
                val magnitude = sqrt(re[bin] * re[bin] + im[bin] * im[bin]) / scale
                if (magnitude > peak) peak = magnitude
            }
            val decibels = 20.0 * log10(peak + 1e-9) + band * 0.3
            val level = ((decibels + 62.0) / 62.0).coerceIn(0.0, 1.0)
            out[band] = (level * 255.0).roundToInt().toByte()
        }
        Spectrum.bars = out
    }

    private fun fft() {
        var j = 0
        for (i in 1 until size) {
            var bit = size shr 1
            while (j and bit != 0) {
                j = j xor bit
                bit = bit shr 1
            }
            j = j xor bit
            if (i < j) {
                val tr = re[i]
                re[i] = re[j]
                re[j] = tr
                val ti = im[i]
                im[i] = im[j]
                im[j] = ti
            }
        }
        var length = 2
        while (length <= size) {
            val step = size / length
            val halfLength = length / 2
            var start = 0
            while (start < size) {
                for (k in 0 until halfLength) {
                    val wr = cosTable[k * step]
                    val wi = sinTable[k * step]
                    val a = start + k
                    val b = a + halfLength
                    val xr = re[b] * wr - im[b] * wi
                    val xi = re[b] * wi + im[b] * wr
                    re[b] = re[a] - xr
                    im[b] = im[a] - xi
                    re[a] += xr
                    im[a] += xi
                }
                start += length
            }
            length = length shl 1
        }
    }

    override fun onFlush() {
        ring.fill(0f)
        position = 0
        sinceLast = 0
        Spectrum.clear()
    }

    override fun onReset() {
        onFlush()
    }
}
