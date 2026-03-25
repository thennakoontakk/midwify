package com.midwify.app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import java.nio.ByteBuffer
import java.nio.ByteOrder

class HeadLandmarkerBridge(
    private val context: Context,
) {
    private var faceLandmarker: FaceLandmarker? = null

    @Synchronized
    private fun getFaceLandmarker(): FaceLandmarker {
        faceLandmarker?.let { return it }

        val modelBuffer = loadModelBuffer(MODEL_ASSET_PATH)
        val baseOptions = BaseOptions.builder()
            .setModelAssetBuffer(modelBuffer)
            .build()
        val options = FaceLandmarker.FaceLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.IMAGE)
            .setNumFaces(1)
            .setMinFaceDetectionConfidence(0.5f)
            .setMinFacePresenceConfidence(0.5f)
            .setMinTrackingConfidence(0.5f)
            .build()

        return FaceLandmarker.createFromOptions(context, options).also {
            faceLandmarker = it
        }
    }

    fun detectFromPath(imagePath: String): Map<String, Any> {
        val decodedBitmap = BitmapFactory.decodeFile(imagePath)
            ?: throw IllegalArgumentException("Unable to decode image at $imagePath")
        val bitmap = if (decodedBitmap.config == Bitmap.Config.ARGB_8888) {
            decodedBitmap
        } else {
            decodedBitmap.copy(Bitmap.Config.ARGB_8888, false)
        }

        val mpImage = BitmapImageBuilder(bitmap).build()
        val result = getFaceLandmarker().detect(mpImage)
        val face = result.faceLandmarks().firstOrNull()
            ?: return mapOf(
                "source" to RUNTIME_SOURCE,
                "landmarks" to emptyList<Map<String, Double>>(),
                "warnings" to listOf("Face landmarker task detected no face in the captured image."),
            )

        return mapOf(
            "source" to RUNTIME_SOURCE,
            "landmarks" to face.map(::serializeLandmark),
            "warnings" to emptyList<String>(),
        )
    }

    @Synchronized
    fun close() {
        faceLandmarker?.close()
        faceLandmarker = null
    }

    private fun loadModelBuffer(assetPath: String): ByteBuffer {
        val bytes = context.assets.open(assetPath).use { input ->
            input.readBytes()
        }
        return ByteBuffer.allocateDirect(bytes.size)
            .order(ByteOrder.nativeOrder())
            .put(bytes)
            .also { it.rewind() }
    }

    private fun serializeLandmark(landmark: NormalizedLandmark): Map<String, Double> {
        return mapOf(
            "x" to landmark.x().toDouble(),
            "y" to landmark.y().toDouble(),
            "z" to landmark.z().toDouble(),
        )
    }

    companion object {
        private const val MODEL_ASSET_PATH = "flutter_assets/assets/models/face_landmarker.task"
        private const val RUNTIME_SOURCE = "mediapipe_face_landmarker_task"
    }
}
