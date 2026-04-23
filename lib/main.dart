import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const AdPlayerApp());
}

class AdPlayerApp extends StatelessWidget {
  const AdPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mamen Premium Ad Player',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
        ),
      ),
      home: const AdPlayerHomePage(),
    );
  }
}

class AdPlayerHomePage extends StatefulWidget {
  const AdPlayerHomePage({super.key});

  @override
  State<AdPlayerHomePage> createState() => _AdPlayerHomePageState();
}

class _AdPlayerHomePageState extends State<AdPlayerHomePage> {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  
  int _rewardScore = 0;
  bool _isBannerLoaded = false;
  late SharedPreferences _prefs;

  // ============================================================
  // BAGIAN ID IKLAN (GANTI DENGAN ID ASLI DARI ADMOB MAMEN)
  // ============================================================
  final String bannerAdUnitId = 'ca-app-pub-2985057151578238/7174605014';
  final String interstitialAdUnitId = 'ca-app-pub-2985057151578238/7012635095';
  final String rewardedAdUnitId = 'ca-app-pub-2985057151578238/4557750778'; // ID ASLI MAMEN SUDAH TERPASANG!
  // MASUKKAN ID HP MAMEN DI SINI (Supaya mamen aman dari Banned)
  final List<String> testDeviceIds = [""]; 
  // ============================================================

  @override
  void initState() {
    super.initState();
    _initAdMob();
    _initData();
    _loadBannerAd();
    _loadInterstitialAd();
    _loadRewardedAd();

    // Print pesan bantuan di log buat cari Device ID mamen
    print("MAMEN INFO: Cari tulisan 'Test Device ID' di bawah ini buat didaftarkan!");
  }

  void _initAdMob() {
    // Konfigurasi supaya HP mamen dianggap perangkat penguji
    RequestConfiguration configuration = RequestConfiguration(testDeviceIds: testDeviceIds);
    MobileAds.instance.updateRequestConfiguration(configuration);
  }

  Future<void> _initData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _rewardScore = _prefs.getInt('mamen_points') ?? 0;
    });
  }

  Future<void> _savePoints() async {
    await _prefs.setInt('mamen_points', _rewardScore);
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerLoaded = true),
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          print('Banner Ad failed: $err');
        },
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (err) => print('InterstitialAd failed: $err'),
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _loadInterstitialAd();
    } else {
      _showSnackBar('Iklan belum siap, mamen! Tunggu bentar...');
      _loadInterstitialAd();
    }
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (err) => print('RewardedAd failed: $err'),
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          setState(() {
            _rewardScore += reward.amount.toInt();
          });
          _savePoints();
          _showSnackBar('Mantap mamen! +${reward.amount} Poin Emas!');
        },
      );
      _rewardedAd = null;
      _loadRewardedAd();
    } else {
      _showSnackBar('Video belum siap, sabar ya mamen...');
      _loadRewardedAd();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.amber.shade800,
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Colors.grey.shade900, Colors.deepPurple.shade900],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                'MAMEN PREMIUM',
                style: TextStyle(
                  fontSize: 18,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w300,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                  border: Border.all(color: Colors.amber, width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.stars, size: 60, color: Colors.amber),
                    Text(
                      '$_rewardScore',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text('POIN EMAS', style: TextStyle(color: Colors.amber)),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  color: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildMenuButton(
                          onPressed: _showInterstitialAd,
                          icon: Icons.fullscreen_rounded,
                          label: 'PUTAR IKLAN CEPAT',
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(height: 15),
                        _buildMenuButton(
                          onPressed: _showRewardedAd,
                          icon: Icons.play_circle_filled_rounded,
                          label: 'TONTON VIDEO EMAS',
                          color: Colors.amber,
                          isLarge: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (_isBannerLoaded)
                Container(
                  alignment: Alignment.bottomCenter,
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isLarge = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: isLarge ? 65 : 55,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: isLarge ? 30 : 24),
        label: Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 18 : 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: color == Colors.amber ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
        ),
      ),
    );
  }
}
