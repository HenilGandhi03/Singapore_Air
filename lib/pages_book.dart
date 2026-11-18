import 'dart:math';
import 'package:flutter/material.dart';
import 'models.dart';
import 'state.dart';
import 'ui.dart';

Future<DateTime?> pickDate(BuildContext c, DateTime init, {DateTime? first}) => showDatePicker(
      context: c,
      initialDate: init,
      firstDate: first ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 360)),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: navy, secondary: gold)), child: child!),
    );

// ================================================================ SEARCH
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    final a = context.app;
    return Screen(
      title: 'Book a flight',
      canPop: false,
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Scenic(c1: 0xFF0E6E7E, c2: 0xFF0B1F44, height: 110, child: Padding(padding: const EdgeInsets.all(18), child: Align(alignment: Alignment.centerLeft, child: Text('Where would\nyou like to go?', style: serif(22, c: Colors.white))))),
        const SizedBox(height: 16),
        CardBox(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            Row(children: [
              for (final t in ['Return', 'One-way'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t),
                    selected: a.tripType == t,
                    selectedColor: navy,
                    labelStyle: TextStyle(color: a.tripType == t ? Colors.white : ink, fontWeight: FontWeight.w600),
                    showCheckmark: false,
                    onSelected: (_) {
                      a.tripType = t;
                      a.notify();
                    },
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            Stack(alignment: Alignment.centerRight, children: [
              Column(children: [
                Pick<String>('From', a.from, [for (final x in airports) x.code], (v) {
                  a.from = v;
                  a.notify();
                }, show: (c) => airportBy(c).label, icon: Icons.flight_takeoff),
                Pick<String>('To', a.to, [for (final x in airports) x.code], (v) {
                  a.to = v;
                  a.notify();
                }, show: (c) => airportBy(c).label, icon: Icons.flight_land),
              ]),
              Positioned(
                right: 44, top: 38,
                child: Material(
                  color: goldSoft, shape: const CircleBorder(),
                  child: InkWell(customBorder: const CircleBorder(), onTap: a.swap, child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.swap_vert, color: navy, size: 22))),
                ),
              ),
            ]),
            Row(children: [
              Expanded(
                child: Field('Departure', icon: Icons.calendar_today_outlined, readOnly: true, c: TextEditingController(text: fmtShort(a.depart)), onTap: () async {
                  final d = await pickDate(context, a.depart);
                  if (d != null) {
                    a.depart = d;
                    if (a.ret != null && a.ret!.isBefore(d)) a.ret = d.add(const Duration(days: 7));
                    a.notify();
                  }
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: a.tripType == 'Return'
                    ? Field('Return', icon: Icons.event_repeat, readOnly: true, c: TextEditingController(text: a.ret == null ? '' : fmtShort(a.ret!)), onTap: () async {
                        final d = await pickDate(context, a.ret ?? a.depart, first: a.depart);
                        if (d != null) {
                          a.ret = d;
                          a.notify();
                        }
                      })
                    : const Field('Return', icon: Icons.event_repeat, readOnly: true, hint: 'One-way'),
              ),
            ]),
            Row(children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: line)),
                  child: Row(children: [
                    const Icon(Icons.person_outline, color: muted, size: 20),
                    const SizedBox(width: 6),
                    const Expanded(child: Text('Passengers', style: TextStyle(color: muted))),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Stepper2(a.adults, (v) {
                  a.adults = v;
                  a.notify();
                }, min: 1, max: 6),
              ),
            ]),
            Pick<String>('Cabin class', a.cabin, cabins, (v) {
              a.cabin = v;
              a.notify();
            }, icon: Icons.airline_seat_recline_extra),
            const SizedBox(height: 4),
            PrimaryBtn('Search flights', icon: Icons.search, onTap: () {
              if (a.from == a.to) {
                toast(context, 'Origin and destination must be different');
                return;
              }
              Navigator.of(context).pushNamed('results');
            }),
          ]),
        ),
        const H('Popular routes'),
        for (final r in const [('BOM', 'SIN'), ('SIN', 'BKK'), ('DEL', 'LHR'), ('SIN', 'SYD')])
          CardBox(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            onTap: () {
              a.from = r.$1;
              a.to = r.$2;
              a.notify();
              toast(context, '${airportBy(r.$1).city} to ${airportBy(r.$2).city} selected');
            },
            child: Row(children: [
              const Icon(Icons.flight, color: gold),
              const SizedBox(width: 12),
              Expanded(child: Text('${airportBy(r.$1).city} to ${airportBy(r.$2).city}', style: const TextStyle(fontWeight: FontWeight.w600))),
              Text(money(searchFlights(r.$1, r.$2, 'Economy')[2].price), style: const TextStyle(color: navy, fontWeight: FontWeight.w800)),
            ]),
          ),
      ]),
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
      body: Column(children: [
        Container(
          color: navy,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(children: [
            const Icon(Icons.calendar_today, color: gold, size: 15),
            const SizedBox(width: 6),
            Text('${fmtShort(a.depart)}${a.tripType == 'Return' && a.ret != null ? ' - ${fmtShort(a.ret!)}' : ''}', style: const TextStyle(color: Colors.white)),
            const Spacer(),
            Text('${a.adults} pax  |  ${a.cabin}', style: const TextStyle(color: Colors.white70)),
          ]),
        ),
        Expanded(
          child: loading
              ? const _Searching()
              : ListView(padding: const EdgeInsets.all(18), children: [
                  Text('${list.length} flights found', style: const TextStyle(color: muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  for (var i = 0; i < list.length; i++) _card(context, list[i], i == 2),
                ]),
        ),
      ]),
    );
  }

  Widget _card(BuildContext c, Flight f, bool cheapest) {
    final a = c.app;
    return CardBox(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(f.number, style: const TextStyle(fontWeight: FontWeight.w800, color: navy)),
          const SizedBox(width: 8),
          Pill(f.cabin, color: navy2),
          const Spacer(),
          if (cheapest) const Pill('Best price', color: good),
        ]),
        const SizedBox(height: 16),
        RouteRow(from: f.from, to: f.to, dep: f.dep, arr: f.dayOffset > 0 ? '${f.arr} +${f.dayOffset}' : f.arr, dur: f.duration),
        const SizedBox(height: 12),
        Text('${f.aircraft}  |  Meal included  |  ${f.cabin == 'Economy' ? '30kg' : '40kg'} baggage', style: const TextStyle(color: muted, fontSize: 12)),
        const Divider(height: 26, color: line),
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('per passenger', style: TextStyle(fontSize: 11, color: muted)),
            Text(money(f.price), style: serif(26)),
          ]),
          const Spacer(),
          SizedBox(
            width: 130,
            child: PrimaryBtn('Select', goldStyle: true, onTap: () {
              a.startDraft(f);
              Navigator.of(c).pushNamed('passengers');
            }),
          ),
        ]),
      ]),
    );
  }
}

