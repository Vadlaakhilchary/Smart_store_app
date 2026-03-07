import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class ScannerScreen extends StatefulWidget {
  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  bool _isProcessing = false;
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller?.initialize();

    // Start the live stream of images
    _controller?.startImageStream((CameraImage image) {
      if (!_isProcessing) {
        _processCameraImage(image);
      }
    });

    setState(() {});
  }

  Future<void> _processCameraImage(CameraImage image) async {
    _isProcessing = true;

    try {
      // Convert CameraImage to InputImage (Required for ML Kit)
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      // Look for barcodes
      final List<Barcode> barcodes =
          await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        final String code = barcodes.first.rawValue ?? "Unknown";
        print("Found Barcode: $code");

        // Stop scanning once we find one to avoid multiple triggers
        _controller?.stopImageStream();

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Scanned: $code")),
        );
      }
    } catch (e) {
      print("Error scanning: $e");
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text("Scan Product")),
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Center(
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(border: Border.all(color: Colors.green, width: 3)),
            ),
          ),
        ],
      ),
    );
  }
}