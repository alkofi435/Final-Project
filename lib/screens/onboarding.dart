// No further edits to be made

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:htr/screens/home.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool onLastPage = false;
  Timer? _timer;
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Welcome to Quill",
      description:
          "Quill allows you to easily convert handwritten documents into digital text.",
      lottieAsset: "assets/onboarding1.json",
    ),
    OnboardingData(
      title: "Snap or Upload",
      description: "Take photos instantly or upload images from your gallery.",
      lottieAsset: "assets/onboarding2.json",
    ),
    OnboardingData(
      title: "Edit. Export. Share.",
      description:
          "Make edits as you wish, then export your text. It's that easy.",
      lottieAsset: "assets/onboarding3.json",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
        if (!mounted || !_controller.hasClients) return;
        final currentPage = _controller.page?.round() ?? _currentPage;
        if (currentPage < _pages.length - 1) {
          _controller.nextPage(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
          );
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
      onLastPage = index == _pages.length - 1;
    });
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final isSmallScreen = screenHeight < 700;
    final isMediumScreen = screenHeight >= 700 && screenHeight < 850;

    final titleFontSize = screenHeight *
        (isSmallScreen
            ? 0.032
            : isMediumScreen
                ? 0.034
                : 0.036);
    final descriptionFontSize = screenHeight *
        (isSmallScreen
            ? 0.020
            : isMediumScreen
                ? 0.022
                : 0.024);
    final buttonHeight = screenHeight * (isSmallScreen ? 0.06 : 0.065);
    final spacingUnit = screenHeight * 0.02;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00A8E8),
              Color(0xFF007EA7),
              Color(0xFF003459),
              Color(0xFF00171F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: isSmallScreen ? 5 : 6,
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return Center(
                      child: Lottie.asset(
                        _pages[index].lottieAsset,
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                flex: isSmallScreen ? 4 : 4,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06,
                    vertical: spacingUnit,
                  ),
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Column(
                          key: ValueKey(_currentPage),
                          children: [
                            Text(
                              _pages[_currentPage].title,
                              style: GoogleFonts.leagueSpartan(
                                textStyle: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: spacingUnit * 0.8),
                            Text(
                              _pages[_currentPage].description,
                              style: GoogleFonts.libreBaskerville(
                                textStyle: TextStyle(
                                  fontSize: descriptionFontSize,
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      SmoothPageIndicator(
                        controller: _controller,
                        count: _pages.length,
                        effect: ExpandingDotsEffect(
                          dotColor: Colors.white,
                          activeDotColor: Color(0xFF00A8E8),
                          dotHeight: screenWidth * 0.02,
                          dotWidth: screenWidth * 0.02,
                          expansionFactor: 3,
                          spacing: screenWidth * 0.015,
                        ),
                      ),
                      SizedBox(height: spacingUnit),
                      SizedBox(
                        height: buttonHeight,
                        child: Row(
                          children: [
                            if (!onLastPage) ...[
                              TextButton(
                                onPressed: () {
                                  _timer?.cancel();
                                  _controller.animateToPage(
                                    _pages.length - 1,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Text(
                                  'Skip',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: descriptionFontSize,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () {
                                  _timer?.cancel();
                                  _controller.nextPage(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Text(
                                  'Next',
                                  style: TextStyle(
                                    fontSize: descriptionFontSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: completeOnboarding,
                                  child: Text(
                                    'Get Started',
                                    style: TextStyle(
                                      fontSize: titleFontSize * 0.65,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                      SizedBox(height: spacingUnit * 0.5),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String lottieAsset;

  OnboardingData({
    required this.title,
    required this.description,
    required this.lottieAsset,
  });
}