class _Searching extends StatefulWidget {
  const _Searching();
  @override
  State<_Searching> createState() => _SearchingState();
}

class _SearchingState extends State<_Searching> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 220, height: 50,
            child: AnimatedBuilder(
              animation: c,
              builder: (_, __) => Stack(alignment: Alignment.center, children: [
                Container(height: 2, color: line),
                Align(alignment: Alignment(-1 + 2 * c.value, 0), child: Transform.rotate(angle: pi / 2, child: const Icon(Icons.flight, color: gold, size: 34))),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Finding the best flights...', style: TextStyle(color: muted, fontSize: 15)),
        ]),
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
      bottom: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('Total fare', style: TextStyle(fontSize: 11, color: muted)),
          Text(money(a.grandTotal), style: serif(22)),
        ]),
        const SizedBox(width: 20),
        Expanded(
          child: PrimaryBtn('Continue', onTap: () {
            _sync();
            for (var i = 0; i < a.draftPax.length; i++) {
              final p = a.draftPax[i];
              if (p.first.isEmpty || p.last.isEmpty) {
                toast(context, 'Please enter the name of passenger ${i + 1}');
                return;
              }
            }
            final lead = a.draftPax.first;
            if (!lead.email.contains('@')) {
              toast(context, 'Enter a valid contact email');
              return;
            }
            Navigator.of(context).pushNamed('addons');
          }),
        ),
      ]),
      body: Column(children: [
        const StepBar(0, ['Passengers', 'Add-ons', 'Payment']),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(18), children: [
            CardBox(
              color: goldSoft,
              child: Row(children: [
                const Icon(Icons.flight, color: navy),
                const SizedBox(width: 10),
                Expanded(child: Text('${f.number}  |  ${airportBy(f.from).city} to ${airportBy(f.to).city}\n${fmtDate(a.depart)}  |  ${f.dep}', style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4))),
              ]),
            ),
            for (var i = 0; i < cs.length; i++) _form(context, i),
          ]),
        ),
      ]),
    );
  }

  Widget _form(BuildContext c, int i) {
    final a = c.app;
    final p = a.draftPax[i];
    final k = cs[i];
    return CardBox(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Passenger ${i + 1}${i == 0 ? ' (Lead)' : ''}', style: serif(17)),
          const Spacer(),
          if (i > 0 && a.profile.saved.isNotEmpty)
            TextButton.icon(
              onPressed: () => sheet(c, (ctx) => Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('Saved passengers', style: serif(19)),
                      const SizedBox(height: 10),
                      for (final s in a.profile.saved)
                        ListTile(
                          leading: const CircleAvatar(backgroundColor: goldSoft, child: Icon(Icons.person, color: navy)),
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
                    ]),
                  )),
              icon: const Icon(Icons.bookmark_outline, size: 18),
              label: const Text('Saved'),
            ),
        ]),
        const SizedBox(height: 8),
        Pick<String>('Title', p.title, const ['Mr', 'Ms', 'Mrs', 'Dr', 'Mstr', 'Miss'], (v) => setState(() => p.title = v)),
        Field('First name', c: k['first']),
        Field('Last name', c: k['last']),
        Row(children: [
          Expanded(child: Field('Date of birth', c: k['dob'], hint: 'DD/MM/YYYY', icon: Icons.cake_outlined)),
          const SizedBox(width: 10),
          Expanded(child: Field('Nationality', c: k['nat'])),
        ]),
        Field('Passport number', c: k['pass'], icon: Icons.badge_outlined),
        if (i == 0) ...[
          Field('Contact email', c: k['email'], type: TextInputType.emailAddress, icon: Icons.mail_outline),
          Field('Mobile number', c: k['phone'], type: TextInputType.phone, icon: Icons.phone_outlined),
        ],
      ]),
    );
  }
}

