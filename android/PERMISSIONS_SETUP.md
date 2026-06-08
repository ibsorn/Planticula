# Configuración de Permisos Android para Planticula

Este documento describe los permisos necesarios para la funcionalidad de análisis de sustrato con cámara y galería.

## Permisos Requeridos

Agrega estos permisos al archivo `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Permisos para Cámara -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />

    <!-- Permisos para Lectura de Almacenamiento (Galería) -->
    <!-- Android 13+ (API 33+) -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

    <!-- Android 12 y anteriores -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />

    <!-- Permisos de Internet (ya existente para Supabase) -->
    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:label="planticula"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- Activity principal -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"
                />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

## Explicación de Permisos

### Cámara
- `CAMERA`: Permite acceder a la cámara del dispositivo
- `hardware.camera`: Declara que la app puede usar cámara (pero no es requerida - funciona en tablets sin cámara)
- `hardware.camera.autofocus`: Mejora la calidad de fotos de sustrato

### Almacenamiento (Galería)
- `READ_MEDIA_IMAGES` (Android 13+): Nuevo permiso específico para imágenes
- `READ_EXTERNAL_STORAGE` (Android 12 y menor): Permiso general de lectura
- `WRITE_EXTERNAL_STORAGE`: Solo necesario hasta Android 9 (API 28) para guardar fotos

## Manejo de Permisos en Runtime

La librería `image_picker` ya maneja la solicitud de permisos en runtime, pero si necesitas verificar manualmente:

```dart
import 'package:permission_handler/permission_handler.dart';

// Verificar permiso de cámara
var status = await Permission.camera.status;
if (status.isDenied) {
  status = await Permission.camera.request();
}

// Verificar permiso de galería (Android 13+)
var photosStatus = await Permission.photos.status;
if (photosStatus.isDenied) {
  photosStatus = await Permission.photos.request();
}
```

## Dependencia Opcional (permission_handler)

Si necesitas manejo avanzado de permisos, agrega a `pubspec.yaml`:

```yaml
dependencies:
  permission_handler: ^11.0.1
```

## ProGuard (solo release builds)

Si usas ProGuard, agrega al `android/app/proguard-rules.pro`:

```
# image_picker
-keep class io.flutter.plugins.imagepicker.** { *; }
```

## Notas sobre Android 13+ (API 33)

En Android 13+, Google cambió el modelo de permisos:
- `READ_MEDIA_IMAGES`: Permiso específico para imágenes
- `READ_MEDIA_VIDEO`: Para videos (no usado en Planticula)
- `READ_MEDIA_AUDIO`: Para audio (no usado en Planticula)

La app seguirá funcionando en versiones antiguas con `READ_EXTERNAL_STORAGE`.

## Troubleshooting

### "Camera permission denied"
Asegúrate de que el permiso `CAMERA` está en AndroidManifest.xml y el usuario lo aceptó.

### "Cannot access gallery"
- Android 13+: Verifica que usas `READ_MEDIA_IMAGES`
- Android 12 y menor: Verifica `READ_EXTERNAL_STORAGE`
- Asegúrate de solicitar permisos en runtime

### La imagen no se muestra después de capturar
Algunos dispositivos necesitan:
```xml
<application
    android:requestLegacyExternalStorage="true"
    ... >
```
Agrega esto para Android 10 (API 29) si tienes problemas.
