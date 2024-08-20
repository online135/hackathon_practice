import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

class SecondPage extends StatefulWidget {
  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? cameras;

  @override
  void initState() {
    super.initState();
    _setupCameras();
  }

  Future<void> _setupCameras() async {
    // 获取可用的摄像头
    cameras = await availableCameras();
  }

  Future<void> _takePicture() async {
    // 初始化控制器
    if (_controller == null) {
      _controller = CameraController(cameras![0], ResolutionPreset.high);
      _initializeControllerFuture = _controller!.initialize();
    }

    try {
      await _initializeControllerFuture;

      // 拍照并获取图片路径
      final image = await _controller!.takePicture();
      if (mounted) {
        // 跳转到显示图片页面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DisplayPictureScreen(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Second Page - Camera'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _takePicture,
          child: Text('Open Camera'),
        ),
      ),
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  DisplayPictureScreen({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Display Picture')),
      body: Image.file(File(imagePath)),
    );
  }
}
