import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hris_mobile_app/screens/logging/reset_password.dart';


class passwordLogging  extends StatefulWidget {
  const  passwordLogging({super.key});

  @override
  State< passwordLogging> createState() => _passwordLogging();
}

class _passwordLogging extends State< passwordLogging> {

  void _navigateResetPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>const resetPassword()),
    );
  }
  bool _obscureText = true;

  void _togglePasswordView() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            Positioned(
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 2,
                child: Image.asset(
                  "assets/images/log.jpg",
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 450,
              child: Container(
                decoration: const BoxDecoration(
                  boxShadow: [BoxShadow(color: Colors.black, blurRadius: 10)],
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50)),
                ),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 30, left: 250),
                      child: Text(
                        "- LOGIN -",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 40, left: 40),
                      child: Container(
                        width: MediaQuery.of(context).size.width - 80,
                        height: 45,
                        decoration: BoxDecoration(color: Colors.white),
                        child: TextField(
                          style: TextStyle(fontWeight: FontWeight.bold),
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: _togglePasswordView,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 80, left: 40),
                      child: Container(
                        width: MediaQuery.of(context).size.width - 80,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: InkWell(
                          onTap: _navigateResetPassword,
                          child: const Center(
                            child: Text(
                              ""
                                  "NEXT",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 50, left: 40, right: 40),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              "OR",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20, left: 40, right: 40),
                      child: Container(
                        width: MediaQuery.of(context).size.width - 80,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          // border: InputBorder.none,
                        ),
                        child: InkWell(
                          onTap: () {
                            // Handle Google login action here
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/images/Google_Icon.webp",
                                height: 30,
                                width: 30,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Sign in with Google",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
