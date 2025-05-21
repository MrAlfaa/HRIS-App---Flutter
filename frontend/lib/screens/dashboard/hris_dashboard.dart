
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../widgets/time.dart';
import 'Attendance.dart';
import 'notification.dart';

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),color: Colors.white,
              iconSize: 30,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/images/Drawe logo.jpg'),
                    radius: 30,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Chamath0915',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'rathnayaka0915@gmail.com',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),

                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Messages'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Profile'),
              onTap: () {
                // Handle the tap
              },
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts_rounded),
              title: const Text('Management'),
              onTap: () {
                // Handle the tap
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy'),
              onTap: () {
                // Handle the tap
              },
            ), ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                // Handle the tap
              },
            ),
          ],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        height: 60,
        backgroundColor: Colors.black,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.grey,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment),
            label: 'Leaves',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments),
            label: 'Payslips',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',

          ),
        ],
      ),


      body: <Widget>[
        /// Home page
        Stack(
          children: [
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
            // Container(
            //   width: MediaQuery.of(context).size.width,
            //   height: MediaQuery.of(context).size.height,
            //   color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
            // ),

            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only( right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left:  20),
                        child: Text(
                          "HELLO  - Chamath Rathnayaka - ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.white,size: 30,),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationScreen()),
                          );
                          // Handle notification button press
                        },
                      ),
                    ],
                  ),
                ),
                const Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Text(
                        "HAVE A NICE DAY...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.wb_sunny,
                      color: Colors.yellowAccent,
                      size: 30.0,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 50, left: 330),
                  child: Text(
                    DateFormat.yMMMEd().format(DateTime.now()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.6),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      hintText: 'Search...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 30, left: 10),
                  child: SizedBox(
                    width: 480,
                    height: 140,
                    child: Stack(
                      children: [
                        // Background image
                        Container(
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/wheather new.jpg'),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                              bottomLeft: Radius.circular(40),
                              bottomRight: Radius.circular(40),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 70, right: 10), // Adjusted padding
                      child: Card(
                        color: Colors.black.withOpacity(0.6),
                        shadowColor: Colors.transparent,
                        child:  SizedBox(
                          width: 250,
                          height: 180,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Admin Panel Settings',
                                  style: TextStyle(color: Colors.white, fontSize: 15),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(width: 10),
                                    IconButton(
                                      icon:  const Icon(Icons.attach_email_rounded, color: Colors.blueGrey, size: 40.0),
                                      onPressed: () {
                                        // Handle notification button press
                                      },
                                    ),
                                    const SizedBox(width: 20),
                                    IconButton(
                                      icon:  const Icon(Icons.admin_panel_settings, color: Colors.blueGrey, size: 40.0),
                                      onPressed: () {
                                        // Handle notification button press
                                      },
                                    ),
                                    const SizedBox(width: 20),
                                    IconButton(
                                      icon:  const Icon(Icons.settings, color: Colors.blueGrey, size: 40.0),
                                      onPressed: () {
                                        // Handle notification button press
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 70, left: 10), // Adjusted padding
                      child: Card(
                        color: Colors.black.withOpacity(0.6),
                        shadowColor: Colors.transparent,
                        child: SizedBox(
                          width: 250,
                          height: 180,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 13.0),
                                child: Text(
                                  'Average Attendance',
                                  style: TextStyle(color: Colors.white, fontSize: 15),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(13.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.bar_chart, color: Colors.blueGrey, size: 50.0),
                                    const SizedBox(width: 20),
                                    Column(
                                      children: [
                                        CircularPercentIndicator(
                                          radius: 25.0,
                                          lineWidth: 6.0,
                                          percent: 0.60,
                                          center: const Text(
                                            "60%",
                                            style: TextStyle(color: Colors.white),
                                          ),
                                          progressColor: Colors.yellow,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),

        /// Attendance page
        Attendance(),


        /// Leaves page
        Card(
          shadowColor: Colors.transparent,
          margin: const EdgeInsets.all(8.0),
          child: SizedBox.expand(
            child: Center(
              child: Text(
                'Leaves page',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
        ),
        /// Payslips page
        Card(
          shadowColor: Colors.transparent,
          margin: const EdgeInsets.all(8.0),
          child: SizedBox.expand(
            child: Center(
              child: Text(
                'Payslips page',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
        ),
        /// Setting page
        Card(
          shadowColor: Colors.transparent,
          margin: const EdgeInsets.all(8.0),
          child: SizedBox.expand(
            child: Center(
              child: Text(
                'Setting page',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
        ),
      ][currentPageIndex],
    );
  }
}
