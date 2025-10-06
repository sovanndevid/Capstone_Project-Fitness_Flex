import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class FormCheckCameraPage extends StatefulWidget {
  const FormCheckCameraPage({super.key, required this.cameras});
  final List<CameraDescription> cameras;

  @override
  State<FormCheckCameraPage> createState() => _FormCheckCameraPageState();
}

class _FormCheckCameraPageState extends State<FormCheckCameraPage> {
  CameraController? _controller;
  bool _ready = false;
  bool _capturing = false;
  XFile? _lastCapture;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.cameras.isEmpty) return;
    final cam = widget.cameras.first;
    final controller = CameraController(cam, ResolutionPreset.medium, enableAudio: false);
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera init failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (!_ready || _capturing) return;
    setState(() => _capturing = true);
    try {
      final shot = await _controller!.takePicture();
      if (!mounted) return;
      setState(() => _lastCapture = shot);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Captured: ${shot.name}')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = !_ready
        ? const Center(child: CircularProgressIndicator())
        : CameraPreview(_controller!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Check'),
        actions: [
          if (_lastCapture != null)
            IconButton(
              tooltip: 'Last Capture',
              icon: const Icon(Icons.image),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AspectRatio(
                          aspectRatio: 9 / 16,
                          child: Image.file(
                            // ignore: deprecated_member_use
                            File(_lastCapture!.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: preview),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: FloatingActionButton.large(
                onPressed: _capture,
                child: _capturing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.fiber_manual_record, size: 40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}