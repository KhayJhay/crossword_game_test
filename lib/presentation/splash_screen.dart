import 'package:crossword_test/presentation/getStarted.dart';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:async';


class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    Timer(Duration(seconds: 5), () {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => GetStarted_Page()));
    });
    super.initState();
  }

  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 120.0),
              child: Image.asset(
                'assets/images/bg_icon.png',
                scale: 1.3,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 120,
            child: SpinKitWaveSpinner(
              size: 50,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
