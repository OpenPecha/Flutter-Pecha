## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## flutter_local_notifications
-keep class com.dexterous.** { *; }

## Auth0
-keep class com.auth0.** { *; }
-keep class com.auth0.android.** { *; }
-keep class com.auth0.android.provider.** { *; }
-keep class com.auth0.android.authentication.** { *; }
-keep class com.auth0.android.management.** { *; }
-keep class com.auth0.android.result.** { *; }
-keep class com.auth0.android.request.** { *; }
-dontwarn com.auth0.**

## Auth0 JWT (for token parsing)
-keep class com.auth0.android.jwt.** { *; }
-keep class com.auth0.jwt.** { *; }

## Gson (used by Auth0 for JSON)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

## OkHttp (used by Auth0 for network requests)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

## Keep Credentials and UserProfile classes (Auth0 result objects)
-keep class com.auth0.android.result.Credentials { *; }
-keep class com.auth0.android.result.UserProfile { *; }

## Prevent stripping of WebAuth callback handling
-keep class com.auth0.android.provider.WebAuthProvider { *; }
-keep class com.auth0.android.provider.WebAuthProvider$* { *; }
-keep class com.auth0.android.provider.AuthCallback { *; }
-keep class com.auth0.android.provider.CustomTabsOptions { *; }

## Keep Auth0 State and PKCE classes (prevents state mismatch)
-keep class com.auth0.android.provider.AuthenticationActivity { *; }
-keep class com.auth0.android.provider.AuthenticationActivity$* { *; }
-keep class com.auth0.android.authentication.storage.** { *; }
-keep class com.auth0.android.provider.PKCE { *; }

## Keep all fields that might store state
-keepclassmembers class com.auth0.android.provider.** {
    private <fields>;
}

## Google Play Core (referenced by Flutter for deferred components)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task



