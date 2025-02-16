import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Deepfake Detector',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Color(0xFF1E1E1E),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      home: VideoUploadScreen(),
    );
  }
}

class VideoUploadScreen extends StatefulWidget {
  @override
  _VideoUploadScreenState createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  File? _video;
  String _result = "";
  bool _isLoading = false;

  // Pick video from gallery
  Future<void> _pickVideo() async {
    final pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _video = File(pickedFile.path);
        _result = "";
      });
    }
  }

  // Upload & analyze the video
  Future<void> _uploadVideo() async {
    if (_video == null) {
      _showSnackbar("Please select a video first!");
      return;
    }

    setState(() {
      _isLoading = true;
      _result = "";
    });

    var request = http.MultipartRequest(
      'POST', Uri.parse('http://your-api-endpoint.com/detect')
    );
    request.files.add(await http.MultipartFile.fromPath('video', _video!.path));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        setState(() {
          _result = responseBody.contains('FAKE') ? "⚠️ Fake Video Detected" : "✅ Real Video";
        });
        _showSnackbar(_result);
      } else {
        _showSnackbar("Error: Failed to process video.");
      }
    } catch (e) {
      _showSnackbar("Error: ${e.toString()}");
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Show snackbar message
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 16)),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Deepfake Detector", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video Preview Section
            Center(
              child: _video == null
                  ? Lottie.asset('assets/upload.json', width: 200, height: 200)
                  : Column(
                      children: [
                        Text("Selected Video", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _video!.path.split('/').last,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
            ),
            SizedBox(height: 20),

            // Pick Video Button
            ElevatedButton.icon(
              icon: Icon(Icons.video_library, size: 24),
              label: Text("Pick Video", style: TextStyle(fontSize: 18)),
              onPressed: _pickVideo,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),

            // Upload and Detect Button
            ElevatedButton.icon(
              icon: Icon(Icons.cloud_upload, size: 24),
              label: Text("Upload & Detect", style: TextStyle(fontSize: 18)),
              onPressed: _uploadVideo,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),

            // Result Display
            _isLoading
                ? Center(child: Lottie.asset('assets/loading.json', width: 100, height: 100))
                : _result.isNotEmpty
                    ? Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: _result.contains('FAKE') ? Colors.red.shade800 : Colors.green.shade800,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black45,
                              offset: Offset(2, 4),
                              blurRadius: 6,
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _result.contains('FAKE') ? Icons.warning : Icons.check_circle,
                              size: 28,
                              color: Colors.white,
                            ),
                            SizedBox(width: 10),
                            Text(
                              _result,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      )
                    : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
