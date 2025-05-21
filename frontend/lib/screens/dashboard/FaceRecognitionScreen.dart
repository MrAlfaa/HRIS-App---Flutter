import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img; // Correct import for image processing
import '../../config/app_config.dart';
import '../../services/location_service.dart';
import '../../services/session_manager.dart'; // Add this import

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
  bool hasError = false;
  String errorMessage = "";
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController =
      TextEditingController(); // For new users only
  bool showPasswordField = false; // Control visibility of password field
  LocationData? locationData;
  File? capturedImageFile; // Store the captured image file
  String? loggedInUserId; // Track currently logged-in user

  @override
  void initState() {
    super.initState();
    // Check for logged-in user first
    _checkLoggedInUser();
    // Get location when screen loads
    _getLocation();
    // Small delay to ensure camera availability before starting
    Future.delayed(Duration(milliseconds: 500), () {
      _startFaceRecognition();
    });
  }

  Future<void> _checkLoggedInUser() async {
    bool isLoggedIn = await SessionManager.isLoggedIn();
    if (isLoggedIn) {
      loggedInUserId = await SessionManager.getUserId();
      String? username = await SessionManager.getUsername();
      usernameController.text = username ?? '';

      print("User already logged in: $username (ID: $loggedInUserId)");
    } else {
      print("No user logged in");
    }
  }

  Future<void> _getLocation() async {
    setState(() {
      status = "Getting location...";
    });

    try {
      locationData = await LocationService.getCurrentLocation(context);
      if (locationData != null) {
        setState(() {
          status = "Location obtained. Ready to scan.";
        });
      } else {
        setState(() {
          status = "Location unavailable. You can still continue.";
        });
      }
    } catch (e) {
      print("Error getting location: $e");
      setState(() {
        status = "Location error. You can still continue.";
      });
    }
  }

  Future<void> _startFaceRecognition() async {
    setState(() {
      isLoading = true;
      status = "Starting camera...";
      hasError = false;
      errorMessage = "";
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
      // First display guidance to the user
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Face Capture Tips"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.face, size: 50, color: Colors.blue),
                SizedBox(height: 10),
                Text("For best results:"),
                SizedBox(height: 5),
                Text("• Position your face in the center"),
                Text("• Ensure good lighting"),
                Text("• Keep a neutral expression"),
                Text("• Remove glasses if possible"),
                Text("• Look directly at the camera"),
              ],
            ),
            actions: [
              TextButton(
                child: Text("OK, I'm Ready"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );

      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 90,
        maxWidth: 1000,
        maxHeight: 1200,
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

      // Store the captured image file
      capturedImageFile = File(pickedFile.path);

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
        try {
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
              // Face not recognized, check if user is already logged in
              bool isLoggedIn = await SessionManager.isLoggedIn();

              setState(() {
                status = isLoggedIn
                    ? "Face not recognized. We'll register your face for your account."
                    : "Face not recognized. Please enter your username to register.";
                needsRegistration = true;
                isLoading = false;
                showPasswordField =
                    !isLoggedIn; // Only show password if not logged in
              });

              // If user is logged in, pre-fill their username and disable the field
              if (isLoggedIn) {
                String? username = await SessionManager.getUsername();
                setState(() {
                  usernameController.text = username ?? '';
                });
              }
            }
          } else {
            setState(() {
              status =
                  "Recognition failed: ${response.statusCode}\n${response.body}";
              hasError = true;
              errorMessage = "Server error: ${response.statusCode}";
              isLoading = false;
            });
          }
        } catch (e) {
          setState(() {
            status = "Connection error: $e";
            hasError = true;
            errorMessage = "Connection error: Please check your network";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          status = "Error: Could not decode image";
          hasError = true;
          errorMessage = "Image processing error";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        status = "Error: $e";
        hasError = true;
        errorMessage = "Camera error: $e";
        isLoading = false;
      });
    }
  }

  Future<void> registerFace() async {
    if (usernameController.text.isEmpty) {
      setState(() {
        status = "Username is required";
        hasError = true;
        errorMessage = "Username is required";
      });
      return;
    }

    setState(() {
      isLoading = true;
      status = "Verifying username...";
      hasError = false;
      errorMessage = "";
    });

    try {
      // First, verify if username exists without requiring password
      final verifyResponse = await http.post(
        Uri.parse("${AppConfig.apiBaseUrl}/api/users/verify-username"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": usernameController.text}),
      );

      print("Username verification response: ${verifyResponse.statusCode}");
      print("Username verification body: ${verifyResponse.body}");

      if (verifyResponse.statusCode != 200) {
        setState(() {
          status = "Username not found";
          hasError = true;
          errorMessage = "This username doesn't exist in the system";
          isLoading = false;
        });
        return;
      }

      // Extract user ID from the response
      final userData = jsonDecode(verifyResponse.body);
      String userId = userData['id'].toString();

      print("Registering face for verified user ID: $userId");

      setState(() {
        status = "Registering face...";
      });

      // Use the already captured image if available, otherwise take a new one
      File imageFile;
      if (capturedImageFile != null && await capturedImageFile!.exists()) {
        imageFile = capturedImageFile!;
      } else {
        // Take a new picture if needed
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
          imageQuality: 90,
        );

        if (pickedFile == null) {
          setState(() {
            status = "Registration cancelled";
            isLoading = false;
          });
          return;
        }

        imageFile = File(pickedFile.path);
        capturedImageFile = imageFile; // Store the new image
      }

      // Process the image and send for face registration
      final bytes = await imageFile.readAsBytes();
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

        print(
            "Sending face registration data to: ${AppConfig.faceRegisterEndpoint}");
        print("With userId: $userId");

        final registerResponse = await http.post(
          Uri.parse("${AppConfig.faceRegisterEndpoint}"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "image": base64Image,
            "userId": userId,
            "username": usernameController.text
          }),
        );

        if (registerResponse.statusCode == 200) {
          // Save session data
          await SessionManager.saveUserSession(
            userId: userId,
            username: usernameController.text,
            faceRegistered: true, // Mark face as registered
          );

          setState(() {
            status = "Face registered successfully!";
            needsRegistration = false;
            isLoading = false;
          });

          // Add a small delay to show success message before proceeding
          await Future.delayed(Duration(seconds: 1));

          // Call the callback with the user information
          widget.onFaceRecognized(int.parse(userId), usernameController.text);
        } else {
          setState(() {
            status = "Registration failed: ${registerResponse.statusCode}";
            hasError = true;
            errorMessage = "Face registration failed: ${registerResponse.body}";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          status = "Error: Could not decode image for registration";
          hasError = true;
          errorMessage = "Image processing error";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        status = "Error: $e";
        hasError = true;
        errorMessage = "Registration error: $e";
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
                      if (hasError) ...[
                        SizedBox(height: 10),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.red.withOpacity(0.3),
                          ),
                          child: Text(
                            errorMessage,
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      if (locationData != null) ...[
                        SizedBox(height: 10),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Location detected:",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white70),
                              ),
                              Text(
                                locationData?.address ?? "Unknown location",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
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
                            // Password field removed
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
                            SizedBox(height: 10),
                            TextButton(
                              onPressed: widget.onCancel,
                              child: Text(
                                "Cancel Registration",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
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
                            SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  needsRegistration = true;
                                  // Check if user is logged in to determine if we show password field
                                  SessionManager.isLoggedIn()
                                      .then((isLoggedIn) {
                                    setState(() {
                                      showPasswordField = !isLoggedIn;
                                    });
                                  });
                                });
                              },
                              child: Text(
                                "Register as New User",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
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

// Extension method to check if string is null or empty
extension StringExtension on String? {
  bool isNotNullOrEmpty() {
    return this != null && this!.isNotEmpty;
  }
}
