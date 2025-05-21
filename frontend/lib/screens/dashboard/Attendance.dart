import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/time.dart';

class Attendance extends StatefulWidget {
  const Attendance({Key? key}) : super(key: key);

  @override
  _AttendanceState createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> {
  String checkInTime = 'N/A';
  String checkOutTime = 'N/A';
  bool hasCheckedIn = false;

  @override
  void initState() {
    super.initState();
    fetchAttendanceStatus();
  }

  Future<void> fetchAttendanceStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString("userId");

    Response response = await get(
      Uri.parse("http:// 192.168.53.175:8080/api/attendance/status/$id"),
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
        hasCheckedIn = data['checkOutTime'] == null;
      });
    } else {
      print('Failed to fetch attendance status');
    }
  }

  Future<void> checkIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString("userId");

    var map = <String, dynamic>{};
    map["id"] = id;

    Response response = await post(
      Uri.parse("http:// 192.168.53.175:8080/api/attendance/checkin"),
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: map,
    );
    print(response.statusCode);

    if (response.statusCode == 200) {
      setState(() {
        checkInTime = DateFormat('hh:mm:ss a').format(DateTime.now());
        hasCheckedIn = true;
      });
    } else {
      print('Failed to check in');
    }
  }

  Future<void> checkOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString("userId");

    var map = <String, dynamic>{};
    map["id"] = id;

    Response response = await post(
      Uri.parse("http:// 192.168.53.175:8080/api/attendance/checkout/$id"),
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: map,
    );

    if (response.statusCode == 200) {
      print("success");
      setState(() {
        checkOutTime = DateFormat('hh:mm:ss a').format(DateTime.now());
        hasCheckedIn = false;
      });
    } else {
      print('Failed to check out');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      height: 250,
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
                    padding: const EdgeInsets.only(top: 80.0),
                    child: Center(
                      child: SizedBox(
                        width: 200,
                        height: 70,
                        child: ElevatedButton(
                          onPressed: checkIn,
                          style: ElevatedButton.styleFrom(
                            textStyle: const TextStyle(fontSize: 20),
                            backgroundColor: Colors.black.withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Text(
                            "CHECK IN",
                            style: TextStyle(color: Colors.white),
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
                      child: ElevatedButton(
                        onPressed: checkOut,
                        style: ElevatedButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 20),
                          backgroundColor: Colors.black.withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text(
                          "CHECK OUT",
                          style: TextStyle(color: Colors.white),
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
