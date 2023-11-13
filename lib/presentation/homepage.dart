import 'dart:math';

import 'package:crossword/components/line_decoration.dart';
import 'package:crossword/crossword.dart';
import 'package:crossword_test/presentation/getStarted.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'package:customprompt/customprompt.dart';
import 'package:http/http.dart' as http;

class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  List<List<String>> letters = [];
  List<Color> lineColors = [];
  Color crossedLineColor = Colors.red;
  List<List<String>>? generatedCrossword;
  List<String> givenWords = [];
  List<String> randomWords = [];
  List<String> foundWords = [];
  int score = 0;
  int timeInSeconds = 180; // 3 minutes
  Set<String> correctWords = Set();
  late Timer timer;
  String crossedWord = '';
  int shimmerLoading = 0;
  Color generateRandomColor() {
    Random random = Random();

    int r = random.nextInt(200) - 128; // Red component between 128 and 255
    int g = random.nextInt(200) - 128; // Green component between 128 and 255
    int b = random.nextInt(200) - 128; // Blue component between 128 and 255

    return Color.fromARGB(255, r, g, b);
  }

  Future<void> fetchRandomWords() async {
    final response = await http.get(Uri.parse(
        'https://random-word-api.herokuapp.com/word?number=4&length=7'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        // Check if the response contains at least one word
        setState(() {
          randomWords =
              data.map((word) => word.toString().toUpperCase()).toList();
          givenWords = List.from(randomWords);
        });
        print(givenWords);
      } else {
        throw Exception('No words found in the response');
      }
    } else {
      throw Exception('Failed to load random words');
    }
  }

  List<List<String>> generateCrossword() {
    // Determine the dimensions of the grid based on the length of the longest word
    if (givenWords.isEmpty) {
      return []; // Return an empty grid if givenWords is empty
    }
    int maxLength = givenWords.map((word) => word.length).reduce(max);
    int rows = givenWords.length + maxLength;
    int columns = maxLength * 2;

    // Initialize an empty grid
    List<List<String>> grid =
        List.generate(rows, (_) => List.filled(columns, ""));

    // Place givenWords on the grid randomly
    for (int i = 0; i < givenWords.length; i++) {
      String word = givenWords[i];
      bool placed = false;
      int regenerationAttempts = 0;
      int maxRegenerationAttempts =
          100; // Set a maximum number of regeneration attempts

      // Try to place the word randomly
      while (!placed && regenerationAttempts < maxRegenerationAttempts) {
        int randomRow = Random().nextInt(rows);
        int randomCol = Random().nextInt(columns);

        bool valid = true;

        // Check if the word can be placed horizontally without overlapping
        if (randomCol + word.length <= columns) {
          for (int l = 0; l < word.length && valid; l++) {
            if (grid[randomRow][randomCol + l] != "" &&
                grid[randomRow][randomCol + l] != word[l]) {
              valid = false;
            }
          }
        } else {
          valid = false;
        }

        // Check if the word can be placed vertically without overlapping
        if (randomRow + word.length <= rows) {
          for (int l = 0; l < word.length && valid; l++) {
            if (grid[randomRow + l][randomCol] != "" &&
                grid[randomRow + l][randomCol] != word[l]) {
              valid = false;
            }
          }
        } else {
          valid = false;
        }

        // Place the word if valid
        if (valid) {
          for (int l = 0; l < word.length; l++) {
            if (randomCol + l < columns) {
              grid[randomRow][randomCol + l] = word[l];
            } else {
              grid[randomRow + l - columns][randomCol] = word[l];
            }
          }
          placed = true;
        }

        regenerationAttempts++;
      }

      // If the word couldn't be placed after maximum regeneration attempts, return an empty grid
      if (!placed) {
        return List.generate(rows, (_) => List.filled(columns, ""));
      }
    }
    // Fill in remaining empty spaces with random letters
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        if (grid[i][j] == "") {
          grid[i][j] =
              String.fromCharCode(Random().nextInt(26) + 'A'.codeUnitAt(0));
        }
      }
    }

    // Check if all the letters of the given words are present in the grid
    for (String word in givenWords) {
      bool found = false;

      // Check horizontally
      for (int i = 0; i < rows && !found; i++) {
        for (int j = 0; j <= columns - word.length && !found; j++) {
          String substring = grid[i].sublist(j, j + word.length).join();
          if (substring == word) {
            found = true;
          }
        }
      }

      // Check vertically
      for (int i = 0; i <= rows - word.length && !found; i++) {
        for (int j = 0; j < columns && !found; j++) {
          String substring = "";
          for (int k = 0; k < word.length; k++) {
            substring += grid[i + k][j];
          }
          if (substring == word) {
            found = true;
          }
        }
      }

      // If any given word is not found, regenerate the crossword
      if (!found) {
        return generateCrossword();
      }
    }

    return grid;
  }

  int calculateScore(String word, int timeTaken) {
    int wordLength = word.length;
    int baseScore = wordLength * 10; // Assign a base score based on word length
    int timePenalty = (180 - timeTaken) ~/
        5; // Deduct points based on time taken (assuming a 3-minute game with a penalty of 2 points per second)

    int score = baseScore - timePenalty;
    return score > 0 ? score : 0; // Ensure the score is non-negative
  }

  bool isWordMatched(String word) {
    return givenWords.contains(word);
  }

  bool isCrossedWordMatched(List<String> crossedWord) {
    String word = crossedWord.join('');
    return givenWords.contains(word);
  }

  @override
  void initState() {
    super.initState();
    initializeGame();
  }

  Future<void> initializeGame() async {
    try {
      await fetchRandomWords();
      lineColors =
          List.generate(100, (index) => generateRandomColor()).toList();
      await Future.delayed(const Duration(milliseconds: 1000));
      generatedCrossword = generateCrossword();

      if (generatedCrossword!.isNotEmpty) {
        setState(() {
          letters = generatedCrossword!;
        });

        timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
          setState(() {
            if (timeInSeconds > 0) {
              timeInSeconds--;
            } else {
              t.cancel(); // Stop the timer when time is up
              // Implement your game over logic here
              CustomPrompt(
                animDuration: 500,
                type: Type.warning,
                color: Colors.orangeAccent,
                curve: Curves.easeInCubic,
                transparent: true,
                context: context,
                btnOneText: const Text('Okay'),
                btnOneOnClick: () {
                  Navigator.pop(context);
                },
                title: 'Game Over',
                content: "Could'nt find words in time",
              ).alert();
            }
          });
        });
      } else {
        throw Exception('Unable to generate a valid crossword');
      }
    } catch (e) {
      print('Error initializing game: $e');
      // Handle the error accordingly, show a message, etc.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GradientText(
                    'Word Search Game',
                    style: const TextStyle(
                        fontSize: 22.0, fontWeight: FontWeight.bold),
                    colors: const [
                      Color.fromARGB(255, 219, 172, 168),
                      Colors.red,
                      Color.fromARGB(255, 111, 22, 16),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      CustomPrompt(
                        context: context,
                        type: Type.confirm,
                        animDuration: 300,
                        transparent: true,
                        color: Colors.orangeAccent,
                        title: 'Quiting Game',
                        content: 'Do you want to quit?',
                        curve: Curves.easeIn,
                        btnOneText: const Text('Yes'),
                        btnOneColor: Colors.white,
                        btnTwoColor: Colors.red,
                        btnTwoText: const Text('No'),
                        btnOneOnClick: () {
                          Navigator.pop(context);
                        },
                        btnTwoOnClick: () {
                          print('Button two clicked');
                        },
                      ).alert();
                    },
                    child: Container(
                      height: 34,
                      width: 34,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.clear,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            SizedBox(
              height: 400,
              child: Container(
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.red)),
                child: generatedCrossword != null
                    ? Crossword(
                        letters: generatedCrossword!,
                        spacing: const Offset(30, 30),
                        onLineDrawn: (List<String> drawnLine) {
                          String currentDrawnWord = drawnLine.last;
                          bool isCorrect = isWordMatched(currentDrawnWord);

                          if (isCorrect &&
                              !foundWords.contains(currentDrawnWord)) {
                            setState(() {
                              int timeTaken = 180 - timeInSeconds;
                              int wordScore =
                                  calculateScore(currentDrawnWord, timeTaken);
                              score +=
                                  wordScore; // Update the score by adding the word's score
                              foundWords.add(currentDrawnWord);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text('Correct! Score: $score'),
                                ),
                              );
                            });

                            if (foundWords.length == 4) {
                              CustomPrompt(
                                  animDuration: 500,
                                  type: Type.success,
                                  curve: Curves.easeInCubic,
                                  transparent: true,
                                  context: context,
                                  title: 'You Won',
                                  btnOneText: const Text('Okay'),
                                  content: "Awesome!! Total Score:$score",
                                  btnOneOnClick: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                GetStarted_Page()));
                                  }).alert();
                            }
                          } else if (!isCorrect) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Incorrect, Try Again'),
                              ),
                            );
                          }
                        },
                        textStyle:
                            const TextStyle(color: Colors.black, fontSize: 15),
                        lineDecoration: LineDecoration(
                            lineColors: lineColors, strokeWidth: 20),
                        hints: givenWords,
                      )
                    : loadingWidget(),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Time:',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ' ${timeInSeconds ~/ 60}:${(timeInSeconds % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                color: Colors.black, fontSize: 18),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            'Score:',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ' $score',
                            style: const TextStyle(
                                color: Colors.black, fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color.fromARGB(255, 234, 180, 176),
                                Colors.red,
                                Color.fromARGB(255, 187, 16, 16),
                              ]),
                        ),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                primary: Colors.transparent,
                                onSurface: Colors.transparent,
                                shadowColor: Colors.transparent,
                                fixedSize: const Size(180, 45),
                                textStyle: const TextStyle(
                                    color: Colors.white, fontSize: 14)),
                            onPressed: () {
                              setState(() {
                                // Clear all game-related variables and reset the game
                                score = 0;
                                foundWords.clear();
                                timeInSeconds = 180;
                                timer.cancel();
                              });
                            },
                            child: const Text(
                              'Restart',
                              style: TextStyle(
                                fontSize: 22,
                                color: Colors.white,
                              ),
                            )),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration:
                        BoxDecoration(border: Border.all(color: Colors.red)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: givenWords.map((word) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Text(
                            '$word',
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 15,
            ),
            if (foundWords.isNotEmpty)
              Column(
                children: [
                  const Text(
                    'Found Words:',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.all(10),
                    padding: const EdgeInsets.all(8),
                    decoration:
                        BoxDecoration(border: Border.all(color: Colors.green)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: foundWords.map((word) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            '$word',
                            style: const TextStyle(
                                color: Colors.black38,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.lineThrough),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer.cancel(); // Cancel the timer to avoid memory leaks
    super.dispose();
  }

  loadingWidget() {
    return Visibility(
      visible: shimmerLoading < 100,
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}
