import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img; // Correct import for image processing
import '../../config/app_config.dart';

class FaceRecognitionScreen extends StatefulWidget {
  final bool isCheckIn;
  final Function(int userId, String username) onFaceRecognized;
  final Function() onCancel;

  const FaceRecognitionScreen({
    Key? key,
    required this.isCheckIn,
    required this.onFaceRecognized,
    required this.onCancel,
  }) : super(key: key);

  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  String status = "Ready to scan";
  bool isLoading = false;
  bool needsRegistration = false;
  TextEditingController usernameController = TextEditingController();
  final String faceRecognitionUrl =
      "http://192.168.53.175:5000"; // Update with actual IP

  @override
  void initState() {
    super.initState();
    // Small delay to ensure camera availability before starting
    Future.delayed(Duration(milliseconds: 500), () {
      _startFaceRecognition();
    });
  }

  Future<void> _startFaceRecognition() async {
    setState(() {
      isLoading = true;
      status = "Starting camera...";
    });

    // Ensure we're using the front camera
    await Future.delayed(Duration(seconds: 1)); // Give UI time to update
    await pickAndSendImage();
  }

  Future<void> pickAndSendImage() async {
    setState(() {
      isLoading = true;
      status = "Opening camera...";
    });

    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front, // Force front camera
        imageQuality: 80, // Increase quality (was 50)
        maxWidth: 800, // Increase size (was 600)
        maxHeight: 1000, // Increase size (was 800)
      );

      if (pickedFile == null) {
        setState(() {
          status = "Cancelled";
          isLoading = false;
        });
        widget.onCancel();
        return;
      }

      setState(() {
        status = "Processing image...";
      });

      // Enhance image processing
      File imageFile = File(pickedFile.path);

      // Add pre-processing to improve face detection
      final bytes = await imageFile.readAsBytes();
      final img.Image? decodedImage = img.decodeImage(bytes);

      if (decodedImage != null) {
        // Process the image to improve face detection
        final img.Image processedImg = img.copyResize(decodedImage, width: 800);

        // Add brightness and contrast adjustment
        final img.Image enhancedImg = img.adjustColor(
          processedImg,
          brightness: 0.05,
          contrast: 0.1,
        );

        // Save processed image
        final File processedFile = File('${pickedFile.path}_processed.jpg');
        await processedFile
            .writeAsBytes(img.encodeJpg(enhancedImg, quality: 90));

        // Use the processed image for recognition
        final processedBytes = await processedFile.readAsBytes();
        final base64Image = base64Encode(processedBytes);

        print("Sending image data of length: ${base64Image.length}");

        // Add a timeout to avoid hanging indefinitely
        final response = await http
            .post(
              Uri.parse("${AppConfig.faceRecognizeEndpoint}"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"image": base64Image}),
            )
            .timeout(Duration(seconds: 30));

        print("Response status code: ${response.statusCode}");
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("Response data: ${response.body}");

          if (data['status'] == 'success' && data['recognized'] == true) {
            // Face recognized
            setState(() {
              status = "Face recognized! Welcome ${data['username']}";
              isLoading = false;
            });

            // Call the callback with the user information
            widget.onFaceRecognized(
                int.parse(data['userId']), data['username']);
          } else {
            // Face not recognized, need to register
            setState(() {
              status = "Face not recognized. Please register.";
              needsRegistration = true;
              isLoading = false;
            });
          }
        } else {
          setState(() {
            status =
                "Recognition failed: ${response.statusCode}\n${response.body}";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          status = "Error: Could not decode image";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        status = "Error: $e";
        isLoading = false;
      });
    }
  }

  Future<void> registerFace() async {
    if (usernameController.text.isEmpty) {
      setState(() {
        status = "Username is required";
      });
      return;
    }

    setState(() {
      isLoading = true;
      status = "Opening camera for registration...";
    });

    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80, // Higher quality for registration
      );

      if (pickedFile == null) {
        setState(() {
          status = "Registration cancelled";
          isLoading = false;
        });
        return;
      }

      setState(() {
        status = "Processing registration...";
      });

      // First, create a user in the backend
      final createUserResponse = await http.post(
        Uri.parse("${AppConfig.apiBaseUrl}/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": usernameController.text,
          "password": "default123" // You might want a better approach here
        }),
      );

      if (createUserResponse.statusCode != 200) {
        setState(() {
          status = "Failed to create user account";
          isLoading = false;
        });
        return;
      }

      final userData = jsonDecode(createUserResponse.body);
      final userId = userData['id'];

      // Now register the face - with enhanced image processing
      File imageFile = File(pickedFile.path);
      final bytes = await imageFile.readAsBytes();

      // Process the image to improve face detection for registration
      final img.Image? decodedImage = img.decodeImage(bytes);

      if (decodedImage != null) {
        final img.Image processedImg = img.copyResize(decodedImage, width: 800);
        final img.Image enhancedImg = img.adjustColor(
          processedImg,
          brightness: 0.05,
          contrast: 0.1,
        );

        final List<int> processedBytes =
            img.encodeJpg(enhancedImg, quality: 90);
        final String base64Image = base64Encode(processedBytes);

        final registerResponse = await http.post(
          Uri.parse("$faceRecognitionUrl/register"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "image": base64Image,
            "userId": userId.toString(),
            "username": usernameController.text
          }),
        );

        if (registerResponse.statusCode == 200) {
          setState(() {
            status = "Face registered successfully!";
            needsRegistration = false;
            isLoading = false;
          });

          // Call the callback with the new user information
          widget.onFaceRecognized(userId, usernameController.text);
        } else {
          setState(() {
            status = "Registration failed: ${registerResponse.statusCode}";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          status = "Error: Could not decode image for registration";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        status = "Error: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCheckIn
            ? "Face Recognition - Check In"
            : "Face Recognition - Check Out"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: widget.onCancel,
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/3D background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                color: Colors.black.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.face,
                        size: 80,
                        color: Colors.white,
                      ),
                      SizedBox(height: 20),
                      Text(
                        status,
                        style: TextStyle(fontSize: 18, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30),
                      if (isLoading)
                        CircularProgressIndicator(color: Colors.white)
                      else if (needsRegistration)
                        Column(
                          children: [
                            TextField(
                              controller: usernameController,
                              decoration: InputDecoration(
                                labelText: "Enter your username",
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: registerFace,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                "Register Face",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        )
                      else
                        ElevatedButton(
                          onPressed: _startFaceRecognition,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            "Try Again",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