// ================================================================ ADD-ONS
const mealOptions = ['Standard', 'Vegetarian', 'Vegan', 'Halal', 'Gluten-free', 'Kids meal', 'Book the Cook: Lobster thermidor'];

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
      bottom: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('Total', style: TextStyle(fontSize: 11, color: muted)),
          Text(money(a.grandTotal), style: serif(22)),
        ]),
        const SizedBox(width: 20),
        Expanded(child: PrimaryBtn('Continue to payment', onTap: () => Navigator.of(context).pushNamed('payment'))),
      ]),
      body: Column(children: [
        const StepBar(1, ['Passengers', 'Add-ons', 'Payment']),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(18), children: [
            _sec(Icons.event_seat, 'Seats', a.draftSeats.isEmpty ? 'Seat assigned at check-in (free)' : 'Selected: ${a.draftSeats.join(', ')}'),
            CardBox(
              child: Column(children: [
                for (var i = 0; i < a.draftPax.length; i++)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(backgroundColor: goldSoft, child: Icon(Icons.person, color: navy)),
                    title: Text(a.draftPax[i].fullName),
                    trailing: Pill(i < a.draftSeats.length ? a.draftSeats[i] : 'Not selected', color: i < a.draftSeats.length ? good : muted),
                  ),
                const SizedBox(height: 6),
                PrimaryBtn('Select seats', outline: true, icon: Icons.event_seat, onTap: () => _seats(context, f)),
              ]),
            ),
            _sec(Icons.restaurant, 'Meal', 'Special meals are free. Book the Cook adds SGD 35 per person.'),
            CardBox(
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                for (final m in mealOptions)
                  ChoiceChip(
                    label: Text(m, style: TextStyle(fontSize: 13, color: a.draftMeal == m ? Colors.white : ink, fontWeight: FontWeight.w600)),
                    selected: a.draftMeal == m,
                    selectedColor: navy,
                    showCheckmark: false,
                    onSelected: (_) {
                      a.draftMeal = m;
                      a.notify();
                    },
                  ),
              ]),
            ),
            _sec(Icons.luggage, 'Extra baggage', 'SGD 9 per kg, in 5kg steps. Base allowance included.'),
            CardBox(
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.draftBaggage == 0 ? 'No extra baggage' : '+${a.draftBaggage} kg', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(a.draftBaggage == 0 ? 'Base 30kg included' : money(a.draftBaggage * 9.0), style: const TextStyle(color: muted)),
                ])),
                Stepper2(a.draftBaggage, (v) {
                  a.draftBaggage = v;
                  a.notify();
                }, step: 5, max: 30),
              ]),
            ),
            _sec(Icons.health_and_safety, 'Travel insurance', 'Cover for cancellations, delays and medical cover.'),
            CardBox(
              onTap: () {
                a.draftInsurance = !a.draftInsurance;
                a.notify();
              },
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Travel Insurance Plus', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text('SGD 24 per passenger  |  Up to SGD 100,000 cover', style: const TextStyle(color: muted, fontSize: 13)),
                ])),
                Switch(
                  value: a.draftInsurance,
                  activeColor: navy,
                  activeTrackColor: gold,
                  onChanged: (v) {
                    a.draftInsurance = v;
                    a.notify();
                  },
                ),
              ]),
            ),
            const H('Price summary'),
            _summary(a),
          ]),
        ),
      ]),
    );
  }

  Widget _sec(IconData i, String t, String sub) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(i, color: gold),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: serif(18)),
            Text(sub, style: const TextStyle(color: muted, fontSize: 13)),
          ])),
        ]),
      );

  void _seats(BuildContext c, Flight f) {
    final a = c.app;
    var sel = List<String>.of(a.draftSeats);
    sheet(c, (ctx) => StatefulBuilder(
          builder: (ctx, set) => SizedBox(
            height: MediaQuery.of(ctx).size.height * .86,
            child: Column(children: [
              Padding(padding: const EdgeInsets.all(14), child: Text('Choose ${a.adults == 1 ? 'your seat' : '${a.adults} seats'}', style: serif(20))),
              Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 14), child: SeatMap(cabin: a.cabin, seed: '${f.number}${a.depart.day}', selected: sel, max: a.adults, onChanged: (v) => set(() => sel = v)))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: PrimaryBtn(sel.isEmpty ? 'Skip for now' : 'Confirm ${sel.join(', ')}', goldStyle: true, onTap: () {
                  a.draftSeats = sel;
                  a.notify();
                  Navigator.pop(ctx);
                }),
              ),
            ]),
          ),
        ));
  }
}

