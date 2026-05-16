# حماية مكتبة TensorFlow Lite من الحذف
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }

# منع حذف الكلاسات اللي اشتكى منها الإيرور
-dontwarn org.tensorflow.lite.gpu.**
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }