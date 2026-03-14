import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cuickdevuser/main.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';


class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key});

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    
  }

  Future<void> _initCamera() async {
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium, // 🔥 SAFE
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;

    if (state == AppLifecycleState.paused) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  // 🔥 COMPRESS TO 50 KB
  Future<File?> _compressToKB(File file) async {
    final dir = await getTemporaryDirectory();
    String targetPath =
        '${dir.path}/cmp_${DateTime.now().millisecondsSinceEpoch}.jpg';

    int quality = 70;
    File? result;

    do {
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 400,
        minHeight: 600,
        format: CompressFormat.jpeg,
      );

      if (compressed == null) return null;

      result = File(compressed.path);
      quality -= 7;
    } while (result.lengthSync() > 50 * 1024 && quality > 10);

    return result;
  }

  // 📸 CAPTURE
  Future<void> _capture() async {
    final XFile xfile = await _controller!.takePicture();
    File original = File(xfile.path);

    File? compressed = await _compressToKB(original);
    if (compressed == null || !mounted) return;

    Navigator.pop(context, compressed.path); // 🔥 RETURN PATH
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 620,
                    child: CameraPreview(_controller!),
                  ),
                  const SizedBox(height: 10),
                  
                  SafeArea(
                    child: GestureDetector(
                        onTap: _capture,
                        child: Container(
                          width: 75,
                          height: 75,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.black, size: 32),
                        ),
                      ),
                  ),
                
                ],
              ),
          ),
    );
  }
}
