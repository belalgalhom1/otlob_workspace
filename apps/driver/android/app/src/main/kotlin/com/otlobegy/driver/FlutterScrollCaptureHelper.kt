package com.otlobegy.driver

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.Rect
import android.os.Build
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import android.view.PixelCopy
import android.view.ScrollCaptureCallback
import android.view.ScrollCaptureSession
import android.view.TextureView
import android.view.View
import android.view.ViewGroup
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean
import java.util.function.Consumer
import kotlin.math.max
import kotlin.math.min

/**
 * Registers an Android 12+ (API 31+) [ScrollCaptureCallback] on [FlutterView]
 * bridged to Flutter's `AndroidScrollCaptureBridge` MethodChannel so native
 * scrolling screenshots ("Capture more" / long screenshots) work across screens.
 */
object FlutterScrollCaptureHelper {
    private const val CHANNEL_NAME = "com.otlobegy/scroll_capture"
    private const val CHANNEL_TIMEOUT_MS = 1200L

    fun attach(activity: Activity, flutterEngine: FlutterEngine) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        val decorView = activity.window?.decorView ?: return
        decorView.post {
            val flutterView = findViewOfType(decorView, FlutterView::class.java) ?: return@post
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            attachApi31(activity, flutterView, channel)
        }
    }

    fun detach(activity: Activity) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        val decorView = activity.window?.decorView ?: return
        val flutterView = findViewOfType(decorView, FlutterView::class.java) ?: return
        detachApi31(flutterView)
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun attachApi31(
        activity: Activity,
        flutterView: FlutterView,
        channel: MethodChannel,
    ) {
        flutterView.scrollCaptureHint = View.SCROLL_CAPTURE_HINT_INCLUDE
        flutterView.setScrollCaptureCallback(
            FlutterViewScrollCaptureCallback(activity, flutterView, channel),
        )
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun detachApi31(flutterView: FlutterView) {
        flutterView.setScrollCaptureCallback(null)
    }

    private fun <T : View> findViewOfType(root: View, clazz: Class<T>): T? {
        if (clazz.isInstance(root)) {
            @Suppress("UNCHECKED_CAST")
            return root as T
        }
        if (root is ViewGroup) {
            for (i in 0 until root.childCount) {
                val found = findViewOfType(root.getChildAt(i), clazz)
                if (found != null) return found
            }
        }
        return null
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private class FlutterViewScrollCaptureCallback(
        private val activity: Activity,
        private val flutterView: FlutterView,
        private val channel: MethodChannel,
    ) : ScrollCaptureCallback {
        private val mainHandler = Handler(Looper.getMainLooper())

        private var initialOffsetPx: Int = 0
        private var minExtentPx: Int = 0
        private var maxExtentPx: Int = 0
        private var viewportRect: Rect = Rect()

        override fun onScrollCaptureSearch(
            signal: CancellationSignal,
            onReady: Consumer<Rect>,
        ) {
            val completed = AtomicBoolean(false)
            fun finish(rect: Rect) {
                if (completed.compareAndSet(false, true)) {
                    onReady.accept(rect)
                }
            }

            if (signal.isCanceled) {
                finish(Rect())
                return
            }

            val timeoutRunnable = Runnable { finish(Rect()) }
            mainHandler.postDelayed(timeoutRunnable, CHANNEL_TIMEOUT_MS)
            signal.setOnCancelListener {
                mainHandler.removeCallbacks(timeoutRunnable)
                finish(Rect())
            }

            mainHandler.post {
                try {
                    channel.invokeMethod(
                        "getScrollMetrics",
                        null,
                        object : MethodChannel.Result {
                            override fun success(result: Any?) {
                                mainHandler.removeCallbacks(timeoutRunnable)
                                val metrics = result as? Map<*, *>
                                if (metrics == null || metrics["scrollable"] != true) {
                                    finish(Rect())
                                    return
                                }
                                finish(extractLocalViewportRect(metrics))
                            }

                            override fun error(code: String, msg: String?, details: Any?) {
                                mainHandler.removeCallbacks(timeoutRunnable)
                                finish(Rect())
                            }

                            override fun notImplemented() {
                                mainHandler.removeCallbacks(timeoutRunnable)
                                finish(Rect())
                            }
                        },
                    )
                } catch (_: Throwable) {
                    mainHandler.removeCallbacks(timeoutRunnable)
                    finish(Rect())
                }
            }
        }

        override fun onScrollCaptureStart(
            session: ScrollCaptureSession,
            signal: CancellationSignal,
            onReady: Runnable,
        ) {
            val completed = AtomicBoolean(false)
            fun finish() {
                if (completed.compareAndSet(false, true)) {
                    onReady.run()
                }
            }

            if (signal.isCanceled) {
                finish()
                return
            }

            val timeoutRunnable = Runnable { finish() }
            mainHandler.postDelayed(timeoutRunnable, CHANNEL_TIMEOUT_MS)
            signal.setOnCancelListener {
                mainHandler.removeCallbacks(timeoutRunnable)
                finish()
            }

            mainHandler.post {
                try {
                    channel.invokeMethod(
                        "startCapture",
                        null,
                        object : MethodChannel.Result {
                            override fun success(result: Any?) {
                                mainHandler.removeCallbacks(timeoutRunnable)
                                val metrics = result as? Map<*, *>
                                if (metrics != null && metrics["scrollable"] == true) {
                                    initialOffsetPx = (metrics["offsetPx"] as? Number)?.toInt() ?: 0
                                    minExtentPx = (metrics["minExtentPx"] as? Number)?.toInt() ?: 0
                                    maxExtentPx = (metrics["maxExtentPx"] as? Number)?.toInt() ?: 0
                                    viewportRect = extractLocalViewportRect(metrics)
                                } else {
                                    viewportRect = Rect()
                                }
                                finish()
                            }

                            override fun error(code: String, msg: String?, details: Any?) {
                                mainHandler.removeCallbacks(timeoutRunnable)
                                viewportRect = Rect()
                                finish()
                            }

                            override fun notImplemented() {
                                mainHandler.removeCallbacks(timeoutRunnable)
                                viewportRect = Rect()
                                finish()
                            }
                        },
                    )
                } catch (_: Throwable) {
                    mainHandler.removeCallbacks(timeoutRunnable)
                    viewportRect = Rect()
                    finish()
                }
            }
        }

        override fun onScrollCaptureImageRequest(
            session: ScrollCaptureSession,
            signal: CancellationSignal,
            captureArea: Rect,
            onComplete: Consumer<Rect>,
        ) {
            val completed = AtomicBoolean(false)
            fun finish(rect: Rect) {
                if (completed.compareAndSet(false, true)) {
                    onComplete.accept(rect)
                }
            }

            if (signal.isCanceled || viewportRect.isEmpty) {
                finish(Rect())
                return
            }

            val viewportHeight = viewportRect.height()
            if (viewportHeight <= 0) {
                finish(Rect())
                return
            }

            val contentTop = minExtentPx - initialOffsetPx
            val contentBottom = (maxExtentPx - initialOffsetPx) + viewportHeight
            val clampedTop = max(captureArea.top, contentTop)
            val clampedBottom = min(captureArea.bottom, contentBottom)
            if (clampedBottom <= clampedTop) {
                finish(Rect())
                return
            }

            val desiredOffsetPx = (initialOffsetPx + clampedTop).coerceIn(minExtentPx, maxExtentPx)
            val timeoutRunnable = Runnable { finish(Rect()) }
            mainHandler.postDelayed(timeoutRunnable, CHANNEL_TIMEOUT_MS * 2)
            signal.setOnCancelListener {
                mainHandler.removeCallbacks(timeoutRunnable)
                finish(Rect())
            }

            mainHandler.post {
                try {
                    channel.invokeMethod(
                        "scrollToOffset",
                        mapOf("offsetPx" to desiredOffsetPx),
                        object : MethodChannel.Result {
                            override fun success(result: Any?) {
                                if (signal.isCanceled) {
                                    mainHandler.removeCallbacks(timeoutRunnable)
                                    finish(Rect())
                                    return
                                }
                                val res = result as? Map<*, *>
                                if (res == null || res["ok"] != true) {
                                    mainHandler.removeCallbacks(timeoutRunnable)
                                    finish(Rect())
                                    return
                                }
                                val actualOffsetPx =
                                    (res["actualOffsetPx"] as? Number)?.toInt() ?: desiredOffsetPx
                                minExtentPx =
                                    (res["minExtentPx"] as? Number)?.toInt() ?: minExtentPx
                                maxExtentPx =
                                    (res["maxExtentPx"] as? Number)?.toInt() ?: maxExtentPx

                                val updatedContentTop = minExtentPx - initialOffsetPx
                                val updatedContentBottom =
                                    (maxExtentPx - initialOffsetPx) + viewportHeight
                                val reqTop = max(captureArea.top, updatedContentTop)
                                val reqBottom = min(captureArea.bottom, updatedContentBottom)

                                val visibleVirtualTop = actualOffsetPx - initialOffsetPx
                                val visibleVirtualBottom = visibleVirtualTop + viewportHeight

                                val drawVirtualTop = max(reqTop, visibleVirtualTop)
                                val drawVirtualBottom = min(reqBottom, visibleVirtualBottom)
                                if (drawVirtualBottom <= drawVirtualTop) {
                                    mainHandler.removeCallbacks(timeoutRunnable)
                                    finish(Rect())
                                    return
                                }

                                captureFlutterViewBitmap { bitmap ->
                                    mainHandler.removeCallbacks(timeoutRunnable)
                                    if (bitmap == null || signal.isCanceled) {
                                        bitmap?.recycle()
                                        finish(Rect())
                                        return@captureFlutterViewBitmap
                                    }

                                    val srcLeft = (viewportRect.left + captureArea.left)
                                        .coerceIn(0, bitmap.width)
                                    val srcRight = (viewportRect.left + captureArea.right)
                                        .coerceIn(srcLeft, bitmap.width)
                                    val srcTop =
                                        (viewportRect.top + (drawVirtualTop - visibleVirtualTop))
                                            .coerceIn(0, bitmap.height)
                                    val srcBottom =
                                        (viewportRect.top + (drawVirtualBottom - visibleVirtualTop))
                                            .coerceIn(srcTop, bitmap.height)

                                    val srcRect = Rect(srcLeft, srcTop, srcRight, srcBottom)
                                    val surface = session.surface
                                    if (srcRect.isEmpty || !surface.isValid) {
                                        bitmap.recycle()
                                        finish(Rect())
                                        return@captureFlutterViewBitmap
                                    }

                                    try {
                                        val canvas = surface.lockHardwareCanvas()
                                        try {
                                            val dstRect = Rect(0, 0, srcRect.width(), srcRect.height())
                                            canvas.drawBitmap(bitmap, srcRect, dstRect, null)
                                        } finally {
                                            surface.unlockCanvasAndPost(canvas)
                                        }
                                        val capturedLeft = srcLeft - viewportRect.left
                                        val capturedRight = srcRight - viewportRect.left
                                        val capturedTop =
                                            visibleVirtualTop + (srcTop - viewportRect.top)
                                        val capturedBottom =
                                            visibleVirtualTop + (srcBottom - viewportRect.top)
                                        finish(
                                            Rect(
                                                capturedLeft,
                                                capturedTop,
                                                capturedRight,
                                                capturedBottom,
                                            ),
                                        )
                                    } catch (_: Throwable) {
                                        finish(Rect())
                                    } finally {
                                        bitmap.recycle()
                                    }
                                }
                            }

                            override fun error(code: String, msg: String?, details: Any?) {
                                mainHandler.removeCallbacks(timeoutRunnable)
                                finish(Rect())
                            }

                            override fun notImplemented() {
                                mainHandler.removeCallbacks(timeoutRunnable)
                                finish(Rect())
                            }
                        },
                    )
                } catch (_: Throwable) {
                    mainHandler.removeCallbacks(timeoutRunnable)
                    finish(Rect())
                }
            }
        }

        override fun onScrollCaptureEnd(onReady: Runnable) {
            val completed = AtomicBoolean(false)
            fun finish() {
                if (completed.compareAndSet(false, true)) {
                    onReady.run()
                }
            }
            val timeoutRunnable = Runnable { finish() }
            mainHandler.postDelayed(timeoutRunnable, CHANNEL_TIMEOUT_MS)

            mainHandler.post {
                try {
                    channel.invokeMethod(
                        "endCapture",
                        null,
                        object : MethodChannel.Result {
                            override fun success(result: Any?) {
                                mainHandler.removeCallbacks(timeoutRunnable)
                                finish()
                            }

                            override fun error(code: String, msg: String?, details: Any?) {
                                mainHandler.removeCallbacks(timeoutRunnable)
                                finish()
                            }

                            override fun notImplemented() {
                                mainHandler.removeCallbacks(timeoutRunnable)
                                finish()
                            }
                        },
                    )
                } catch (_: Throwable) {
                    mainHandler.removeCallbacks(timeoutRunnable)
                    finish()
                }
            }
        }

        private fun extractLocalViewportRect(metrics: Map<*, *>): Rect {
            val viewWidth = flutterView.width
            val viewHeight = flutterView.height
            if (viewWidth <= 0 || viewHeight <= 0) return Rect()

            val location = IntArray(2)
            flutterView.getLocationInWindow(location)
            val offsetX = location[0]
            val offsetY = location[1]

            val left = ((metrics["viewportLeft"] as? Number)?.toInt() ?: 0) - offsetX
            val top = ((metrics["viewportTop"] as? Number)?.toInt() ?: 0) - offsetY
            val right = ((metrics["viewportRight"] as? Number)?.toInt() ?: viewWidth) - offsetX
            val bottom = ((metrics["viewportBottom"] as? Number)?.toInt() ?: viewHeight) - offsetY

            val rect = Rect(
                left.coerceIn(0, viewWidth),
                top.coerceIn(0, viewHeight),
                right.coerceIn(0, viewWidth),
                bottom.coerceIn(0, viewHeight),
            )
            return if (rect.width() > 0 && rect.height() > 0) rect else Rect()
        }

        private fun captureFlutterViewBitmap(callback: (Bitmap?) -> Unit) {
            val textureView = findViewOfType(flutterView, TextureView::class.java)
            if (textureView != null && textureView.isAvailable &&
                textureView.width > 0 && textureView.height > 0
            ) {
                val bmp = textureView.getBitmap()
                if (bmp != null) {
                    callback(bmp)
                    return
                }
            }

            val window = activity.window
            val width = flutterView.width
            val height = flutterView.height
            if (window == null || width <= 0 || height <= 0) {
                callback(null)
                return
            }

            val location = IntArray(2)
            flutterView.getLocationInWindow(location)
            val srcWindowRect = Rect(
                location[0],
                location[1],
                location[0] + width,
                location[1] + height,
            )
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            try {
                PixelCopy.request(
                    window,
                    srcWindowRect,
                    bitmap,
                    { copyResult ->
                        if (copyResult == PixelCopy.SUCCESS) {
                            callback(bitmap)
                        } else {
                            bitmap.recycle()
                            callback(null)
                        }
                    },
                    mainHandler,
                )
            } catch (_: Throwable) {
                bitmap.recycle()
                callback(null)
            }
        }
    }
}
