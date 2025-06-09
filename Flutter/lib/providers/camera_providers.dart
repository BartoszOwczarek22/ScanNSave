import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cameraControllerProvider =
    AsyncNotifierProvider<CameraControllerNotifier, CameraState>(
  CameraControllerNotifier.new,
);

class CameraControllerNotifier extends AsyncNotifier<CameraState> {

  @override
  Future<CameraState> build() async {
    // Inicjalizacja dostępnych kamer
    final cameras = await availableCameras();
    final camera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.back);

    // Tworzymy kontroler
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await controller.initialize();

    return CameraState(controller: controller);
  }

  Future<XFile?> Capture() async {

    final controller = state.valueOrNull?.controller;

    if (controller == null) {
      return null;
    }
    state = AsyncData(state.value!.copyWith(isTakingPhoto: true));
    try {
      final picture = await controller.takePicture();
      return picture;
    } catch (e) {
      debugPrint('Błąd przy robieniu zdjęcia: $e');
      return null;
    } finally {
      state = AsyncData(state.value!.copyWith(isTakingPhoto: false));
    }
  }

  @override
  Future<void> dispose() async {
    final controller = state.valueOrNull?.controller;
    if (controller != null) {
      await controller.dispose();
    }
  }
}

class CameraState {
  final CameraController? controller;
  final bool isTakingPhoto;

  CameraState({
    required this.controller,
    this.isTakingPhoto = false,
  });

  CameraState copyWith({
    CameraController? controller,
    bool? isTakingPhoto,
  }) {
    return CameraState(
      controller: controller ?? this.controller,
      isTakingPhoto: isTakingPhoto ?? this.isTakingPhoto,
    );
  }
}