Widget _summary(AppState a) => CardBox(
      child: Column(children: [
        KV('Fare (${a.adults} x ${money(a.flight!.price)})', money(a.fareTotal)),
        KV('Taxes & surcharges', money(a.taxes)),
        if (a.addonsTotal > 0) KV('Add-ons', money(a.addonsTotal)),
        const Divider(color: line),
        KV('Total', money(a.grandTotal), bold: true),
      ]),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 34, vertical: 28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: gold),
                SizedBox(height: 18),
                Text('Processing secure payment', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                SizedBox(height: 4),
                Text('Please do not close the app', style: TextStyle(color: muted, fontSize: 13)),
              ]),
            ),
          ),
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    final b = a.confirmBooking(method);
    Navigator.of(context, rootNavigator: true).pop(); // dialog
    nav.pushNamedAndRemoveUntil('confirmation', (r) => r.isFirst, arguments: b.ref);
  }

  @override
  Widget build(BuildContext context) {
    final a = context.app;
    return Screen(
      title: 'Payment',
      bottom: PrimaryBtn('Pay ${money(a.grandTotal)}', icon: Icons.lock_outline, goldStyle: true, loading: busy, onTap: pay),
      body: Column(children: [
        const StepBar(2, ['Passengers', 'Add-ons', 'Payment']),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(18), children: [
            _summary(a),
            const H('Payment method'),
            Row(children: [
              for (final m in [('Card', Icons.credit_card), ('UPI', Icons.qr_code_scanner), ('Net Banking', Icons.account_balance)])
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => method = m.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: method == m.$1 ? navy : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: method == m.$1 ? navy : line)),
                      child: Column(children: [
                        Icon(m.$2, color: method == m.$1 ? gold : muted),
                        const SizedBox(height: 4),
                        Text(m.$1, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: method == m.$1 ? Colors.white : ink)),
                      ]),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            CardBox(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Column(key: ValueKey(method), crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (method == 'Card') ...[
                    Field('Card number', c: card, type: TextInputType.number, icon: Icons.credit_card, onChanged: (v) {
                      final d = v.replaceAll(RegExp(r'\D'), '');
                      final g = [for (var i = 0; i < d.length && i < 16; i += 4) d.substring(i, min(i + 4, d.length))].join(' ');
                      if (g != v) card.value = TextEditingValue(text: g, selection: TextSelection.collapsed(offset: g.length));
                    }),
                    Field('Name on card', c: name, icon: Icons.person_outline),
                    Row(children: [
                      Expanded(child: Field('Expiry', c: exp, hint: 'MM/YY')),
                      const SizedBox(width: 10),
                      Expanded(child: Field('CVV', c: cvv, obscure: true, type: TextInputType.number)),
                    ]),
                  ],
                  if (method == 'UPI') ...[
                    Field('UPI ID', c: upi, icon: Icons.alternate_email, hint: 'name@bank'),
                    const Text('A collect request will be simulated. No real payment is made.', style: TextStyle(color: muted, fontSize: 13)),
                  ],
                  if (method == 'Net Banking')
                    for (final b in const ['Merlion National Bank', 'Harbour Trust Bank', 'Orchid Savings Bank', 'Summit Bank'])
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: b, groupValue: bank, activeColor: navy,
                        title: Text(b, style: const TextStyle(fontWeight: FontWeight.w600)),
                        secondary: const Icon(Icons.account_balance, color: muted),
                        onChanged: (v) => setState(() => bank = v!),
                      ),
                ]),
              ),
            ),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.verified_user_outlined, size: 16, color: muted),
              SizedBox(width: 6),
              Text('Simulated payment. No data is sent anywhere.', style: TextStyle(color: muted, fontSize: 12.5)),
            ]),
            const SizedBox(height: 16),
          ]),
        ),
      ]),
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

