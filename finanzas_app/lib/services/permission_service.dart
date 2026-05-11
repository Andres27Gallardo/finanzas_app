import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // ✅ Pide todos los permisos necesarios al iniciar
  static Future<void> requestAll() async {
    await [
      Permission.microphone,
      Permission.camera,
      Permission.location,
      Permission.notification,
      Permission.storage,
    ].request();
  }

  static Future<bool> hasMicrophone() async =>
      await Permission.microphone.isGranted;

  static Future<bool> hasCamera() async =>
      await Permission.camera.isGranted;

  // ✅ Solicita micrófono y muestra diálogo si denegado permanentemente
  static Future<bool> requestMicrophone(BuildContext context) async {
    var status = await Permission.microphone.status;

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      // Mostrar diálogo para ir a configuración
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Permiso de Micrófono'),
            content: const Text(
              'Para usar el reconocimiento de voz necesitas activar el permiso de micrófono.\n\n'
              'Ve a Configuración > Aplicaciones > Finanzas IA > Permisos > Micrófono',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await openAppSettings();
                },
                child: const Text('Ir a Configuración'),
              ),
            ],
          ),
        );
      }
      return false;
    }

    status = await Permission.microphone.request();
    return status.isGranted;
  }

  // ✅ Solicita cámara y muestra diálogo si denegado permanentemente
  static Future<bool> requestCamera(BuildContext context) async {
    var status = await Permission.camera.status;

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Permiso de Cámara'),
            content: const Text(
              'Para escanear recibos necesitas activar el permiso de cámara.\n\n'
              'Ve a Configuración > Aplicaciones > Finanzas IA > Permisos > Cámara',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await openAppSettings();
                },
                child: const Text('Ir a Configuración'),
              ),
            ],
          ),
        );
      }
      return false;
    }

    status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<void> openSettings() async => await openAppSettings();
}
