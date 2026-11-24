import 'dart:io';

import 'package:camera/camera.dart';
import 'package:floodlight/screens/report/review_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialised = false;
  bool _isCameraLoading = false;
  String? _cameraError;
  XFile? _selectedPhoto;

  @override
  void initState() {
    super.initState();
    _initialiseCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initialiseCamera() async {
    if (_isCameraLoading) return;

    if (mounted) {
      setState(() {
        _isCameraLoading = true;
        _isCameraInitialised = false;
        _cameraError = null;
      });
    }

    await _cameraController?.dispose();
    _cameraController = null;

    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (!mounted) return;
        setState(() {
          _cameraError = status.isPermanentlyDenied
              ? 'Camera permission is disabled. Enable it in Settings.'
              : 'Camera permission was denied';
        });
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('NoCamera', 'No camera is available');
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraInitialised = controller.value.isInitialized;
      });
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraError =
            'Unable to access camera: ${error.description ?? error.code}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraError = 'Unable to initialise the camera: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _isCameraLoading = false);
      }
    }
  }

  Future<void> _takePicture() async {
    final controller = _cameraController;
    if (!_isCameraInitialised ||
        controller == null ||
        controller.value.isTakingPicture) {
      return;
    }

    try {
      final photo = await controller.takePicture();
      if (!mounted) return;
      setState(() {
        _selectedPhoto = photo;
        _cameraError = null;
      });
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraError =
            'Unable to capture photo: ${error.description ?? error.code}';
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _selectedPhoto = pickedFile;
          _cameraError = null;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraError = 'Unable to pick image from gallery: $error';
      });
    }
  }

  void _clearSelectedPhoto() {
    setState(() {
      _selectedPhoto = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_selectedPhoto != null)
            Image.file(File(_selectedPhoto!.path), fit: BoxFit.cover)
          else if (_isCameraInitialised)
            CameraPreview(_cameraController!)
          else
            Center(
              child: _cameraError == null
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _cameraError!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        TextButton(
                          onPressed: _isCameraLoading
                              ? null
                              : _initialiseCamera,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                  right: 15,
                  left: 15,
                  bottom: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close),
                    ),
                    Text(
                      _selectedPhoto != null ? 'Selected Photo' : 'Snapshot',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    if (_selectedPhoto != null)
                      IconButton(
                        tooltip: 'Retake / Choose another',
                        onPressed: _clearSelectedPhoto,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.refresh),
                      )
                    else
                      IconButton(
                        onPressed: () {},
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.location_off_outlined),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(
                        Icons.photo_outlined,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: _takePicture,
                      icon: const Icon(
                        Icons.circle_outlined,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: _selectedPhoto == null
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ReviewScreen(photo: _selectedPhoto!),
                                ),
                              );
                            },
                      icon: Icon(
                        Icons.check_circle_outline_outlined,
                        size: 30,
                        color: _selectedPhoto == null
                            ? Colors.grey
                            : Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
