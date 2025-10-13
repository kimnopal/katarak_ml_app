# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.nnapi.** { *; }
-keep class org.tensorflow.lite.support.** { *; }

# Hindari optimisasi refleksi
-dontwarn org.tensorflow.lite.**
-dontwarn org.tensorflow.lite.gpu.**
-dontwarn org.tensorflow.lite.nnapi.**
-dontwarn org.tensorflow.lite.support.**
