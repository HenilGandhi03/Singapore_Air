import 'package:flutter/material.dart';
import 'analytics/clevertap_analytics.dart';
import 'brand.dart';
import 'models.dart';
import 'state.dart';
import 'ui.dart';
import 'pages_home.dart';
import 'pages_book.dart';
import 'pages_trips.dart';
import 'pages_misc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final s = AppState();
  await s.init();
  await CleverTapAnalytics.instance.init(s);
  runApp(MerlionApp(state: s));
}

class MerlionApp extends StatelessWidget {
  final AppState state;
  const MerlionApp({super.key, required this.state});
  @override
  Widget build(BuildContext context) => Scope(
    state: state,
    child: MaterialApp(
      title: 'Singapore Airlines',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      builder: (c, child) => _GlobalTapTracker(
        child: LayoutBuilder(
          builder: (c, box) {
            if (box.maxWidth < 520) return child!;
            // desktop: render inside a phone-shaped frame
            final h = box.maxHeight - 40;
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF07142E), Color(0xFF16356B)],
                ),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 410,
                height: h > 860 ? 860 : h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(38),
                  border: Border.all(
                    color: gold.withValues(alpha: .5),
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 50,
                      offset: Offset(0, 24),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: child,
              ),
            );
          },
        ),
      ),
      home: const Root(),
    ),
  );
}

class _GlobalTapTracker extends StatelessWidget {
  final Widget child;
  const _GlobalTapTracker({required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerUp: (event) {
        CleverTapAnalytics.instance.captureGlobalTap(context, event);
      },
      child: child,
    );
  }
}

enum Stage { splash, welcome, app }

class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  Stage stage = Stage.splash;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted)
        setState(
          () => stage = context.app.onboarded ? Stage.app : Stage.welcome,
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    Widget w;
    if (stage == Stage.splash) {
      w = const SplashPage(key: ValueKey('s'));
    } else if (!app.onboarded) {
      w = WelcomePage(
        key: const ValueKey('w'),
        onDone: () => app.finishOnboarding(),
      );
    } else {
      w = const Shell(key: ValueKey('a'));
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: w,
    );
  }
}

