# 🚀 CÓMO INSTALAR Y CORRER LA APP - GUÍA PASO A PASO

## ✅ PASO 1 — Instala Flutter (si no lo tienes)

1. Ve a: https://docs.flutter.dev/get-started/install
2. Descarga Flutter para Windows, Mac o Linux
3. Descomprime y agrega al PATH (sigue las instrucciones del sitio)
4. Abre una terminal y ejecuta:
   ```
   flutter doctor
   ```
   Deben aparecer ✓ en Flutter, Android toolchain y Connected device.

---

## ✅ PASO 2 — Instala Android Studio

1. Descarga: https://developer.android.com/studio
2. Instala y abre Android Studio
3. Ve a: Tools > Device Manager > Create Device
4. Selecciona: Pixel 6 > Android 14 > Finish
5. Presiona ▶ (Play) para iniciar el emulador

---

## ✅ PASO 3 — Copia el proyecto

Copia todos los archivos en una carpeta, por ejemplo:
```
C:\Proyectos\finanzas_app\
```

La estructura debe verse así:
```
finanzas_app/
├── pubspec.yaml
└── lib/
    ├── main.dart
    ├── models/
    ├── providers/
    ├── screens/
    ├── services/
    ├── theme/
    └── widgets/
```

---

## ✅ PASO 4 — Instala las dependencias

Abre la terminal en la carpeta del proyecto y ejecuta:
```
flutter pub get
```
Espera a que termine (puede tardar 1-2 minutos la primera vez).

---

## ✅ PASO 5 — Corre la app

Con el emulador abierto, ejecuta:
```
flutter run
```
¡La app se instalará y abrirá automáticamente! 🎉

---

## 🤖 PASO 6 (OPCIONAL) — Activar el Chatbot con IA

Para que el asistente IA funcione:

1. Ve a: https://aistudio.google.com/app/apikey
2. Inicia sesión con tu cuenta de Google
3. Clic en "Create API Key" → "Create API key in new project"
4. Copia la key (empieza con "AIza...")
5. Abre el archivo: `lib/services/gemini_service.dart`
6. Busca esta línea:
   ```
   static const String _apiKey = 'AQUI_VA_TU_API_KEY';
   ```
7. Reemplaza `AQUI_VA_TU_API_KEY` con tu key real:
   ```
   static const String _apiKey = 'AIzaSy...tuKey...';
   ```
8. Guarda y vuelve a correr: `flutter run`

⚠️ El chatbot funciona SIN key, pero muestra las instrucciones en lugar de responder IA.
Con key, el chatbot conoce tus datos reales y da consejos personalizados.

---

## 🛠️ COMANDOS ÚTILES

| Qué quieres hacer | Comando |
|---|---|
| Correr la app | `flutter run` |
| Ver cambios en tiempo real | La app se recarga automáticamente con "r" en terminal |
| Limpiar build | `flutter clean` |
| Actualizar dependencias | `flutter pub get` |
| Build APK (para instalar en celular) | `flutter build apk --release` |

---

## 📱 INSTALAR EN TU CELULAR ANDROID REAL

1. En tu celular: Ajustes > Opciones de desarrollador > Depuración USB ✓
2. Conecta con cable USB
3. Ejecuta: `flutter devices` — debe aparecer tu celular
4. Ejecuta: `flutter run`

O para APK:
```
flutter build apk --release
```
El APK estará en: `build/app/outputs/apk/release/app-release.apk`

---

## ❓ PROBLEMAS COMUNES

**Error: "No connected devices"**
→ Abre el emulador primero en Android Studio

**Error: "flutter not found"**
→ Flutter no está en el PATH. Reinstala siguiendo la guía oficial

**Error en pubspec.yaml**
→ Ejecuta `flutter clean` luego `flutter pub get`

**App lenta en emulador**
→ Normal. En celular real es mucho más rápida.

---

## 🎯 QUÉ PUEDES HACER EN LA APP

- ✅ Registrarte con email y contraseña
- ✅ Configurar tu perfil financiero
- ✅ Agregar ingresos, gastos y transferencias
- ✅ Ver gráficas por categoría y periodo
- ✅ Administrar cuentas bancarias
- ✅ Chatbot IA (con API Key de Gemini)
- ✅ Auto-completar transacciones con IA
- ✅ Modo oscuro
- ✅ Categorías personalizables con colores
- ✅ Eliminar transacciones deslizando
