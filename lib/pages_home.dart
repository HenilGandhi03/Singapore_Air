import 'package:flutter/material.dart';
import 'brand.dart';
import 'main.dart';
import 'models.dart';
import 'state.dart';
import 'ui.dart';

String daysLabel(DateTime d) {
  final t = DateTime.now();
  final n = DateTime(
    d.year,
    d.month,
    d.day,
  ).difference(DateTime(t.year, t.month, t.day)).inDays;
  if (n <= 0) return 'Today';
  if (n == 1) return 'Tomorrow';
  return 'In $n days';
}

void openBoardingPass(BuildContext c) {
  final app = c.app;
  final ready = app.upcoming.where((b) => b.checkedIn).toList();
  if (ready.isNotEmpty) {
    openRoute(c, 'pass', ready.first.ref, 2);
    return;
  }
  sheet(
    c,
    (ctx) => Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_2, size: 52, color: gold),
          const SizedBox(height: 10),
          Text('No boarding pass yet', style: serif(21)),
          const SizedBox(height: 8),
          const Text(
            'Check in for an upcoming flight and your digital boarding pass will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          PrimaryBtn(
            'Check in now',
            icon: Icons.how_to_reg,
            onTap: () {
              Navigator.pop(ctx);
              openRoute(c, 'checkin', null, 2);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

const _heroes = [
  (
    'hero1',
    'The New First Class. Defining The Exceptional.',
    'Quiet luxury meets exceptional comfort in your private sanctuary.',
    0xFF3A4660,
    0xFF1B2335,
    'sydney',
  ),
  (
    'hero2',
    'Cherry blossom season awaits.',
    'Fly to Tokyo with exclusive member fares this spring.',
    0xFF8E2C5B,
    0xFF1B2A55,
    'tokyo',
  ),
  (
    'hero3',
    'Island escape to Bali.',
    'Return fares from SGD 320. Book by month end.',
    0xFF0E6E7E,
    0xFF002A77,
    'bali',
  ),
  (
    'hero4',
    'Summer down under.',
    'Sydney from SGD 1,180 for KrisFlyer members.',
    0xFFB4541F,
    0xFF002A77,
    'sydney',
  ),
  (
    'hero5',
    'Weekend in London.',
    'Non-stop flights, now on sale.',
    0xFF3B3F7A,
    0xFF002A77,
    'london',
  ),
];

const _fares = [
  ('Ho Chi Minh City', 'SGN', 255, 0xFF6B8E3A, 0xFF2B4A1F),
  ('Sydney', 'SYD', 649, 0xFFB4541F, 0xFF3A2A50),
  ('Kuala Lumpur', 'KUL', 189, 0xFFD0902A, 0xFF3A2A50),
  ('Bangkok', 'BKK', 298, 0xFF8E2C5B, 0xFF1B2A55),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final pc = PageController();
  final pc2 = PageController(viewportFraction: .9);
  int page = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final nt = app.nextTrip;
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = (screenHeight * 0.28).clamp(240.0, 300.0).toDouble();
    final heroImageHeight = (heroHeight * 0.75).toDouble();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ---------------- white app header Home Screen
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top - 10,
              16,
              8,
            ),
            child: Row(
              children: [
                Transform.scale(
                  scale: 1.5,
                  alignment: Alignment.centerLeft,
                  child: SiaLogo(height: 42),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => openRoute(context, 'notifications'),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.notifications_none,
                          color: navy,
                          size: 28,
                        ),
                      ),
                      if (app.unread > 0)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD0021B),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${app.unread}',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => app.goTab(4, 'profile'),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: muted, width: 2),
                    ),
                    child: const Icon(Icons.person, color: muted, size: 26),
                  ),
                ),
              ],
            ),
          ),
          // ---------------- Gradient welcome bar
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 2, 77, 191),
                  Color.fromARGB(255, 105, 168, 198),
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Good morning, ${app.profile.first}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => app.goTab(4, 'miles'),
                  child: Text(
                    '${app.profile.tier}  |  ${num0(app.miles)} mi',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          // ---------------- main scrollable content
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ---------------- hero carousel with title overlay
                SizedBox(
                  height: heroHeight,
                  child: PageView.builder(
                    controller: pc,
                    itemCount: _heroes.length,
                    onPageChanged: (i) => setState(() => page = i),
                    itemBuilder: (_, i) {
                      final h = _heroes[i];
                      return GestureDetector(
                        onTap: () => openRoute(context, 'offer', h.$6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Photo(
                              h.$1,
                              c1: h.$4,
                              c2: h.$5,
                              height: heroImageHeight,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: .55),
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(18),
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  h.$2,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                              child: Text(
                                h.$3,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: ink,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // ---------------- hero carousel dots
                _dots(_heroes.length, page),
                // ---------------- spacer
                const SizedBox(height: 18),
                // ---------------- plan your next getaway
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => app.goTab(1),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: sqBlue, width: 1.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Row(
                        children: [
                          Container(
                            // padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEAF0FA),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: sqBlue,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Plan your next getaway',
                                  style: TextStyle(
                                    color: sqBlue,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Get destination recommendations',
                                  style: TextStyle(color: muted, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ---------------- best fares
                _title('Find our Best Fares', 'See all', () => app.goTab(1)),
                SizedBox(
                  height: 260,
                  child: PageView.builder(
                    controller: pc2,
                    padEnds: false,
                    itemCount: _fares.length,
                    itemBuilder: (_, i) {
                      final f = _fares[i];
                      return Padding(
                        padding: EdgeInsets.only(
                          left: i == 0 ? 14 : 4,
                          right: 8,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            app.from = 'SIN';
                            app.to = f.$2;
                            app.notify();
                            app.goTab(1, 'results');
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Material(
                                elevation: 3,
                                borderRadius: BorderRadius.circular(6),
                                child: Photo(
                                  f.$2,
                                  c1: f.$4,
                                  c2: f.$5,
                                  height: 180,
                                  radius: 6,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          f.$1,
                                          style: const TextStyle(
                                            color: navy,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const Text(
                                          'Economy',
                                          style: TextStyle(
                                            color: navy,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'FROM',
                                        style: TextStyle(
                                          color: navy,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        'SGD ${f.$3}*',
                                        style: serif(22, w: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // ---------------- promo banner
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                  child: GestureDetector(
                    onTap: () => openRoute(context, 'offer', 'tokyo'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Photo(
                          'promo',
                          c1: 0xFFB08A78,
                          c2: 0xFF6E5A64,
                          height: 140,
                          radius: 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'MADE OF',
                                style: TextStyle(
                                  color: Colors.white,
                                  letterSpacing: 4,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'EVERY WORLD',
                                style: serif(
                                  30,
                                  c: Colors.white,
                                  w: FontWeight.w400,
                                ),
                              ),
                              const Text(
                                'YOU CAN DREAM OF',
                                style: TextStyle(
                                  color: Colors.white,
                                  letterSpacing: 4,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Discover the new travel experience',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                        const Text(
                          'Where flying becomes exceptional',
                          style: TextStyle(fontSize: 16, color: ink),
                        ),
                      ],
                    ),
                  ),
                ),

                //                 // ---------------- upcoming trip
                // if (nt != null) ...[
                //   _title('Your upcoming trip', 'See all', () => app.goTab(2)),
                //   Padding(
                //     padding: const EdgeInsets.symmetric(horizontal: 14),
                //     child: _tripCard(context, nt),
                //   ),
                // ],
                // // ---------------- quick actions
                // _title('Quick actions'),
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 14),
                //   child: GridView.count(
                //     crossAxisCount: 3,
                //     shrinkWrap: true,
                //     physics: const NeverScrollableScrollPhysics(),
                //     crossAxisSpacing: 10,
                //     mainAxisSpacing: 10,
                //     childAspectRatio: 1.05,
                //     children: [
                //       _qa(
                //         Icons.flight_takeoff,
                //         'Book a Flight',
                //         () => app.goTab(1),
                //       ),
                //       _qa(Icons.luggage, 'Manage Booking', () => app.goTab(2)),
                //       _qa(
                //         Icons.how_to_reg,
                //         'Check In',
                //         () => openRoute(context, 'checkin', null, 2),
                //       ),
                //       _qa(Icons.radar, 'Flight Status', () => app.goTab(3)),
                //       _qa(
                //         Icons.qr_code_2,
                //         'Boarding Pass',
                //         () => openBoardingPass(context),
                //       ),
                //       _qa(
                //         Icons.workspace_premium,
                //         'My Miles',
                //         () => app.goTab(4, 'miles'),
                //       ),
                //     ],
                //   ),
                // ),
                //
                const SizedBox(height: 20),

                Container(
                  color: const Color(0xFFF2F2F4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'STAR ALLIANCE',
                        style: TextStyle(
                          letterSpacing: 2,
                          color: ink,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.star_border_purple500, size: 20, color: muted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dots(int n, int cur) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < n; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == cur ? 26 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: i == cur ? navy : const Color(0xFF9AA0A6),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
      ],
    ),
  );

  Widget _title(String t, [String? action, VoidCallback? f]) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 26, 18, 14),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          t,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: f,
            child: Text(
              action,
              style: const TextStyle(
                color: navy,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    ),
  );

  Widget _qa(IconData i, String t, VoidCallback f) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    elevation: 2,
    child: InkWell(
      onTap: f,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(i, color: navy, size: 28),
          const SizedBox(height: 8),
          Text(
            t,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _tripCard(BuildContext c, Booking b) {
    final f = b.flight;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: navy,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => openRoute(c, 'trip', b.ref, 2),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${f.number}  |  ${f.cabin}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        daysLabel(b.date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                RouteRow(
                  from: f.from,
                  to: f.to,
                  dep: f.dep,
                  arr: f.arr,
                  dur: f.duration,
                  light: true,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.event, size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      fmtDate(b.date),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      b.ref,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: b.checkedIn
                          ? _tripBtn(
                              'Boarding pass',
                              Icons.qr_code_2,
                              () => openRoute(c, 'pass', b.ref, 2),
                              true,
                            )
                          : _tripBtn(
                              'Check in',
                              Icons.how_to_reg,
                              () => openRoute(c, 'checkin', b.ref, 2),
                              true,
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _tripBtn(
                        'Manage',
                        Icons.tune,
                        () => openRoute(c, 'trip', b.ref, 2),
                        false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tripBtn(String t, IconData i, VoidCallback f, bool solid) => SizedBox(
    height: 42,
    child: ElevatedButton.icon(
      onPressed: f,
      icon: Icon(i, size: 18),
      label: Text(t),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: solid ? Colors.white : Colors.white12,
        foregroundColor: solid ? navy : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    ),
  );
}
