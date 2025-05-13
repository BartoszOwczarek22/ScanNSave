import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scan_n_save/providers/camera_providers.dart';

class CameraPage extends ConsumerStatefulWidget {
  CameraPage({super.key}) {}

  @override
  ConsumerState<CameraPage> createState() => CameraPageState();
}

class CameraPageState extends ConsumerState<CameraPage> {
  @override
  void initState() {}

  @override
  Widget build(BuildContext context) {
    final cameraControllerAsync = ref.watch(cameraControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: cameraControllerAsync.when(
        data: (controller) {
          if (!controller.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CameraPreview(controller),
              Center(
                child: ElevatedButton(
                    onPressed: () async {
                      final controllerNotifier = ref.read(
                        cameraControllerProvider.notifier,
                      );
                      final picture = await controllerNotifier.Capture();

                      if (picture != null && context.mounted) {}
                    },
                    child: const Text('Zrób zdjęcie'),
                  ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Błąd: $error')),
      ),
    );
  }
}
