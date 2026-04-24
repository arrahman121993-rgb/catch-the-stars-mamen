import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ads_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
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
  // LOGIC ID IKLAN (OTOMATIS TEST ID KALAU DEBUG)
  // ============================================================
  final String bannerAdUnitId = kDebugMode 
      ? 'ca-app-pub-3940256099942544/6300978111' 
      : AdsConfig.bannerId;

  final String interstitialAdUnitId = kDebugMode 
      ? 'ca-app-pub-3940256099942544/1033173712' 
      : AdsConfig.interstitialId;

  final String rewardedAdUnitId = kDebugMode 
      ? 'ca-app-pub-3940256099942544/5224354917' 
      : AdsConfig.rewardedId;
  // ============================================================

  @override
  void initState() {
    super.initState();
    _initData();
    _loadBannerAd();
    _loadInterstitialAd();
    _loadRewardedAd();
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
      _showSnackBar('Iklan belum siap, mamen!');
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
          _showSnackBar('Mantap mamen! +${reward.amount} Poin!');
        },
      );
      _rewardedAd = null;
      _loadRewardedAd();
    } else {
      _showSnackBar('Video belum siap...');
      _loadRewardedAd();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
      appBar: AppBar(
        title: const Text('MAMEN AD PLAYER'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                'Poin: $_rewardScore',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _showInterstitialAd,
              icon: const Icon(Icons.ads_click),
              label: const Text('Tampilkan Interstitial'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showRewardedAd,
              icon: const Icon(Icons.video_library),
              label: const Text('Tonton Video Reward'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            ),
            const Spacer(),
            if (_isBannerLoaded)
              SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }
}
