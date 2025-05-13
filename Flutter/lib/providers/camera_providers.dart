import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cameraControllerProvider =
    AsyncNotifierProvider<CameraControllerNotifier, CameraController>(
  CameraControllerNotifier.new,
);

class CameraControllerNotifier extends AsyncNotifier<CameraController> {
  CameraController? controller;
  @override
  Future<CameraController> build() async {
    // Inicjalizacja dostępnych kamer
    final cameras = await availableCameras();
    final camera = cameras.last;

    // Tworzymy kontroler
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await controller.initialize();

    return controller;
  }

  Future<XFile?> Capture() async {
    final controller = state.valueOrNull;

    if (controller == null || !controller.value.isInitialized || controller.value.isTakingPicture) {
      return null;
    }

    try {
      final picture = await controller.takePicture();
      return picture;
    } catch (e) {
      debugPrint('Błąd przy robieniu zdjęcia: $e');
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    final controller = state.valueOrNull;
    if (controller != null) {
      await controller.dispose();
    }
  }
}