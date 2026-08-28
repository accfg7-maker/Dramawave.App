import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

const Color kBlack = Color(0xFF000000);
const Color kDark = Color(0xFF141414);
const Color kRed = Color(0xFFE50914);
const Color kDarkRed = Color(0xFF65060A);
const Color kWhite = Color(0xFFFFFFFF);
const Color kGray = Color(0xFFAAAAAA);

const String targetUrl =
    'https://dramawave.dramafren.org/index.php';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const DramaWaveApp());
}

class DramaWaveApp extends StatelessWidget {
  const DramaWaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DramaWave',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBlack,
        colorScheme: const ColorScheme.dark(
          primary: kRed,
          secondary: kRed,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ============================================================
// SPLASH SCREEN
// ============================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> glow;
  late Animation<double> scale;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    glow = Tween<double>(
      begin: 0.25,
      end: 1.0,
    ).animate(controller);

    scale = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(controller);

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: controller,
              builder: (_, child) {
                return Transform.scale(
                  scale: scale.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: kRed,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: kRed.withOpacity(glow.value),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'D',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 62,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            const Text(
              'DRAMAWAVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
                letterSpacing: 5,
              ),
            ),

            const SizedBox(height: 35),

            const SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(
                color: kRed,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WebViewController webViewController;

  StreamSubscription<List<ConnectivityResult>>?
      connectivitySubscription;

  int selectedIndex = 0;
  int progress = 0;

  bool offline = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();

    setupWebView();
    setupConnectivity();
  }

  // ==========================================================
  // WEBVIEW
  // ==========================================================

  void setupWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(
        JavaScriptMode.unrestricted,
      )
      ..setBackgroundColor(kBlack)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (!mounted) return;

            setState(() {
              progress = value;
              loading = value < 100;
            });
          },

          onPageStarted: (_) {
            if (!mounted) return;

            setState(() {
              loading = true;
              progress = 0;
            });
          },

          onPageFinished: (_) async {
            if (!mounted) return;

            setState(() {
              loading = false;
              progress = 100;
            });

            await injectDarkTheme();
            await enhanceVideos();
          },

          onWebResourceError: (error) {
            if (!mounted) return;

            if (error.isForMainFrame ?? true) {
              setState(() {
                offline = true;
              });
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(targetUrl),
      );
  }

  // ==========================================================
  // DARK CSS
  // ==========================================================

  Future<void> injectDarkTheme() async {
    const script = r'''
      (function () {

        if (document.getElementById("dramawave-dark-style")) {
          return;
        }

        const style = document.createElement("style");

        style.id = "dramawave-dark-style";

        style.innerHTML = `

          html,
          body {
            background: #000000 !important;
            color: #ffffff !important;
          }

          body {
            font-family:
              -apple-system,
              BlinkMacSystemFont,
              "Segoe UI",
              Roboto,
              Arial,
              sans-serif !important;
          }

          header,
          nav,
          footer,
          .navbar,
          .header,
          .footer {
            background: #050505 !important;
            color: #ffffff !important;
          }

          a {
            color: #ffffff !important;
          }

          input,
          textarea,
          select {
            background: #181818 !important;
            color: #ffffff !important;
            border-color: #333333 !important;
          }

          button {
            border-radius: 6px !important;
          }

          ::selection {
            background: #E50914 !important;
            color: #ffffff !important;
          }

          ::-webkit-scrollbar {
            width: 5px;
          }

          ::-webkit-scrollbar-track {
            background: #000000;
          }

          ::-webkit-scrollbar-thumb {
            background: #555555;
            border-radius: 10px;
          }

          img {
            border-radius: 5px;
          }

        `;

        document.head.appendChild(style);

      })();
    ''';

    try {
      await webViewController.runJavaScript(script);
    } catch (_) {}
  }

  // ==========================================================
  // VIDEO ENHANCEMENT
  // ==========================================================

  Future<void> enhanceVideos() async {
    const script = r'''
      (function () {

        function enhance() {

          document
            .querySelectorAll("video")
            .forEach(function(video) {

              video.setAttribute(
                "playsinline",
                ""
              );

              video.setAttribute(
                "webkit-playsinline",
                ""
              );

              video.style.backgroundColor = "#000000";

            });

        }

        enhance();

        const observer =
          new MutationObserver(function() {
            enhance();
          });

        observer.observe(
          document.documentElement,
          {
            childList: true,
            subtree: true
          }
        );

      })();
    ''';

    try {
      await webViewController.runJavaScript(script);
    } catch (_) {}
  }

  // ==========================================================
  // INTERNET
  // ==========================================================

  void setupConnectivity() async {
    final connectivity = Connectivity();

    final initial =
        await connectivity.checkConnectivity();

    updateConnectivity(initial);

    connectivitySubscription =
        connectivity.onConnectivityChanged.listen(
      updateConnectivity,
    );
  }

  void updateConnectivity(
    List<ConnectivityResult> result,
  ) {
    if (!mounted) return;

    final connected =
        result.isNotEmpty &&
        !result.contains(
          ConnectivityResult.none,
        );

    setState(() {
      offline = !connected;
    });
  }

  // ==========================================================
  // BACK BUTTON
  // ==========================================================

  Future<void> handleBack() async {
    final canGoBack =
        await webViewController.canGoBack();

    if (canGoBack) {
      await webViewController.goBack();
    } else {
      SystemNavigator.pop();
    }
  }

  // ==========================================================
  // RELOAD
  // ==========================================================

  Future<void> reloadPage() async {
    setState(() {
      offline = false;
    });

    await webViewController.reload();
  }

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  Future<void> navigationTap(int index) async {
    setState(() {
      selectedIndex = index;
    });

    switch (index) {
      case 0:
        await webViewController.loadRequest(
          Uri.parse(targetUrl),
        );
        break;

      case 1:
        await searchWebsite();
        break;

      case 2:
        await categoriesWebsite();
        break;

      case 3:
        showMessage(
          'Saved items are managed by the website.',
        );
        break;

      case 4:
        showSettings();
        break;
    }
  }

  Future<void> searchWebsite() async {
    const script = r'''
      (function () {

        const selectors = [
          'input[type="search"]',
          'input[name="search"]',
          'input[name="q"]',
          'input[placeholder*="Search" i]',
          '.search input',
          '#search input'
        ];

        for (const selector of selectors) {

          const element =
            document.querySelector(selector);

          if (element) {

            element.focus();

            element.scrollIntoView({
              behavior: "smooth",
              block: "center"
            });

            return true;
          }
        }

        return false;

      })();
    ''';

    try {
      await webViewController
          .runJavaScriptReturningResult(script);
    } catch (_) {}
  }

  Future<void> categoriesWebsite() async {
    const script = r'''
      (function () {

        const selectors = [
          'a[href*="category"]',
          'a[href*="genre"]',
          '.categories a',
          '.genres a'
        ];

        for (const selector of selectors) {

          const element =
            document.querySelector(selector);

          if (element) {
            element.click();
            return true;
          }

        }

        return false;

      })();
    ''';

    try {
      await webViewController
          .runJavaScriptReturningResult(script);
    } catch (_) {}
  }

  // ==========================================================
  // SETTINGS
  // ==========================================================

  void showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                ListTile(
                  leading: const Icon(
                    Icons.refresh,
                    color: kRed,
                  ),
                  title: const Text(
                    'Reload website',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    reloadPage();
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.dark_mode,
                    color: kRed,
                  ),
                  title: const Text(
                    'Dark appearance',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: kRed,
                  ),
                  title: const Text(
                    'About',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    showMessage(
                      'DramaWave Mobile',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF171717),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult:
          (didPop, result) async {
        if (!didPop) {
          await handleBack();
        }
      },

      child: Scaffold(
        backgroundColor: kBlack,

        body: Stack(
          children: [

            Positioned.fill(
              child: WebViewWidget(
                controller:
                    webViewController,
              ),
            ),

            // Loading bar
            if (progress > 0 && progress < 100)
              Positioned(
                top:
                    MediaQuery.of(context)
                        .padding
                        .top,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 3,
                  child:
                      LinearProgressIndicator(
                    value:
                        progress / 100,
                    backgroundColor:
                        Colors.transparent,
                    valueColor:
                        const AlwaysStoppedAnimation(
                      kRed,
                    ),
                  ),
                ),
              ),

            // Offline banner
            if (offline)
              Positioned(
                top:
                    MediaQuery.of(context)
                            .padding
                            .top +
                        10,
                left: 12,
                right: 12,
                child: buildOfflineBanner(),
              ),

            // Bottom navigation
            Positioned(
              left: 10,
              right: 10,
              bottom:
                  10 +
                  MediaQuery.of(context)
                      .padding
                      .bottom,
              child: buildBottomNavigation(),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // OFFLINE BANNER
  // ==========================================================

  Widget buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF350609),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: kRed.withOpacity(.5),
        ),
      ),

      child: Row(
        children: [

          const Icon(
            Icons.wifi_off,
            color: kRed,
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Text(
              'No internet connection',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          TextButton(
            onPressed: reloadPage,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: kDarkRed,
            ),
            child: const Text(
              'Retry',
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BOTTOM NAVIGATION
  // ==========================================================

  Widget buildBottomNavigation() {
    const items = [
      [Icons.home_rounded, 'Home'],
      [Icons.search_rounded, 'Search'],
      [Icons.category_rounded, 'Categories'],
      [Icons.bookmark_rounded, 'Saved'],
      [Icons.settings_rounded, 'Settings'],
    ];

    return Container(
      height: 68,

      decoration: BoxDecoration(
        color: const Color(0xEE090909),
        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: Colors.white.withOpacity(.08),
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.7),
            blurRadius: 25,
          ),
        ],
      ),

      child: Row(
        children: List.generate(
          items.length,
          (index) {

            final selected =
                selectedIndex == index;

            return Expanded(
              child: InkWell(
                onTap: () =>
                    navigationTap(index),

                borderRadius:
                    BorderRadius.circular(18),

                child: AnimatedContainer(
                  duration:
                      const Duration(
                    milliseconds: 180,
                  ),

                  margin:
                      const EdgeInsets.all(5),

                  decoration: BoxDecoration(
                    color: selected
                        ? kRed.withOpacity(.15)
                        : Colors.transparent,

                    borderRadius:
                        BorderRadius.circular(14),
                  ),

                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [

                      Icon(
                        items[index][0]
                            as IconData,
                        color: selected
                            ? kRed
                            : kGray,
                        size: 22,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        items[index][1]
                            as String,

                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : kGray,

                          fontSize: 10,

                          fontWeight:
                              selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    connectivitySubscription?.cancel();
    super.dispose();
  }
}