class _ConfirmationPageState extends State<ConfirmationPage> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..forward();
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
        actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => a.goTab(0))],
        body: Stack(children: [
          ListView(padding: const EdgeInsets.all(18), children: [
            const SizedBox(height: 10),
            Center(
              child: AnimatedBuilder(
                animation: c,
                builder: (_, __) {
                  final t = Curves.elasticOut.transform((c.value * 2.2).clamp(0, 1));
                  return SizedBox(
                    width: 120, height: 120,
                    child: Stack(alignment: Alignment.center, children: [
                      for (var i = 0; i < 2; i++)
                        Opacity(
                          opacity: (1 - ((c.value * 2 + i * .4) % 1)).clamp(0, 1) * .4,
                          child: Container(width: 90 + 40 * ((c.value * 2 + i * .4) % 1), height: 90 + 40 * ((c.value * 2 + i * .4) % 1), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: good, width: 2))),
                        ),
                      Transform.scale(scale: t, child: Container(width: 86, height: 86, decoration: const BoxDecoration(shape: BoxShape.circle, color: good), child: const Icon(Icons.check_rounded, color: Colors.white, size: 54))),
                    ]),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Center(child: Text('You\'re all set, ${a.profile.first}!', style: serif(26))),
            const SizedBox(height: 6),
            const Center(child: Text('A confirmation has been added to your notifications.', style: TextStyle(color: muted))),
            const SizedBox(height: 20),
            CardBox(
              color: navy,
              child: Column(children: [
                const Text('BOOKING REFERENCE', style: TextStyle(color: Colors.white60, letterSpacing: 2, fontSize: 11)),
                const SizedBox(height: 6),
                Text(b.ref, style: serif(38, c: gold).copyWith(letterSpacing: 6)),
                const SizedBox(height: 8),
                const Pill('CONFIRMED', color: Color(0xFF55D69A)),
              ]),
            ),
            CardBox(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                RouteRow(from: f.from, to: f.to, dep: f.dep, arr: f.arr, dur: f.duration),
                const Divider(height: 28, color: line),
                KV('Flight', '${f.number}  |  ${f.cabin}'),
                KV('Departure', fmtDate(b.date)),
                if (b.returnDate != null) KV('Return', fmtDate(b.returnDate!)),
                KV('Seats', b.seats.isEmpty ? 'At check-in' : b.seats.join(', ')),
                KV('Meal', b.meal),
                if (b.baggageKg > 0) KV('Extra baggage', '${b.baggageKg} kg'),
                KV('Insurance', b.insurance ? 'Travel Insurance Plus' : 'None'),
                KV('Paid via', b.method),
                KV('Total paid', money(b.total), bold: true),
              ]),
            ),
            CardBox(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Passengers', style: serif(17)),
                const SizedBox(height: 8),
                for (final (i, p) in b.pax.indexed)
                  ListTile(
                    contentPadding: EdgeInsets.zero, dense: true,
                    leading: const CircleAvatar(radius: 16, backgroundColor: goldSoft, child: Icon(Icons.person, size: 18, color: navy)),
                    title: Text('${p.title} ${p.fullName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Passport ${p.passport.isEmpty ? '-' : p.passport}'),
                    trailing: Text(i < b.seats.length ? b.seats[i] : '-', style: const TextStyle(fontWeight: FontWeight.w800, color: navy)),
                  ),
              ]),
            ),
            const SizedBox(height: 4),
            PrimaryBtn('Manage booking', icon: Icons.luggage, onTap: () => a.goTab(2, 'trip', b.ref)),
            const SizedBox(height: 10),
            PrimaryBtn('Back to home', outline: true, onTap: () => a.goTab(0)),
            const SizedBox(height: 20),
          ]),
          IgnorePointer(child: AnimatedBuilder(animation: c, builder: (_, __) => CustomPaint(size: Size.infinite, painter: _Confetti(c.value)))),
        ]),
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
      final col = [gold, navy2, const Color(0xFF55D69A), const Color(0xFFE8D29A)][i % 4];
      c.save();
      c.translate(x + sin(t * 8 + i) * 14, y);
      c.rotate(t * 10 + i);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -2, 9, 5), const Radius.circular(1.5)), Paint()..color = col.withValues(alpha: 1 - t * .7));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti o) => o.t != t;
}