// ---------------------------------------------------------------- splash
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..forward();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      color: Colors.white,
      child: Center(
        child: AnimatedBuilder(
          animation: c,
          builder: (_, __) {
            final t = Curves.easeOutCubic.transform((c.value * 2).clamp(0, 1));
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: t,
                  child: Transform.scale(
                    scale: .7 + .3 * t,
                    child: const SiaLogo(height: 96),
                  ),
                ),
                const SizedBox(height: 22),
                Opacity(
                  opacity: t,
                  child: const Text(
                    'A GREAT WAY TO FLY',
                    style: TextStyle(
                      color: gold,
                      letterSpacing: 4,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: 190,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: c.value,
                      minHeight: 3,
                      backgroundColor: line,
                      color: navy,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Preparing your journey...',
                  style: TextStyle(
                    color: muted,
                    fontSize: 14,
                    letterSpacing: .5,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------- welcome / login
class WelcomePage extends StatefulWidget {
  final VoidCallback onDone;
  const WelcomePage({super.key, required this.onDone});
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final id = TextEditingController(text: '8820 4417 55');
  final pin = TextEditingController(text: '123456');
  bool busy = false, login = false;
  final pc = PageController();
  int page = 0;

  static const slides = [
    (
      'Discover the world',
      'Fly to 120+ destinations with award-winning service.',
      0xFF8E2C5B,
    ),
    (
      'Manage every journey',
      'Book, check in and board with a few taps.',
      0xFF0E6E7E,
    ),
    (
      'Earn KrisFlyer',
      'Turn every trip into rewards, upgrades and lounge access.',
      0xFFB4541F,
    ),
  ];

  void signIn() async {
    setState(() => busy = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: navy,
    body: SafeArea(
      child: login
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => setState(() => login = false),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const SiaLogo(height: 54),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text('Welcome back', style: serif(30, c: Colors.white)),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in with your KrisFlyer number. Demo details are prefilled.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 26),
                  Field('Membership number', c: id, icon: Icons.badge_outlined),
                  Field('PIN', c: pin, icon: Icons.lock_outline, obscure: true),
                  const SizedBox(height: 10),
                  PrimaryBtn(
                    'Sign in',
                    goldStyle: true,
                    loading: busy,
                    onTap: signIn,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: busy
                          ? null
                          : () => toast(
                              context,
                              'Demo only: your PIN is prefilled',
                            ),
                      child: const Text(
                        'Forgot PIN?',
                        style: TextStyle(color: gold),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: pc,
                    itemCount: slides.length,
                    onPageChanged: (i) => setState(() => page = i),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Expanded(
                            child: Scenic(
                              c1: slides[i].$3,
                              c2: 0xFF16356B,
                              height: double.infinity,
                              radius: 32,
                              child: const Center(
                                child: Icon(
                                  Icons.flight_takeoff,
                                  color: Colors.white,
                                  size: 74,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          Text(
                            slides[i].$1,
                            style: serif(28, c: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            slides[i].$2,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < slides.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.all(4),
                        width: i == page ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == page ? gold : Colors.white30,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      PrimaryBtn(
                        'Sign in to KrisFlyer',
                        goldStyle: true,
                        onTap: () => setState(() => login = true),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: widget.onDone,
                        child: const Text(
                          'Continue as guest',
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    ),
  );
}

// ---------------------------------------------------------------- shell with persistent bottom nav
class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ValueListenableBuilder<int>(
      valueListenable: app.tab,
      builder: (context, idx, _) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          final nav = app.navKeys[idx].currentState;
          if (nav != null && nav.canPop()) {
            nav.pop();
          } else if (idx != 0) {
            app.tab.value = 0;
          }
        },
        child: Scaffold(
          body: IndexedStack(
            index: idx,
            children: [
              for (var i = 0; i < 5; i++)
                Navigator(
                  key: app.navKeys[i],
                  onGenerateRoute: (s) => _route(s, i),
                ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: navy.withValues(alpha: .1),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  for (final e in const [
                    (Icons.home_outlined, Icons.home_rounded, 'Home'),
                    (Icons.flight, Icons.flight, 'Book Flights'),
                    (Icons.work_outline, Icons.work, 'My Trips'),
                    (Icons.schedule, Icons.schedule, 'Flight Status'),
                    (Icons.menu, Icons.menu, 'More'),
                  ].indexed)
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          CleverTapAnalytics.instance.trackTap(
                            source:
                                'bottom_nav_${e.$2.$3.toLowerCase().replaceAll(' ', '_')}',
                            screen: 'tab_${idx}',
                            props: {'target_tab': e.$1},
                          );
                          if (idx == e.$1) {
                            app.navKeys[e.$1].currentState?.popUntil(
                              (r) => r.isFirst,
                            );
                          } else {
                            app.tab.value = e.$1;
                            CleverTapAnalytics.instance.trackScreen(
                              e.$2.$3,
                              props: {'tab_index': e.$1},
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      idx == e.$1 ? e.$2.$2 : e.$2.$1,
                                      color: idx == e.$1
                                          ? navy
                                          : const Color(0xFF8A8F98),
                                      size: 26,
                                    ),
                                    if (e.$1 == 4 && app.unread > 0)
                                      Positioned(
                                        right: -3,
                                        top: -2,
                                        child: Container(
                                          width: 11,
                                          height: 11,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFD0021B),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                e.$2.$3,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: idx == e.$1
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: idx == e.$1
                                      ? navy
                                      : const Color(0xFF8A8F98),
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
        ),
      ),
    );
  }
}

Route<dynamic> _route(RouteSettings s, int tab) {
  final routeName = s.name ?? '/';
  CleverTapAnalytics.instance.trackScreen(routeName, props: {'tab': tab});
  Widget w;
  final a = s.arguments;
  switch (s.name) {
    case '/':
      w = [
        const HomePage(),
        const SearchPage(),
        const TripsPage(),
        const StatusPage(),
        const MorePage(),
      ][tab];
      break;
    case 'profile':
      w = const ProfilePage();
      break;
    case 'results':
      w = const ResultsPage();
      break;
    case 'passengers':
      w = const PassengersPage();
      break;
    case 'addons':
      w = const AddonsPage();
      break;
    case 'payment':
      w = const PaymentPage();
      break;
    case 'confirmation':
      w = ConfirmationPage(ref: a as String);
      break;
    case 'trip':
      w = TripDetailPage(ref: a as String);
      break;
    case 'checkin':
      w = CheckInPage(ref: a as String?);
      break;
    case 'pass':
      w = BoardingPassPage(ref: a as String);
      break;
    case 'status':
      w = StatusPage(initial: a as String?);
      break;
    case 'offer':
      w = OfferPage(id: a as String);
      break;
    case 'notifications':
      w = const NotificationsPage();
      break;
    case 'miles':
      w = const MilesPage();
      break;
    default:
      w = const HomePage();
  }
  return PageRouteBuilder(
    settings: s,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, __, ___) => w,
    transitionsBuilder: (_, anim, __, child) {
      final c = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: c,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(.06, 0),
            end: Offset.zero,
          ).animate(c),
          child: child,
        ),
      );
    },
  );
}

/// Opens a route in the currently active tab (or switches tab when [tab] is given).
void openRoute(BuildContext c, String route, [Object? args, int? tab]) {
  final app = c.app;
  CleverTapAnalytics.instance.trackTap(
    source: 'open_route',
    screen: route,
    props: {'tab': tab ?? app.tab.value},
  );
  if (tab != null && tab != app.tab.value) {
    app.goTab(tab, route, args);
  } else {
    app.navKeys[app.tab.value].currentState?.pushNamed(route, arguments: args);
  }
}

/// Routes a notification (or deep link) to the matching screen.
void goNotif(BuildContext c, Notif n) {
  CleverTapAnalytics.instance.trackEvent('notification_opened', {
    'route': n.route,
    'title': n.title,
    'id': n.id,
  });
  c.app.markRead(n);
  switch (n.route) {
    case 'trip':
      openRoute(c, 'trip', n.arg, 2);
    case 'checkin':
      openRoute(c, 'checkin', n.arg, 2);
    case 'pass':
      openRoute(c, 'pass', n.arg, 2);
    case 'offer':
      openRoute(c, 'offer', n.arg, 0);
    default:
      c.app.goTab(0);
  }
}
