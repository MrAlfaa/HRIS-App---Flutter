import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black45,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 40, left: 10),
              child: Text(
                "Notification",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
            ),

            const SizedBox(height: 20),
            _buildNotificationCard("Notification 1", "     User id 1 Check-In success ( 2024/08/12 - 09.25 A.M )"),
            _buildNotificationCard("Notification 2", "     User id 1 Check-Out success ( 2024/08/12 - 05.30 P.M )"),
            _buildNotificationCard("Notification 3", "     User id 1 Check-In success ( 2024/08/07 - 09.25 A.M )"),
            _buildNotificationCard("Notification 4", "     User id 1 Check-Out success ( 2024/08/07 - 05.30 P.M )"),
            _buildNotificationCard("Notification 5", "     User id 1 Check-In success ( 2024/08/08 - 09.25 A.M )"),
            _buildNotificationCard("Notification 6", "     User id 1 Check-Out success ( 2024/08/08 - 05.30 P.M )"),
            _buildNotificationCard("Notification 7", "     User id 1 Check-In success ( 2024/08/09 - 08.25 A.M )"),
            _buildNotificationCard("Notification 8", "     User id 1 Check-Out success ( 2024/08/09 - 05.30 P.M )"),
            _buildNotificationCard("Notification 9", "     User id 1 Check-In success ( 2024/08/06 - 10.25 A.M )"),
            _buildNotificationCard("Notification 10", "    User id 1 Check-Out success ( 2024/08/10 - 05.30 P.M )"),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(String title, String content) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Card(
        color: Colors.grey,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.message, color: Colors.blue, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                content,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
