import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isCameraOn = false;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsAndInitialize() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      await _initializeCamera();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('需要相机权限')));
    }
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('未检测到可用摄像头')));
      return;
    }

    _controller = CameraController(
      _cameras![0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      _showError('无法初始化摄像头: $e');
    }
  }

  void _toggleCamera() async {
    try {
      if (_isCameraOn) {
        await _controller!.pausePreview();
      } else {
        if (!_isCameraInitialized) {
          await _checkPermissionsAndInitialize();
        } else {
          await _controller!.initialize();
          await _controller!.resumePreview();
        }
      }
      setState(() {
        _isCameraOn = !_isCameraOn;
      });
    } catch (e) {
      _showError('操作摄像头失败: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('摄像头控制')),
      body: Column(
        children: [
          Expanded(
            child:
                _isCameraInitialized
                    ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: CameraPreview(_controller!),
                    )
                    : const Center(child: null),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _toggleCamera,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCameraOn ? Colors.red : Colors.green,
                  ),
                  child: Text(_isCameraOn ? '关闭摄像头' : '开启摄像头'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
