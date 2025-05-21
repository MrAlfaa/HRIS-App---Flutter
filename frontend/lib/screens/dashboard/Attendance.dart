import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../widgets/time.dart';
import '../../services/location_service.dart';
import 'FaceRecognitionScreen.dart';
import '../../services/session_manager.dart'; // Add this import

class Attendance extends StatefulWidget {
  const Attendance({Key? key}) : super(key: key);

  @override
  _AttendanceState createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> {
  String checkInTime = 'N/A';
  String checkOutTime = 'N/A';
  bool hasCheckedIn = false;
  bool isShowingFaceRecognition = false;
  String? checkInLocation = 'N/A';
  String? checkOutLocation = 'N/A';

  @override
  void initState() {
    super.initState();
    fetchAttendanceStatus();
  }

  Future<void> fetchAttendanceStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString("userId");

    if (id == null) {
      // Handle no user logged in
      return;
    }

    try {
      http.Response response = await http.get(
        Uri.parse("${AppConfig.apiBaseUrl}/api/attendance/status/$id"),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          checkInTime = data['checkInTime'] != null
              ? DateFormat('hh:mm:ss a')
                  .format(DateTime.parse(data['checkInTime']))
              : 'N/A';
          checkOutTime = data['checkOutTime'] != null
              ? DateFormat('hh:mm:ss a')
                  .format(DateTime.parse(data['checkOutTime']))
              : 'N/A';
          hasCheckedIn =
              data['checkInTime'] != null && data['checkOutTime'] == null;

          // Add location display
          checkInLocation = data['checkInAddress'] ?? 'N/A';
          checkOutLocation = data['checkOutAddress'] ?? 'N/A';
        });
      } else {
        print('Failed to fetch attendance status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching attendance status: $e');
    }
  }

  Future<void> handleFaceRecognition(bool isCheckIn) async {
    setState(() {
      isShowingFaceRecognition = true;
    });
  }

  void handleFaceRecognized(int userId, String username) async {
    // Save user ID and mark face as registered
    await SessionManager.saveUserSession(
      userId: userId.toString(),
      username: username,
      faceRegistered: true, // Mark face as registered
    );

    // Get current location
    LocationData? locationData =
        await LocationService.getCurrentLocation(context);

    try {
      if (!hasCheckedIn) {
        // Handle check-in
        Map<String, dynamic> requestBody = {"userId": userId};

        // Add location data if available
        if (locationData != null) {
          requestBody["location"] = locationData.toJson();
        }

        print("Sending check-in request with data: $requestBody");
        http.Response response = await http.post(
          Uri.parse("${AppConfig.apiBaseUrl}/api/attendance/face-checkin"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestBody),
        );

        print("Check-in response status: ${response.statusCode}");
        print("Check-in response body: ${response.body}");

        if (response.statusCode == 200) {
          var responseData = jsonDecode(response.body);
          setState(() {
            checkInTime = DateFormat('hh:mm:ss a').format(DateTime.now());
            hasCheckedIn = true;
            isShowingFaceRecognition = false;
            checkInLocation = locationData?.address ?? 'Location not available';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Successfully checked in!")),
          );
        } else {
          print('Failed to check in: ${response.statusCode}');
          setState(() {
            isShowingFaceRecognition = false;
          });

          // Parse error message
          String errorMsg = "Failed to check in";
          try {
            final errorData = jsonDecode(response.body);
            if (errorData.containsKey('error')) {
              errorMsg = errorData['error'];
            }
          } catch (e) {
            // Ignore parsing errors
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      } else {
        // Handle check-out with similar improvements
        Map<String, dynamic> requestBody = {"userId": userId};

        // Add location data if available
        if (locationData != null) {
          requestBody["location"] = locationData.toJson();
        }

        print("Sending check-out request with data: $requestBody");
        http.Response response = await http.post(
          Uri.parse("${AppConfig.apiBaseUrl}/api/attendance/face-checkout"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestBody),
        );

        print("Check-out response status: ${response.statusCode}");
        print("Check-out response body: ${response.body}");

        if (response.statusCode == 200) {
          var responseData = jsonDecode(response.body);
          setState(() {
            checkOutTime = DateFormat('hh:mm:ss a').format(DateTime.now());
            hasCheckedIn = false;
            isShowingFaceRecognition = false;
            checkOutLocation =
                locationData?.address ?? 'Location not available';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Successfully checked out!")),
          );
        } else {
          print('Failed to check out: ${response.statusCode}');
          setState(() {
            isShowingFaceRecognition = false;
          });

          // Parse error message
          String errorMsg = "Failed to check out";
          try {
            final errorData = jsonDecode(response.body);
            if (errorData.containsKey('error')) {
              errorMsg = errorData['error'];
            }
          } catch (e) {
            // Ignore parsing errors
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      }
    } catch (e) {
      print('Error during face-based attendance: $e');
      setState(() {
        isShowingFaceRecognition = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isShowingFaceRecognition) {
      return FaceRecognitionScreen(
        isCheckIn: !hasCheckedIn,
        onFaceRecognized: handleFaceRecognized,
        onCancel: () {
          setState(() {
            isShowingFaceRecognition = false;
          });
        },
      );
    }

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/3D background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 70),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'WELCOME',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 30),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              AssetImage('assets/images/Profile logo.jpg'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text(
                    'Employee - Chamath0915',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 60, left: 220),
                  child: Text(
                    "Today's Status",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Center(
                    child: Container(
                      width: 550,
                      height: 300, // Increased height to accommodate location
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 15,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "Check In",
                                  style: TextStyle(
                                      fontFamily: "NexaRegular",
                                      fontSize: 20,
                                      color: Colors.white),
                                ),
                                Text(
                                  checkInTime,
                                  style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Location:",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white70),
                                ),
                                Container(
                                  padding: EdgeInsets.all(5),
                                  width: 150,
                                  child: Text(
                                    checkInLocation ?? 'N/A',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.white),
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "Check Out",
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.white),
                                ),
                                Text(
                                  checkOutTime,
                                  style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Location:",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white70),
                                ),
                                Container(
                                  padding: EdgeInsets.all(5),
                                  width: 150,
                                  child: Text(
                                    checkOutLocation ?? 'N/A',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.white),
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: TimeDisplay(),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: Center(
                    child: Text(
                      DateFormat.yMMMEd().format(DateTime.now()),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                if (!hasCheckedIn)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 40.0), // Reduced padding
                    child: Center(
                      child: SizedBox(
                        width: 200,
                        height: 70,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.face, color: Colors.white),
                          label: Text("FACE CHECK IN",
                              style: TextStyle(color: Colors.white)),
                          onPressed: () => handleFaceRecognition(true),
                          style: ElevatedButton.styleFrom(
                            textStyle: const TextStyle(fontSize: 20),
                            backgroundColor: Colors.black.withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Center(
                    child: SizedBox(
                      width: 200,
                      height: 70,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.face, color: Colors.white),
                        label: Text("FACE CHECK OUT",
                            style: TextStyle(color: Colors.white)),
                        onPressed: hasCheckedIn
                            ? () => handleFaceRecognition(false)
                            : null,
                        style: ElevatedButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 20),
                          backgroundColor: Colors.black.withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
