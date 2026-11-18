import 'dart:math';
import 'package:flutter/material.dart';
import 'models.dart';
import 'state.dart';
import 'ui.dart';

Future<DateTime?> pickDate(BuildContext c, DateTime init, {DateTime? first}) =>
    showDatePicker(
      context: c,
      initialDate: init,
      firstDate: first ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 360)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: navy, secondary: gold),
        ),
        child: child!,
      ),
    );

// ================================================================ SEARCH
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool beta = false;
  String promo = '';

  Future<void> _pickAirport(bool isFrom) async {
    final a = context.app;
    final r = await sheet<String>(context, (ctx) {
      var q = '';
      return StatefulBuilder(
        builder: (ctx, set) {
          final list = airports
              .where(
                (x) => '${x.city} ${x.code} ${x.country}'
                    .toLowerCase()
                    .contains(q.toLowerCase()),
              )
              .toList();
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * .75,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                  child: TextField(
                    autofocus: false,
                    onChanged: (v) => set(() => q = v),
                    decoration: InputDecoration(
                      hintText: isFrom
                          ? 'Search departure city'
                          : 'Search arrival city',
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final x in list)
                        ListTile(
                          leading: Text(
                            x.code,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: navy,
                            ),
                          ),
                          title: Text(
                            x.city,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('${x.name}, ${x.country}'),
                          onTap: () => Navigator.pop(ctx, x.code),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
    if (r != null) {
      if (isFrom) {
        a.from = r;
      } else {
        a.to = r;
      }
      a.notify();
    }
  }

  void _passengers() {
    final a = context.app;
    sheet(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Passengers & cabin', style: serif(21)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Adults',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Stepper2(
                    a.adults,
                    (v) {
                      set(() => a.adults = v);
                      a.notify();
                    },
                    min: 1,
                    max: 6,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in cabins)
                    ChoiceChip(
                      label: Text(
                        c,
                        style: TextStyle(
                          color: a.cabin == c ? Colors.white : ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: a.cabin == c,
                      selectedColor: navy,
                      showCheckmark: false,
                      onSelected: (_) {
                        set(() => a.cabin = c);
                        a.notify();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              PrimaryBtn('Done', onTap: () => Navigator.pop(ctx)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = context.app;
    final from = airportBy(a.from), to = airportBy(a.to);
    final oneWay = a.tripType != 'Return';

    Widget tab(String t, VoidCallback f, bool sel) => Expanded(
      child: GestureDetector(
        onTap: f,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFE6EEFB) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            t,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
              color: sel ? navy : ink,
            ),
          ),
        ),
      ),
    );

    Widget tile(Widget child, VoidCallback f, {double h = 78}) => Expanded(
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: f,
          child: Container(
            height: h,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: child,
          ),
        ),
      ),
    );

    Widget city(String label, Airport? ap) => ap == null
        ? Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: muted),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(color: muted, fontSize: 13)),
              Text(
                ap.code,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: navy,
                  height: 1.1,
                ),
              ),
              Text(ap.city, style: const TextStyle(fontSize: 14, color: navy)),
            ],
          );

    Widget date(
      String label,
      DateTime? d,
      VoidCallback f, {
      bool disabled = false,
    }) => tile(
      Text(
        d == null ? label : fmtDate(d),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: d == null ? 16 : 15,
          color: disabled ? line : (d == null ? muted : navy),
          fontWeight: d == null ? FontWeight.w400 : FontWeight.w700,
        ),
      ),
      disabled ? () {} : f,
      h: 70,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              18,
              MediaQuery.of(context).padding.top - 10,
              16,
              8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Book Flights',
                        style: serif(27, c: navy, w: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => a.goTab(4, 'profile'),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: navy, width: 2),
                    ),
                    child: const Icon(Icons.person, color: navy, size: 26),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      tab('Return', () {
                        a.tripType = 'Return';
                        a.notify();
                      }, a.tripType == 'Return'),
                      tab('One-way', () {
                        a.tripType = 'One-way';
                        a.notify();
                      }, a.tripType == 'One-way'),
                      tab('Multi-city', () {
                        a.tripType = 'Multi-city';
                        a.notify();
                        toast(
                          context,
                          'Multi-city is simulated as a single leg in this demo',
                        );
                      }, a.tripType == 'Multi-city'),
                      tab('Saved flights', _saved, false),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      children: [
                        tile(
                          city('From', from),
                          () => _pickAirport(true),
                          h: 130,
                        ),
                        Container(width: 2, height: 130, color: bg),
                        tile(city('To', to), () => _pickAirport(false), h: 130),
                      ],
                    ),
                    GestureDetector(
                      onTap: a.swap,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: gold, width: 1.5),
                        ),
                        child: const Icon(Icons.swap_horiz, color: gold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Column(
                  children: [
                    Row(
                      children: [
                        date('Departure date', a.depart, () async {
                          final d = await pickDate(context, a.depart);
                          if (d != null) {
                            a.depart = d;
                            if (a.ret != null && a.ret!.isBefore(d))
                              a.ret = d.add(const Duration(days: 7));
                            a.notify();
                          }
                        }),
                        Container(width: 2, height: 70, color: bg),
                        date('Return date', oneWay ? null : a.ret, () async {
                          final d = await pickDate(
                            context,
                            a.ret ?? a.depart,
                            first: a.depart,
                          );
                          if (d != null) {
                            a.ret = d;
                            a.notify();
                          }
                        }, disabled: oneWay),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        tile(
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          '${a.adults} ${a.adults == 1 ? 'Adult' : 'Adults'}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: navy,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' in',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                a.cabin,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: navy,
                                ),
                              ),
                            ],
                          ),
                          _passengers,
                          h: 92,
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _promo,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Text(
                          promo.isEmpty
                              ? 'Do you have a promo code?'
                              : 'Promo code: $promo',
                          style: const TextStyle(
                            color: navy,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Try our new booking experience  ',
                                  ),
                                  WidgetSpan(
                                    child: Icon(
                                      Icons.info,
                                      size: 19,
                                      color: muted,
                                    ),
                                  ),
                                ],
                              ),
                              style: TextStyle(fontSize: 16, color: ink),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFA400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'BETA',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Switch(
                            value: beta,
                            activeTrackColor: navy,
                            onChanged: (v) {
                              setState(() => beta = v);
                              toast(
                                context,
                                v
                                    ? 'New booking experience enabled (demo)'
                                    : 'Classic booking experience',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 62,
                      child: ElevatedButton(
                        onPressed: () {
                          if (a.from == a.to) {
                            toast(
                              context,
                              'Origin and destination must be different',
                            );
                            return;
                          }
                          Navigator.of(context).pushNamed('results');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(3)),
                          ),
                        ),
                        child: const Text(
                          'SEARCH',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    InkWell(
                      onTap: () => Navigator.of(context).pushNamed('results'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: sqBlue, width: 1.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
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
                                    'Get best flights quicker',
                                    style: TextStyle(
                                      color: sqBlue,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Search and compare fares easier',
                                    style: TextStyle(color: ink, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: muted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _promo() {
    final c = TextEditingController(text: promo);
    sheet(
      context,
      (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Promo code', style: serif(21)),
            const SizedBox(height: 14),
            Field('Enter code', c: c, icon: Icons.local_offer_outlined),
            PrimaryBtn(
              'Apply',
              onTap: () {
                setState(() => promo = c.text.trim().toUpperCase());
                Navigator.pop(ctx);
                toast(
                  context,
                  promo.isEmpty
                      ? 'Promo code removed'
                      : 'Code $promo applied (demo)',
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _saved() {
    final a = context.app;
    sheet(
      context,
      (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saved flights', style: serif(21)),
            const SizedBox(height: 10),
            for (final r in const [
              ('BOM', 'SIN'),
              ('SIN', 'SYD'),
              ('DEL', 'LHR'),
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bookmark, color: gold),
                title: Text(
                  '${airportBy(r.$1).city} to ${airportBy(r.$2).city}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${r.$1} - ${r.$2}'),
                onTap: () {
                  a.from = r.$1;
                  a.to = r.$2;
                  a.notify();
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ================================================================ RESULTS
class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});
  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  bool loading = true;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = context.app;
    final list = searchFlights(a.from, a.to, a.cabin);
    final f = airportBy(a.from), t = airportBy(a.to);
    return Screen(
      title: '${f.code}  to  ${t.code}',
      body: Column(
        children: [
          Container(
            color: navy,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: gold, size: 15),
                const SizedBox(width: 6),
                Text(
                  '${fmtShort(a.depart)}${a.tripType == 'Return' && a.ret != null ? ' - ${fmtShort(a.ret!)}' : ''}',
                  style: const TextStyle(color: Colors.white),
                ),
                const Spacer(),
                Text(
                  '${a.adults} pax  |  ${a.cabin}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const _Searching()
                : ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      Text(
                        '${list.length} flights found',
                        style: const TextStyle(
                          color: muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (var i = 0; i < list.length; i++)
                        _card(context, list[i], i == 2),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext c, Flight f, bool cheapest) {
    final a = c.app;
    return CardBox(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                f.number,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: navy,
                ),
              ),
              const SizedBox(width: 8),
              Pill(f.cabin, color: navy2),
              const Spacer(),
              if (cheapest) const Pill('Best price', color: good),
            ],
          ),
          const SizedBox(height: 16),
          RouteRow(
            from: f.from,
            to: f.to,
            dep: f.dep,
            arr: f.dayOffset > 0 ? '${f.arr} +${f.dayOffset}' : f.arr,
            dur: f.duration,
          ),
          const SizedBox(height: 12),
          Text(
            '${f.aircraft}  |  Meal included  |  ${f.cabin == 'Economy' ? '30kg' : '40kg'} baggage',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          const Divider(height: 26, color: line),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'per passenger',
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                  Text(money(f.price), style: serif(26)),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 130,
                child: PrimaryBtn(
                  'Select',
                  goldStyle: true,
                  onTap: () {
                    a.startDraft(f);
                    Navigator.of(c).pushNamed('passengers');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Searching extends StatefulWidget {
  const _Searching();
  @override
  State<_Searching> createState() => _SearchingState();
}

class _SearchingState extends State<_Searching>
    with SingleTickerProviderStateMixin {
  late final c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 220,
          height: 50,
          child: AnimatedBuilder(
            animation: c,
            builder: (_, __) => Stack(
              alignment: Alignment.center,
              children: [
                Container(height: 2, color: line),
                Align(
                  alignment: Alignment(-1 + 2 * c.value, 0),
                  child: Transform.rotate(
                    angle: pi / 2,
                    child: const Icon(Icons.flight, color: gold, size: 34),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Finding the best flights...',
          style: TextStyle(color: muted, fontSize: 15),
        ),
      ],
    ),
  );
}

// ================================================================ PASSENGERS
class PassengersPage extends StatefulWidget {
  const PassengersPage({super.key});
  @override
  State<PassengersPage> createState() => _PassengersPageState();
}

class _PassengersPageState extends State<PassengersPage> {
  late final List<Map<String, TextEditingController>> cs;
  @override
  void initState() {
    super.initState();
    final pax = context.app.draftPax;
    cs = [for (final p in pax) _mk(p)];
  }

  Map<String, TextEditingController> _mk(PassengerInfo p) => {
    'first': TextEditingController(text: p.first),
    'last': TextEditingController(text: p.last),
    'dob': TextEditingController(text: p.dob),
    'nat': TextEditingController(text: p.nationality),
    'pass': TextEditingController(text: p.passport),
    'email': TextEditingController(text: p.email),
    'phone': TextEditingController(text: p.phone),
  };

  void _sync() {
    final a = context.app;
    for (var i = 0; i < cs.length; i++) {
      final p = a.draftPax[i], c = cs[i];
      p.first = c['first']!.text.trim();
      p.last = c['last']!.text.trim();
      p.dob = c['dob']!.text.trim();
      p.nationality = c['nat']!.text.trim();
      p.passport = c['pass']!.text.trim();
      p.email = c['email']!.text.trim();
      p.phone = c['phone']!.text.trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.app;
    final f = a.flight!;
    return Screen(
      title: 'Passenger details',
      bottom: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total fare',
                style: TextStyle(fontSize: 11, color: muted),
              ),
              Text(money(a.grandTotal), style: serif(22)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: PrimaryBtn(
              'Continue',
              onTap: () {
                _sync();
                for (var i = 0; i < a.draftPax.length; i++) {
                  final p = a.draftPax[i];
                  if (p.first.isEmpty || p.last.isEmpty) {
                    toast(
                      context,
                      'Please enter the name of passenger ${i + 1}',
                    );
                    return;
                  }
                }
                final lead = a.draftPax.first;
                if (!lead.email.contains('@')) {
                  toast(context, 'Enter a valid contact email');
                  return;
                }
                Navigator.of(context).pushNamed('addons');
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const StepBar(0, ['Passengers', 'Add-ons', 'Payment']),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                CardBox(
                  color: goldSoft,
                  child: Row(
                    children: [
                      const Icon(Icons.flight, color: navy),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${f.number}  |  ${airportBy(f.from).city} to ${airportBy(f.to).city}\n${fmtDate(a.depart)}  |  ${f.dep}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < cs.length; i++) _form(context, i),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _form(BuildContext c, int i) {
    final a = c.app;
    final p = a.draftPax[i];
    final k = cs[i];
    return CardBox(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Passenger ${i + 1}${i == 0 ? ' (Lead)' : ''}',
                style: serif(17),
              ),
              const Spacer(),
              if (i > 0 && a.profile.saved.isNotEmpty)
                TextButton.icon(
                  onPressed: () => sheet(
                    c,
                    (ctx) => Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Saved passengers', style: serif(19)),
                          const SizedBox(height: 10),
                          for (final s in a.profile.saved)
                            ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: goldSoft,
                                child: Icon(Icons.person, color: navy),
                              ),
                              title: Text(s.fullName),
                              subtitle: Text(s.passport),
                              onTap: () {
                                setState(() {
                                  p.title = s.title;
                                  k['first']!.text = s.first;
                                  k['last']!.text = s.last;
                                  k['dob']!.text = s.dob;
                                  k['nat']!.text = s.nationality;
                                  k['pass']!.text = s.passport;
                                });
                                Navigator.pop(ctx);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.bookmark_outline, size: 18),
                  label: const Text('Saved'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Pick<String>('Title', p.title, const [
            'Mr',
            'Ms',
            'Mrs',
            'Dr',
            'Mstr',
            'Miss',
          ], (v) => setState(() => p.title = v)),
          Field('First name', c: k['first']),
          Field('Last name', c: k['last']),
          Row(
            children: [
              Expanded(
                child: Field(
                  'Date of birth',
                  c: k['dob'],
                  hint: 'DD/MM/YYYY',
                  icon: Icons.cake_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Field('Nationality', c: k['nat'])),
            ],
          ),
          Field('Passport number', c: k['pass'], icon: Icons.badge_outlined),
          if (i == 0) ...[
            Field(
              'Contact email',
              c: k['email'],
              type: TextInputType.emailAddress,
              icon: Icons.mail_outline,
            ),
            Field(
              'Mobile number',
              c: k['phone'],
              type: TextInputType.phone,
              icon: Icons.phone_outlined,
            ),
          ],
        ],
      ),
    );
  }
}

// ================================================================ ADD-ONS
const mealOptions = [
  'Standard',
  'Vegetarian',
  'Vegan',
  'Halal',
  'Gluten-free',
  'Kids meal',
  'Book the Cook: Lobster thermidor',
];

class AddonsPage extends StatefulWidget {
  const AddonsPage({super.key});
  @override
  State<AddonsPage> createState() => _AddonsPageState();
}

class _AddonsPageState extends State<AddonsPage> {
  @override
  Widget build(BuildContext context) {
    final a = context.app;
    final f = a.flight!;
    return Screen(
      title: 'Add-ons',
      bottom: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Total', style: TextStyle(fontSize: 11, color: muted)),
              Text(money(a.grandTotal), style: serif(22)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: PrimaryBtn(
              'Continue to payment',
              onTap: () => Navigator.of(context).pushNamed('payment'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const StepBar(1, ['Passengers', 'Add-ons', 'Payment']),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _sec(
                  Icons.event_seat,
                  'Seats',
                  a.draftSeats.isEmpty
                      ? 'Seat assigned at check-in (free)'
                      : 'Selected: ${a.draftSeats.join(', ')}',
                ),
                CardBox(
                  child: Column(
                    children: [
                      for (var i = 0; i < a.draftPax.length; i++)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: goldSoft,
                            child: Icon(Icons.person, color: navy),
                          ),
                          title: Text(a.draftPax[i].fullName),
                          trailing: Pill(
                            i < a.draftSeats.length
                                ? a.draftSeats[i]
                                : 'Not selected',
                            color: i < a.draftSeats.length ? good : muted,
                          ),
                        ),
                      const SizedBox(height: 6),
                      PrimaryBtn(
                        'Select seats',
                        outline: true,
                        icon: Icons.event_seat,
                        onTap: () => _seats(context, f),
                      ),
                    ],
                  ),
                ),
                _sec(
                  Icons.restaurant,
                  'Meal',
                  'Special meals are free. Book the Cook adds SGD 35 per person.',
                ),
                CardBox(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in mealOptions)
                        ChoiceChip(
                          label: Text(
                            m,
                            style: TextStyle(
                              fontSize: 13,
                              color: a.draftMeal == m ? Colors.white : ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selected: a.draftMeal == m,
                          selectedColor: navy,
                          showCheckmark: false,
                          onSelected: (_) {
                            a.draftMeal = m;
                            a.notify();
                          },
                        ),
                    ],
                  ),
                ),
                _sec(
                  Icons.luggage,
                  'Extra baggage',
                  'SGD 9 per kg, in 5kg steps. Base allowance included.',
                ),
                CardBox(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.draftBaggage == 0
                                  ? 'No extra baggage'
                                  : '+${a.draftBaggage} kg',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              a.draftBaggage == 0
                                  ? 'Base 30kg included'
                                  : money(a.draftBaggage * 9.0),
                              style: const TextStyle(color: muted),
                            ),
                          ],
                        ),
                      ),
                      Stepper2(
                        a.draftBaggage,
                        (v) {
                          a.draftBaggage = v;
                          a.notify();
                        },
                        step: 5,
                        max: 30,
                      ),
                    ],
                  ),
                ),
                _sec(
                  Icons.health_and_safety,
                  'Travel insurance',
                  'Cover for cancellations, delays and medical cover.',
                ),
                CardBox(
                  onTap: () {
                    a.draftInsurance = !a.draftInsurance;
                    a.notify();
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Travel Insurance Plus',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'SGD 24 per passenger  |  Up to SGD 100,000 cover',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: a.draftInsurance,
                        activeColor: navy,
                        activeTrackColor: gold,
                        onChanged: (v) {
                          a.draftInsurance = v;
                          a.notify();
                        },
                      ),
                    ],
                  ),
                ),
                const H('Price summary'),
                _summary(a),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sec(IconData i, String t, String sub) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(i, color: gold),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t, style: serif(18)),
              Text(sub, style: const TextStyle(color: muted, fontSize: 13)),
            ],
          ),
        ),
      ],
    ),
  );

  void _seats(BuildContext c, Flight f) {
    final a = c.app;
    var sel = List<String>.of(a.draftSeats);
    sheet(
      c,
      (ctx) => StatefulBuilder(
        builder: (ctx, set) => SizedBox(
          height: MediaQuery.of(ctx).size.height * .86,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Choose ${a.adults == 1 ? 'your seat' : '${a.adults} seats'}',
                  style: serif(20),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: SeatMap(
                    cabin: a.cabin,
                    seed: '${f.number}${a.depart.day}',
                    selected: sel,
                    max: a.adults,
                    onChanged: (v) => set(() => sel = v),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: PrimaryBtn(
                  sel.isEmpty ? 'Skip for now' : 'Confirm ${sel.join(', ')}',
                  goldStyle: true,
                  onTap: () {
                    a.draftSeats = sel;
                    a.notify();
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _summary(AppState a) => CardBox(
  child: Column(
    children: [
      KV('Fare (${a.adults} x ${money(a.flight!.price)})', money(a.fareTotal)),
      KV('Taxes & surcharges', money(a.taxes)),
      if (a.addonsTotal > 0) KV('Add-ons', money(a.addonsTotal)),
      const Divider(color: line),
      KV('Total', money(a.grandTotal), bold: true),
    ],
  ),
);

// ================================================================ PAYMENT
class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String method = 'Card';
  String bank = 'Merlion National Bank';
  final card = TextEditingController(text: '4111 1111 1111 1111');
  final name = TextEditingController(text: 'ALEX MORGAN');
  final exp = TextEditingController(text: '12/29');
  final cvv = TextEditingController(text: '123');
  final upi = TextEditingController(text: 'alex.morgan@merlionpay');
  bool busy = false;

  Future<void> pay() async {
    if (method == 'Card' && card.text.replaceAll(' ', '').length < 12) {
      toast(context, 'Enter a valid card number');
      return;
    }
    if (method == 'UPI' && !upi.text.contains('@')) {
      toast(context, 'Enter a valid UPI ID, e.g. name@bank');
      return;
    }
    final a = context.app;
    final nav = Navigator.of(context);
    setState(() => busy = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 34, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: gold),
                  SizedBox(height: 18),
                  Text(
                    'Processing secure payment',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Please do not close the app',
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    final b = a.confirmBooking(method);
    Navigator.of(context, rootNavigator: true).pop(); // dialog
    nav.pushNamedAndRemoveUntil(
      'confirmation',
      (r) => r.isFirst,
      arguments: b.ref,
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = context.app;
    return Screen(
      title: 'Payment',
      bottom: PrimaryBtn(
        'Pay ${money(a.grandTotal)}',
        icon: Icons.lock_outline,
        goldStyle: true,
        loading: busy,
        onTap: pay,
      ),
      body: Column(
        children: [
          const StepBar(2, ['Passengers', 'Add-ons', 'Payment']),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _summary(a),
                const H('Payment method'),
                Row(
                  children: [
                    for (final m in [
                      ('Card', Icons.credit_card),
                      ('UPI', Icons.qr_code_scanner),
                      ('Net Banking', Icons.account_balance),
                    ])
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => method = m.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: method == m.$1 ? navy : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: method == m.$1 ? navy : line,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  m.$2,
                                  color: method == m.$1 ? gold : muted,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  m.$1,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: method == m.$1 ? Colors.white : ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                CardBox(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Column(
                      key: ValueKey(method),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (method == 'Card') ...[
                          Field(
                            'Card number',
                            c: card,
                            type: TextInputType.number,
                            icon: Icons.credit_card,
                            onChanged: (v) {
                              final d = v.replaceAll(RegExp(r'\D'), '');
                              final g = [
                                for (var i = 0; i < d.length && i < 16; i += 4)
                                  d.substring(i, min(i + 4, d.length)),
                              ].join(' ');
                              if (g != v)
                                card.value = TextEditingValue(
                                  text: g,
                                  selection: TextSelection.collapsed(
                                    offset: g.length,
                                  ),
                                );
                            },
                          ),
                          Field(
                            'Name on card',
                            c: name,
                            icon: Icons.person_outline,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Field('Expiry', c: exp, hint: 'MM/YY'),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Field(
                                  'CVV',
                                  c: cvv,
                                  obscure: true,
                                  type: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (method == 'UPI') ...[
                          Field(
                            'UPI ID',
                            c: upi,
                            icon: Icons.alternate_email,
                            hint: 'name@bank',
                          ),
                          const Text(
                            'A collect request will be simulated. No real payment is made.',
                            style: TextStyle(color: muted, fontSize: 13),
                          ),
                        ],
                        if (method == 'Net Banking')
                          for (final b in const [
                            'Merlion National Bank',
                            'Harbour Trust Bank',
                            'Orchid Savings Bank',
                            'Summit Bank',
                          ])
                            RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              value: b,
                              groupValue: bank,
                              activeColor: navy,
                              title: Text(
                                b,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              secondary: const Icon(
                                Icons.account_balance,
                                color: muted,
                              ),
                              onChanged: (v) => setState(() => bank = v!),
                            ),
                      ],
                    ),
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 16, color: muted),
                    SizedBox(width: 6),
                    Text(
                      'Simulated payment. No data is sent anywhere.',
                      style: TextStyle(color: muted, fontSize: 12.5),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================ CONFIRMATION
class ConfirmationPage extends StatefulWidget {
  final String ref;
  const ConfirmationPage({super.key, required this.ref});
  @override
  State<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage>
    with SingleTickerProviderStateMixin {
  late final c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..forward();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.app;
    final b = a.byRef(widget.ref)!;
    final f = b.flight;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (d, _) {
        if (!d) Navigator.of(context).popUntil((r) => r.isFirst);
      },
      child: Screen(
        title: 'Booking confirmed',
        canPop: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => a.goTab(0),
          ),
        ],
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const SizedBox(height: 10),
                Center(
                  child: AnimatedBuilder(
                    animation: c,
                    builder: (_, __) {
                      final t = Curves.elasticOut.transform(
                        (c.value * 2.2).clamp(0, 1),
                      );
                      return SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            for (var i = 0; i < 2; i++)
                              Opacity(
                                opacity:
                                    (1 - ((c.value * 2 + i * .4) % 1)).clamp(
                                      0,
                                      1,
                                    ) *
                                    .4,
                                child: Container(
                                  width: 90 + 40 * ((c.value * 2 + i * .4) % 1),
                                  height:
                                      90 + 40 * ((c.value * 2 + i * .4) % 1),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: good, width: 2),
                                  ),
                                ),
                              ),
                            Transform.scale(
                              scale: t,
                              child: Container(
                                width: 86,
                                height: 86,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: good,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    'You\'re all set, ${a.profile.first}!',
                    style: serif(26),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'A confirmation has been added to your notifications.',
                    style: TextStyle(color: muted),
                  ),
                ),
                const SizedBox(height: 20),
                CardBox(
                  color: navy,
                  child: Column(
                    children: [
                      const Text(
                        'BOOKING REFERENCE',
                        style: TextStyle(
                          color: Colors.white60,
                          letterSpacing: 2,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        b.ref,
                        style: serif(38, c: gold).copyWith(letterSpacing: 6),
                      ),
                      const SizedBox(height: 8),
                      const Pill('CONFIRMED', color: Color(0xFF55D69A)),
                    ],
                  ),
                ),
                CardBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RouteRow(
                        from: f.from,
                        to: f.to,
                        dep: f.dep,
                        arr: f.arr,
                        dur: f.duration,
                      ),
                      const Divider(height: 28, color: line),
                      KV('Flight', '${f.number}  |  ${f.cabin}'),
                      KV('Departure', fmtDate(b.date)),
                      if (b.returnDate != null)
                        KV('Return', fmtDate(b.returnDate!)),
                      KV(
                        'Seats',
                        b.seats.isEmpty ? 'At check-in' : b.seats.join(', '),
                      ),
                      KV('Meal', b.meal),
                      if (b.baggageKg > 0)
                        KV('Extra baggage', '${b.baggageKg} kg'),
                      KV(
                        'Insurance',
                        b.insurance ? 'Travel Insurance Plus' : 'None',
                      ),
                      KV('Paid via', b.method),
                      KV('Total paid', money(b.total), bold: true),
                    ],
                  ),
                ),
                CardBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Passengers', style: serif(17)),
                      const SizedBox(height: 8),
                      for (final (i, p) in b.pax.indexed)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const CircleAvatar(
                            radius: 16,
                            backgroundColor: goldSoft,
                            child: Icon(Icons.person, size: 18, color: navy),
                          ),
                          title: Text(
                            '${p.title} ${p.fullName}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Passport ${p.passport.isEmpty ? '-' : p.passport}',
                          ),
                          trailing: Text(
                            i < b.seats.length ? b.seats[i] : '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: navy,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                PrimaryBtn(
                  'Manage booking',
                  icon: Icons.luggage,
                  onTap: () => a.goTab(2, 'trip', b.ref),
                ),
                const SizedBox(height: 10),
                PrimaryBtn(
                  'Back to home',
                  outline: true,
                  onTap: () => a.goTab(0),
                ),
                const SizedBox(height: 20),
              ],
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: c,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: _Confetti(c.value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Confetti extends CustomPainter {
  final double t;
  _Confetti(this.t);
  @override
  void paint(Canvas c, Size s) {
    if (t >= 1) return;
    final r = Random(11);
    for (var i = 0; i < 46; i++) {
      final x = r.nextDouble() * s.width;
      final sp = .5 + r.nextDouble();
      final y = -20 + (t * sp * (s.height + 60));
      final col = [
        gold,
        navy2,
        const Color(0xFF55D69A),
        const Color(0xFFE8D29A),
      ][i % 4];
      c.save();
      c.translate(x + sin(t * 8 + i) * 14, y);
      c.rotate(t * 10 + i);
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -2, 9, 5),
          const Radius.circular(1.5),
        ),
        Paint()..color = col.withValues(alpha: 1 - t * .7),
      );
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti o) => o.t != t;
}
