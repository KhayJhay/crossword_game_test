import 'package:crossword_test/presentation/homepage.dart';
import 'package:flutter/material.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';


class GetStarted_Page extends StatelessWidget {
  const GetStarted_Page({super.key});

  @override
  Widget build(BuildContext context) {
    double _height = MediaQuery.of(context).size.height;
    double _width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        height: _height,
        width: _width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Color.fromARGB(255, 193, 21, 9),
                Colors.red,
                Color.fromARGB(255, 236, 223, 222),
              ]),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 80.0),
                child: Column(
                  children: [
                    GradientText(
              'Red Cross Society\nWord Search Game',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold
              ),
              colors: [
                   const Color.fromARGB(255, 111, 22, 16),
                  Colors.red,
                  const Color.fromARGB(255, 111, 22, 16),
              ],
          ),
      
                  
                  ],
                ),
              ),
            ),
            Align(
               alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom:30.0),
                child: Image.asset(
                        'assets/images/bg_1.png',
                    color: Colors.white,
                      ),
              ),
            ),
            Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => GamePage()));
                  },
                  child: Container(
                    height: 81,
                    width: 195,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.only(topLeft: Radius.circular(60)),
                    ),
                    child: Center(
                      child: Text(
                        'Play  Game',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
