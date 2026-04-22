import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const CatchTheStarsApp());
}

class CatchTheStarsApp extends StatelessWidget {
  const CatchTheStarsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Catch the Stars',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
      ),
      home: const GamePage(),
    );
  }
}

class FallingObject {
  Offset position;
  final String type; // 'star', 'giant', 'bomb', 'magnet', 'shield'
  final double speedMult;
  
  FallingObject({required this.position, required this.type, required this.speedMult});
}

enum GameStatus { menu, playing, gameOver }

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

import 'package:flutter/services.dart';

// ... (rest of imports)

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  // --- GAME LOGIC ---
  GameStatus status = GameStatus.menu;
  double basketX = 0.5;
  List<FallingObject> fallingObjects = [];
  List<Offset> caughtEffects = [];
  int score = 0;
  int highScore = 0;
  int level = 1;
  int combo = 0;
  double comboOpacity = 0.0;
  late Timer gameTimer;
  final Random random = Random();
  double gameSpeed = 0.015;
  
  // Power-up States
  bool isMagnetActive = false;
  bool isShieldActive = false;
  int magnetTimeLeft = 0;
  Timer? magnetTimer;

  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<Offset> bgStars = List.generate(100, (index) => Offset(Random().nextDouble(), Random().nextDouble()));

  // Dynamic Background Colors
  final List<List<Color>> levelColors = [
    [const Color(0xFF0D1B2A), const Color(0xFF1B263B), const Color(0xFF415A77)], // Level 1: Night
    [const Color(0xFF1A1A2E), const Color(0xFF16213E), const Color(0xFF0F3460)], // Level 2: Deep Blue
    [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)], // Level 3: Ocean
    [const Color(0xFF4B0082), const Color(0xFF000000)], // Level 4: Space
    [const Color(0xFFFF5F6D), const Color(0xFFFFC371)], // Level 5: Sunset
  ];

  // --- ADMOB ---
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  final String bannerAdUnitId = 'ca-app-pub-2985057151578238/7174605014';
  final String interstitialAdUnitId = 'ca-app-pub-2985057151578238/7012635095';
  final String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // Masih Test ID

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _loadBannerAd();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  void _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  void _saveHighScore() async {
    if (score > highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', score);
      setState(() {
        highScore = score;
      });
    }
  }

  // --- ADMOB METHODS ---
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerAdReady = true),
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (err) {},
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _loadInterstitialAd();
    }
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (err) => _rewardedAd = null,
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          setState(() {
            status = GameStatus.playing;
            fallingObjects = [];
            isShieldActive = true;
          });
          gameTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
            if (status == GameStatus.playing) updateGame();
          });
          _loadRewardedAd();
        },
      );
    }
  }
      score = 0;
      level = 1;
      combo = 0;
      comboOpacity = 0.0;
      fallingObjects = [];
      caughtEffects = [];
      isMagnetActive = false;
      isShieldActive = false;
      magnetTimeLeft = 0;
      basketX = 0.5;
      gameSpeed = 0.015;
    });
    
    gameTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (status == GameStatus.playing) {
        updateGame();
      } else {
        timer.cancel();
      }
    });
  }

  void updateGame() {
    setState(() {
      // 1. Spawning
      double chance = random.nextDouble();
      if (chance < (0.05 + (score / 3000) + (level * 0.01))) {
        double typeChance = random.nextDouble();
        if (typeChance < 0.03) {
          fallingObjects.add(FallingObject(position: Offset(random.nextDouble(), -0.1), type: 'shield', speedMult: 1.2));
        } else if (typeChance < 0.07) {
          fallingObjects.add(FallingObject(position: Offset(random.nextDouble(), -0.1), type: 'magnet', speedMult: 1.2));
        } else if (typeChance < 0.12) {
          fallingObjects.add(FallingObject(position: Offset(random.nextDouble(), -0.1), type: 'giant', speedMult: 1.8));
        } else if (typeChance < 0.25) {
          fallingObjects.add(FallingObject(position: Offset(random.nextDouble(), -0.1), type: 'bomb', speedMult: 1.4));
        } else {
          fallingObjects.add(FallingObject(position: Offset(random.nextDouble(), -0.1), type: 'star', speedMult: 1.0));
        }
      }

      gameSpeed = 0.015 + (score / 4000) + (level * 0.002);

      // 2. Movement & Collision
      List<FallingObject> nextObjects = [];
      for (var obj in fallingObjects) {
        double nextY = obj.position.dy + (gameSpeed * obj.speedMult);
        double nextX = obj.position.dx;

        if (isMagnetActive && (obj.type == 'star' || obj.type == 'giant')) {
          if (nextX < basketX) nextX += 0.02;
          if (nextX > basketX) nextX -= 0.02;
        }
        
        if (nextY >= 0.85 && nextY <= 0.93) {
          if ((nextX - basketX).abs() < 0.15) {
            // BERHASIL NANGKAP!
            HapticFeedback.lightImpact();
            _playSfx('catch');

            if (obj.type == 'bomb') {
              if (isShieldActive) {
                isShieldActive = false;
                continue;
              }
              gameOver('KENA PETIR! ADUH!');
              return;
            } else if (obj.type == 'magnet') {
              activateMagnet();
              continue;
            } else if (obj.type == 'shield') {
              isShieldActive = true;
              continue;
            } else {
              // Skor + Combo
              combo++;
              int points = (obj.type == 'giant') ? 10 : 1;
              score += points * (combo > 5 ? 2 : 1); // Bonus x2 kalo combo > 5
              
              if (score >= level * 20 && level < 5) {
                level++;
                HapticFeedback.vibrate();
              }

              caughtEffects.add(Offset(nextX, 0.85));
              Timer(const Duration(milliseconds: 500), () {
                if (mounted) setState(() => caughtEffects.remove(Offset(nextX, 0.85)));
              });
              continue;
            }
          }
        }

        if (nextY > 1.0) {
          if (obj.type != 'bomb' && obj.type != 'magnet' && obj.type != 'shield') {
            gameOver('BINTANGNYA LEPAS, MAMEN!');
            _playSfx('fail');
            HapticFeedback.heavyImpact();
            return;
          }
          continue;
        }
        
        obj.position = Offset(nextX, nextY);
        nextObjects.add(obj);
      }
      fallingObjects = nextObjects;
    });
  }

  void gameOver(String msg) {
    gameTimer.cancel();
    magnetTimer?.cancel();
    _saveHighScore();
    setState(() {
      status = GameStatus.gameOver;
      combo = 0;
    });
    _showInterstitialAd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Background
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: levelColors[level - 1],
              ),
            ),
          ),
          
          // ... (bg stars - same)

          if (status == GameStatus.menu) _buildMainMenu(),
          if (status == GameStatus.playing) ..._buildGameplay(),
          if (status == GameStatus.gameOver) _buildGameOver(),

          // ... (banner - same)
        ],
      ),
    );
  }

  List<Widget> _buildGameplay() {
    return [
      // UI Skor & Level
      Positioned(
        top: 50,
        left: 0,
        right: 0,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('LV. $level', style: TextStyle(color: Colors.yellowAccent.withOpacity(0.8), fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(width: 20),
                Text('$score', style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.w900)),
              ],
            ),
            if (combo > 1)
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                child: Text('COMBO X$combo!', style: const TextStyle(color: Colors.orangeAccent, fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
      
      // ... (Rest of objects, power-ups, basket - same as before but status-aware)
    ];
  }


  Widget _buildGameOver() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('YAH KEPLESET!', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text('SKOR: $score', style: const TextStyle(color: Colors.yellow, fontSize: 50, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: startGame,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
              child: const Text('MAIN LAGI', style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
            const SizedBox(height: 10),
            if (_rewardedAd != null)
              ElevatedButton.icon(
                onPressed: _showRewardedAd,
                icon: const Icon(Icons.play_arrow),
                label: const Text('NONTON VIDEO BUAT LANJUT', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
              ),
            TextButton(
              onPressed: () => setState(() => status = GameStatus.menu),
              child: const Text('KEMBALI KE MENU', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}


          // Banner
          if (_isBannerAdReady)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.black,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }
}
