########################################################
# ✅ TensorFlow Lite GPU Delegate 관련 보존 규칙
########################################################
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.nnapi.** { *; }
-keep class org.tensorflow.lite.support.** { *; }
-keep class org.tensorflow.lite.task.** { *; }

# JNI 로드 관련
-keepclassmembers class * {
    native <methods>;
}

# 경고 무시
-dontwarn org.tensorflow.lite.**

########################################################
# ✅ Flutter Camera Preview 관련 보존 규칙
########################################################
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.plugins.camera.** { *; }
-keep class android.view.TextureView { *; }
-keep class android.graphics.SurfaceTexture { *; }

-dontwarn io.flutter.plugins.camera.**
-dontwarn android.view.TextureView

########################################################
# ✅ Flutter Deferred Components (Play Store Dynamic Feature) 보존 규칙
########################################################
# Play Core SplitInstallManager 및 관련 클래스 보존
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep interface com.google.android.play.core.splitinstall.** { *; }
-dontwarn com.google.android.play.core.splitinstall.**

# Play Core Task API 보존
-keep class com.google.android.play.core.tasks.** { *; }
-keep interface com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.tasks.**

########################################################
# ✅ 추가 권장: CameraX 및 Android Camera2 관련 클래스 보존
########################################################
-keep class androidx.camera.** { *; }
-keep class android.hardware.camera2.** { *; }
-dontwarn androidx.camera.**
-dontwarn android.hardware.camera2.**

########################################################
# ✅ Flutter 엔진 관련 핵심 클래스 보존 (안정성)
########################################################
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
