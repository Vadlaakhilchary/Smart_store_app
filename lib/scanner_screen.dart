import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'database_service.dart'; //

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
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
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller?.initialize();

    _controller?.startImageStream((CameraImage image) {
      if (!_isProcessing) {
        _processCameraImage(image);
      }
    });

    if (mounted) setState(() {});
  }

  Future<void> _processCameraImage(CameraImage image) async {
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image); //
      if (inputImage == null) return;

      final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        final String code = barcodes.first.rawValue ?? "Unknown";
        print("Found Barcode: $code");

        // Stop scanning temporarily
        await _controller?.stopImageStream();

        // MEMBER B LOGIC: Fetch product from Firebase
        final productData = await DatabaseService().getProductByBarcode(code);

        if (!mounted) return;

        if (productData != null) {
          _showResult(productData['name'], productData['price']);
        } else {
          _showError("Product $code not found.");
        }
      }
    } catch (e) {
      print("Error scanning: $e");
    } finally {
      _isProcessing = false;
    }
  }

  // Conversion logic required for ML Kit to read camera data
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final sensorOrientation = _controller!.description.sensorOrientation;
    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotationValue.fromRawValue(sensorOrientation) 
                  ?? InputImageRotation.rotation0deg,
        format: inputImageFormat,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _showResult(String name, dynamic price) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Found: $name - ₹$price"),
        backgroundColor: Colors.green, //
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Product")),
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}