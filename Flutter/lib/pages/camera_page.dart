import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scan_n_save/pages/receipt_details_page.dart';
import 'package:scan_n_save/providers/camera_providers.dart';

class CameraPage extends ConsumerStatefulWidget {
  CameraPage({super.key}) {}

  @override
  ConsumerState<CameraPage> createState() => CameraPageState();
}

class CameraPageState extends ConsumerState<CameraPage> {
  @override
  Widget build(BuildContext context) {
    final cameraControllerAsync = ref.watch(cameraControllerProvider);
    final baseSize = MediaQuery.of(context).size.shortestSide;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: cameraControllerAsync.when(
        data: (camState) {
          if (!(camState.controller?.value.isInitialized ?? true)) {
            return const Center(child: CircularProgressIndicator());
          }
          return SizedBox.expand(
            child: Stack(
              children: [
                CameraPreview(camState.controller!),
                Positioned(
                  bottom: 15,
                  left: 0,
                  right: 0,
                  child:
                      camState.isTakingPhoto
                          ? SizedBox(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned(
                                  child: SizedBox(
                                    width: baseSize * 0.15,
                                    height: baseSize * 0.15,
                                    child: CircularProgressIndicator(
                                      value: null,
                                      color: Colors.white,
                                      strokeWidth: 5,
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : GestureDetector(
                            onTap: () {
                              ref
                                  .read(cameraControllerProvider.notifier)
                                  .Capture()
                                  .then((value) {
                                    if (value != null) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  ReceiptScanningPage(
                                                    recieptImagePath:
                                                        value.path,
                                                  ),
                                        ),
                                      );
                                    }
                                  });
                            },
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 5,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Błąd: $error')),
      ),
    );
  }
}
