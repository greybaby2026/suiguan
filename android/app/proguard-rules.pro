-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.baseflow.permissionhandler.** { *; }
-keep class dev.babu.mobile_scanner.** { *; }
-keep class com.openfilex.** { *; }

-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes RuntimeVisibleAnnotations
-keepattributes EnclosingMethod

-dontwarn io.flutter.**
-dontwarn com.dexterous.flutterlocalnotifications.**
-dontwarn com.baseflow.permissionhandler.**

-keepclassmembers class * {
    public <init>(...);
}

-keep class * extends java.lang.reflect.** { *; }
