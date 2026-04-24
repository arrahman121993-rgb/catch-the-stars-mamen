import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads_config.dart';

class SnakeGamePage extends StatefulWidget {
  const SnakeGamePage({super.key});

  @override
  State<SnakeGamePage> createState() => _SnakeGamePageState();
}

class _SnakeGamePageState extends State<SnakeGamePage> {
  // Pengaturan Iklan
  InterstitialAd? _interstitialAd;
  final String interstitialAdUnitId = kDebugMode 
      ? 'ca-app-pub-3940256099942544/1033173712' 
      : AdsConfig.interstitialId;

  // Pengaturan Grid
  static const int rowCount = 20;
  static const int columnCount = 20;
  static const int totalSquares = rowCount * columnCount;

  // State Game
  List<int> snakePosition = [45, 65, 85, 105, 125];
  int foodPosition = 300;
  String direction = 'down';
  bool gameStarted = false;
  Timer? timer;
  int score = 0;

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (err) => print('Game Interstitial failed: $err'),
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _loadInterstitialAd(); // Load lagi buat nanti
    }
  }

  void startGame() {
    if (gameStarted) return;
    
    gameStarted = true;
    snakePosition = [45, 65, 85, 105, 125];
    direction = 'down';
    score = 0;
    _generateNewFood();
    
    timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      updateSnake();
      if (gameOver()) {
        timer.cancel();
        _showGameOverDialog();
      }
    });
  }

  void _generateNewFood() {
    foodPosition = Random().nextInt(totalSquares);
    while (snakePosition.contains(foodPosition)) {
      foodPosition = Random().nextInt(totalSquares);
    }
  }

  void updateSnake() {
    setState(() {
      switch (direction) {
        case 'down':
          if (snakePosition.last >= totalSquares - columnCount) {
            snakePosition.add(snakePosition.last + columnCount - totalSquares);
          } else {
            snakePosition.add(snakePosition.last + columnCount);
          }
          break;
        case 'up':
          if (snakePosition.last < columnCount) {
            snakePosition.add(snakePosition.last - columnCount + totalSquares);
          } else {
            snakePosition.add(snakePosition.last - columnCount);
          }
          break;
        case 'left':
          if (snakePosition.last % columnCount == 0) {
            snakePosition.add(snakePosition.last - 1 + columnCount);
          } else {
            snakePosition.add(snakePosition.last - 1);
          }
          break;
        case 'right':
          if ((snakePosition.last + 1) % columnCount == 0) {
            snakePosition.add(snakePosition.last + 1 - columnCount);
          } else {
            snakePosition.add(snakePosition.last + 1);
          }
          break;
      }

      if (snakePosition.last == foodPosition) {
        score++;
        _generateNewFood();
      } else {
        snakePosition.removeAt(0);
      }
    });
  }

  bool gameOver() {
    for (int i = 0; i < snakePosition.length - 1; i++) {
      if (snakePosition[i] == snakePosition.last) {
        return true;
      }
    }
    return false;
  }

  void _showGameOverDialog() {
    _showInterstitialAd(); // MUNCUL IKLAN PAS KALAH!
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('GAME OVER MAMEN!', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          content: Text('Skor mamen: $score', style: const TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  gameStarted = false;
                  startGame();
                });
              },
              child: const Text('COBA LAGI', style: TextStyle(color: Colors.greenAccent)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('KELUAR', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('NEON SNAKE MAMEN', style: TextStyle(color: Colors.greenAccent, letterSpacing: 2)),
        actions: [
          Center(child: Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Text('SCORE: $score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
          ))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (direction != 'up' && details.delta.dy > 0) direction = 'down';
                if (direction != 'down' && details.delta.dy < 0) direction = 'up';
              },
              onHorizontalDragUpdate: (details) {
                if (direction != 'left' && details.delta.dx > 0) direction = 'right';
                if (direction != 'right' && details.delta.dx < 0) direction = 'left';
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalSquares,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnCount,
                  ),
                  itemBuilder: (context, index) {
                    if (snakePosition.contains(index)) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Container(color: index == snakePosition.last ? Colors.white : Colors.greenAccent),
                          ),
                        ),
                      );
                    } else if (index == foodPosition) {
                      return Container(
                        padding: const EdgeInsets.all(2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Container(color: Colors.redAccent),
                        ),
                      );
                    } else {
                      return Container(
                        padding: const EdgeInsets.all(2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Container(color: Colors.grey[900]),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!gameStarted)
                    ElevatedButton(
                      onPressed: startGame,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                      child: const Text('MULAI GAME', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  if (gameStarted)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildControlBtn(Icons.arrow_upward, 'up'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildControlBtn(Icons.arrow_back, 'left'),
                            const SizedBox(width: 20),
                            _buildControlBtn(Icons.arrow_forward, 'right'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildControlBtn(Icons.arrow_downward, 'down'),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBtn(IconData icon, String newDir) {
    return GestureDetector(
      onTap: () {
        if (newDir == 'up' && direction != 'down') direction = 'up';
        if (newDir == 'down' && direction != 'up') direction = 'down';
        if (newDir == 'left' && direction != 'right') direction = 'left';
        if (newDir == 'right' && direction != 'left') direction = 'right';
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
        ),
        child: Icon(icon, color: Colors.greenAccent, size: 30),
      ),
    );
  }
}
