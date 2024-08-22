import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

class SecondPage extends StatefulWidget {
  const SecondPage({super.key});

  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? cameras;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _setupCameras();
  }

  Future<void> _setupCameras() async {
    // 获取可用的摄像头
    cameras = await availableCameras();
  }

  Future<void> _initializeCamera() async {
    if (cameras != null && cameras!.isNotEmpty) {
      _controller = CameraController(cameras![0], ResolutionPreset.high);
      _initializeControllerFuture = _controller!.initialize();
      setState(() {});
    }
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      setState(() {
        _imagePath = image.path;
      });
    } catch (e) {
      print(e);
    }
  }

  // Future<void> _takePicture() async {
  //   try {
  //     await _initializeControllerFuture;

  //     // 拍照並獲取圖片路徑
  //     final image = await _controller!.takePicture();
  //     if (mounted) {
  //       // 跳轉到顯示頁面
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => DisplayPictureScreen(imagePath: image.path),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Page - Camera'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _imagePath != null
                ? Image.file(File(_imagePath!))
                : _controller == null
                    ? Center(
                        child: GestureDetector(
                          onTap: _initializeCamera,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 100),
                          ),
                        ),
                      )
                    : FutureBuilder<void>(
                        future: _initializeControllerFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done) {
                            return CameraPreview(_controller!);
                          } else {
                            return const Center(child: CircularProgressIndicator());
                          }
                        },
                      ),
          ),
          _controller != null && _imagePath == null
              ? ElevatedButton(
                  onPressed: _takePicture,
                  child: const Text('Take Picture'),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }


  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('Second Page - Camera'),
  //     ),
  //     body: Column(
  //       children: [
  //         // Display the camera preview
  //         Expanded(
  //           child: _controller == null
  //               ? const Center(child: CircularProgressIndicator())
  //               : FutureBuilder<void>(
  //                   future: _initializeControllerFuture,
  //                   builder: (context, snapshot) {
  //                     if (snapshot.connectionState == ConnectionState.done) {
  //                       return CameraPreview(_controller!);
  //                     } else {
  //                       return const Center(child: CircularProgressIndicator());
  //                     }
  //                   },
  //                 ),
  //         ),
  //         ElevatedButton(
  //           onPressed: _takePicture,
  //           child: const Text('Take Picture'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

// class DisplayPictureScreen extends StatelessWidget {
//   final String imagePath;

//   const DisplayPictureScreen({super.key, required this.imagePath});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Display Picture')),
//       body: Image.file(File(imagePath)),
//     );
//   }
// }