import 'package:flutter/material.dart';
import 'brand.dart';
import 'download_stub.dart' if (dart.library.html) 'download_web.dart';
import 'models.dart';
import 'pass_file.dart';
import 'state.dart';
import 'ui.dart';

Color statusColor(Booking b) => b.status == 'Cancelled' ? bad : (b.isPast ? muted : good);
String statusText(Booking b) => b.status == 'Cancelled' ? 'Cancelled' : (b.isPast ? 'Completed' : (b.checkedIn ? 'Checked in' : 'Confirmed'));

// ================================================================ TRIPS
class TripsPage extends StatefulWidget {
  const TripsPage({super.key});
  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  bool upcomingTab = true;
  final ref = TextEditingController();
  final last = TextEditingController();

  void find() {
    final b = context.app.byRef(ref.text);
    if (b == null || (last.text.trim().isNotEmpty && !b.pax.any((p) => p.last.toLowerCase() == last.text.trim().toLowerCase()))) {
      toast(context, 'No booking found. Try MR4K7P with surname Morgan.');
      return;
    }
    Navigator.of(context).pushNamed('trip', arguments: b.ref);
  }

  @override
  Widget build(BuildContext context) {
    final a = context.app;
    final list = upcomingTab ? a.upcoming : a.past;
    return Screen(
      title: 'My trips',
      canPop: false,
      body: ListView(padding: const EdgeInsets.all(18), children: [
        CardBox(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Find a booking', style: serif(18)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(flex: 5, child: Field('Booking reference', c: ref, hint: 'e.g. MR4K7P', icon: Icons.confirmation_number_outlined)),
              const SizedBox(width: 8),
              Expanded(flex: 4, child: Field('Surname', c: last, hint: 'Morgan')),
            ]),
            PrimaryBtn('Retrieve booking', outline: true, icon: Icons.search, onTap: find),
          ]),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: const Color(0xFFE6E9F1), borderRadius: BorderRadius.circular(26)),
          child: Row(children: [
            for (final t in [(true, 'Upcoming (${a.upcoming.length})'), (false, 'Past (${a.past.length})')])
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => upcomingTab = t.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(color: upcomingTab == t.$1 ? navy : Colors.transparent, borderRadius: BorderRadius.circular(22)),
                    child: Text(t.$2, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: upcomingTab == t.$1 ? Colors.white : muted)),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 14),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(children: [
              const Icon(Icons.luggage_outlined, size: 52, color: line),
              const SizedBox(height: 8),
              Text(upcomingTab ? 'No upcoming trips yet' : 'No past trips', style: const TextStyle(color: muted)),
              if (upcomingTab) TextButton(onPressed: () => a.goTab(1), child: const Text('Book a flight')),
            ]),
          ),
        for (final b in list) _tile(context, b),
      ]),
    );
  }

  Widget _tile(BuildContext c, Booking b) {
    final f = b.flight;
    return CardBox(
      onTap: () => Navigator.of(c).pushNamed('trip', arguments: b.ref),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          Text(f.number, style: const TextStyle(fontWeight: FontWeight.w800, color: navy)),
          const Text('   |   ', style: TextStyle(color: line)),
          Text(fmtShort(b.date), style: const TextStyle(color: muted, fontWeight: FontWeight.w600)),
          const Spacer(),
          Pill(statusText(b), color: statusColor(b)),
        ]),
        const SizedBox(height: 14),
        RouteRow(from: f.from, to: f.to, dep: f.dep, arr: f.arr, dur: f.duration),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.confirmation_number_outlined, size: 15, color: gold),
          const SizedBox(width: 5),
          Text(b.ref, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const Spacer(),
          Text('Seat ${b.seats.isEmpty ? '-' : b.seats.join(', ')}', style: const TextStyle(color: muted)),
          const Icon(Icons.chevron_right, color: muted),
        ]),
      ]),
    );
  }
}

// ================================================================ TRIP DETAIL
class TripDetailPage extends StatelessWidget {
  final String ref;
  const TripDetailPage({super.key, required this.ref});

  @override
  Widget build(BuildContext context) {
    final a = context.app;
    final b = a.byRef(ref);
    if (b == null) return const Screen(title: 'Booking', body: Center(child: Text('Booking not found')));
    final f = b.flight, from = airportBy(f.from), to = airportBy(f.to);
    final active = b.upcoming;
    return Screen(
      title: 'Booking ${b.ref}',
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [navy, navy2])),
          child: Column(children: [
            Row(children: [
              Text('${f.number}  |  ${f.cabin}', style: const TextStyle(color: Colors.white70)),
              const Spacer(),
              Pill(statusText(b), color: b.status == 'Cancelled' ? const Color(0xFFFF8A7A) : const Color(0xFF55D69A)),
            ]),
            const SizedBox(height: 16),
            RouteRow(from: f.from, to: f.to, dep: f.dep, arr: f.arr, dur: f.duration, light: true),
            const SizedBox(height: 14),
            Row(children: [
              Text('${from.city}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              Text('${to.city}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        if (active)
          Row(children: [
            Expanded(
              child: b.checkedIn
                  ? PrimaryBtn('Boarding pass', goldStyle: true, icon: Icons.qr_code_2, onTap: () => Navigator.of(context).pushNamed('pass', arguments: b.ref))
                  : PrimaryBtn('Check in', goldStyle: true, icon: Icons.how_to_reg, onTap: () => Navigator.of(context).pushNamed('checkin', arguments: b.ref)),
            ),
          ]),
        const H('Flight information'),
        CardBox(
          child: Column(children: [
            KV('Date', fmtDate(b.date)),
            if (b.returnDate != null) KV('Return', fmtDate(b.returnDate!)),
            KV('Departs', '${f.dep}  |  ${from.name}'),
            KV('Arrives', '${f.arr}${f.dayOffset > 0 ? ' +${f.dayOffset}' : ''}  |  ${to.name}'),
            KV('Aircraft', f.aircraft),
            KV('Terminal / Gate', '${b.terminal}  /  ${b.gate}'),
            KV('Booked', fmtShort(b.created)),
            KV('Total paid', money(b.total)),
          ]),
        ),
        const H('Passengers & seats'),
        CardBox(
          child: Column(children: [
            for (final (i, p) in b.pax.indexed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: goldSoft, child: Icon(Icons.person, color: navy)),
                title: Text('${p.title} ${p.fullName}', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('Passport ${p.passport.isEmpty ? '-' : p.passport}  |  ${b.meal}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: goldSoft, borderRadius: BorderRadius.circular(12)),
                  child: Text(i < b.seats.length ? b.seats[i] : 'TBA', style: const TextStyle(fontWeight: FontWeight.w800, color: navy)),
                ),
              ),
            KV('Extra baggage', b.baggageKg == 0 ? 'None' : '${b.baggageKg} kg'),
            KV('Insurance', b.insurance ? 'Travel Insurance Plus' : 'Not added'),
          ]),
        ),
        const H('Manage'),
        Wrap(spacing: 10, runSpacing: 10, children: [
          SmallBtn('Flight status', () => Navigator.of(context).pushNamed('status', arguments: f.number), icon: Icons.radar),
          if (active) SmallBtn('Change seat', () => _changeSeat(context, b), icon: Icons.event_seat),
          if (active) SmallBtn('Add baggage', () => _baggage(context, b), icon: Icons.luggage),
          if (b.checkedIn && !b.isPast) SmallBtn('Boarding pass', () => Navigator.of(context).pushNamed('pass', arguments: b.ref), icon: Icons.qr_code_2),
          if (active) SmallBtn('Cancel booking', () => _cancel(context, b), icon: Icons.cancel_outlined, danger: true),
        ]),
        if (b.status == 'Cancelled')
          CardBox(margin: const EdgeInsets.only(top: 14), color: const Color(0xFFFDECEA), child: const Text('This booking was cancelled. A refund of the eligible fare is being processed to your original payment method within 5-7 days.', style: TextStyle(color: bad, height: 1.4))),
        const SizedBox(height: 24),
      ]),
    );
  }

  void _changeSeat(BuildContext c, Booking b) {
    final a = c.app;
    var sel = List<String>.of(b.seats);
    sheet(c, (ctx) => StatefulBuilder(
          builder: (ctx, set) => SizedBox(
            height: MediaQuery.of(ctx).size.height * .86,
            child: Column(children: [
              Padding(padding: const EdgeInsets.all(14), child: Text('Change seat', style: serif(20))),
              Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 14), child: SeatMap(cabin: b.flight.cabin, seed: '${b.flight.number}${b.date.day}', selected: sel, max: b.pax.length, mine: b.seats, onChanged: (v) => set(() => sel = v)))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: PrimaryBtn(sel.isEmpty ? 'Select a seat' : 'Confirm ${sel.join(', ')}', goldStyle: true, onTap: () {
                  if (sel.isEmpty) return;
                  a.updateBooking(b, seats: sel);
                  Navigator.pop(ctx);
                  toast(c, 'Seat updated to ${sel.join(', ')}');
                }),
              ),
            ]),
          ),
        ));
  }

  void _baggage(BuildContext c, Booking b) {
    final a = c.app;
    var kg = b.baggageKg;
    sheet(c, (ctx) => StatefulBuilder(
          builder: (ctx, set) => Padding(
            padding: const EdgeInsets.all(22),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add extra baggage', style: serif(21)),
              const SizedBox(height: 4),
              const Text('SGD 9 per kg, added in 5kg steps.', style: TextStyle(color: muted)),
              const SizedBox(height: 18),
              Row(children: [
                const Icon(Icons.luggage, color: gold, size: 34),
                const SizedBox(width: 12),
                Expanded(child: Text('$kg kg extra', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                Stepper2(kg, (v) => set(() => kg = v), step: 5, max: 40),
              ]),
              const SizedBox(height: 12),
              KV('Additional charge', money((kg - b.baggageKg) * 9.0)),
              const SizedBox(height: 14),
              PrimaryBtn('Confirm', goldStyle: true, onTap: () {
                a.updateBooking(b, baggage: kg);
                Navigator.pop(ctx);
                toast(c, 'Baggage updated: +$kg kg');
              }),
              const SizedBox(height: 8),
            ]),
          ),
        ));
  }

  Future<void> _cancel(BuildContext c, Booking b) async {
    final ok = await confirmDialog(c, 'Cancel this booking?', 'Booking ${b.ref} will be cancelled and a refund of ${money(b.total * .85)} (after a 15% fee) will be simulated. This cannot be undone.', yes: 'Cancel booking', danger: true);
    if (ok && c.mounted) {
      c.app.cancel(b);
      toast(c, 'Booking ${b.ref} cancelled');
    }
  }
}

// ================================================================ BOARDING PASS CARD
class BoardingPassCard extends StatelessWidget {
  final Booking b;
  final int i;
  const BoardingPassCard(this.b, this.i, {super.key});
  @override
  Widget build(BuildContext context) {
    final f = b.flight, p = b.pax[i];
    final seat = i < b.seats.length ? b.seats[i] : 'TBA';
    final from = airportBy(f.from), to = airportBy(f.to);
    Widget cell(String k, String v, {bool big = false}) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k, style: const TextStyle(fontSize: 10, color: muted, letterSpacing: 1.1, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(v, style: TextStyle(fontSize: big ? 19 : 15, fontWeight: FontWeight.w800, color: ink)),
          ]),
        );
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: navy.withValues(alpha: .18), blurRadius: 26, offset: const Offset(0, 12))]),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: navy,
          child: Row(children: [
            const SiaLogo(height: 34, light: true),
            const Spacer(),
            Text(f.cabin.toUpperCase(), style: const TextStyle(color: gold, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.2)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(children: [
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(from.code, style: serif(36)), Text(from.city, style: const TextStyle(color: muted, fontSize: 12))]),
              const Expanded(child: Icon(Icons.flight, color: gold, size: 28)),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(to.code, style: serif(36)), Text(to.city, style: const TextStyle(color: muted, fontSize: 12))]),
            ]),
            const SizedBox(height: 18),
            Row(children: [cell('PASSENGER', p.fullName.toUpperCase())]),
            const SizedBox(height: 14),
            Row(children: [cell('FLIGHT', f.number), cell('DATE', '${fmtShort(b.date)} ${b.date.year}'), cell('DEPARTS', f.dep)]),
            const SizedBox(height: 14),
            Row(children: [cell('BOARDING', hm(f.depMin - 45), big: true), cell('GATE', b.gate, big: true), cell('SEAT', seat, big: true)]),
            const SizedBox(height: 14),
            Row(children: [cell('TERMINAL', b.terminal), cell('BOOKING', b.ref), cell('GROUP', 'Zone 2')]),
          ]),
        ),
        Row(children: [
          Container(width: 12, height: 24, decoration: const BoxDecoration(color: bg, borderRadius: BorderRadius.horizontal(right: Radius.circular(12)))),
          Expanded(child: LayoutBuilder(builder: (_, c) => Row(children: [for (var k = 0; k < (c.maxWidth / 9).floor(); k++) Expanded(child: Container(height: 1.5, margin: const EdgeInsets.symmetric(horizontal: 2), color: line))]))),
          Container(width: 12, height: 24, decoration: const BoxDecoration(color: bg, borderRadius: BorderRadius.horizontal(left: Radius.circular(12)))),
        ]),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            QrBox('${b.ref}|${f.number}|${p.fullName}|$seat', size: 150),
            const SizedBox(height: 14),
            SizedBox(height: 40, width: 220, child: CustomPaint(painter: BarcodePainter('${b.ref}$seat${f.number}'))),
            const SizedBox(height: 6),
            Text('${b.ref}  ${f.number.replaceAll(' ', '')}  $seat', style: const TextStyle(color: muted, fontSize: 11, letterSpacing: 2)),
          ]),
        ),
      ]),
    );
  }
}

// ================================================================ BOARDING PASS PAGE
class BoardingPassPage extends StatefulWidget {
  final String ref;
  const BoardingPassPage({super.key, required this.ref});
  @override
  State<BoardingPassPage> createState() => _BoardingPassPageState();
}

Future<void> doDownload(BuildContext c, Booking b, int i) async {
  final ok = await downloadTextFile(boardingPassName(b), boardingPassHtml(b, i), 'text/html');
  if (c.mounted) toast(c, ok ? 'Downloaded ${boardingPassName(b)}' : 'Download is available in the web build');
}

class _BoardingPassPageState extends State<BoardingPassPage> {
  int page = 0;
  @override
  Widget build(BuildContext context) {
    final a = context.app;
    final b = a.byRef(widget.ref);
    if (b == null) return const Screen(title: 'Boarding pass', body: Center(child: Text('Not found')));
    return Container(
      color: navy,
      child: Screen(
        title: 'Boarding pass',
        body: Container(
          color: bg,
          child: ListView(padding: const EdgeInsets.all(18), children: [
            if (b.pax.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(spacing: 8, children: [
                  for (final (i, p) in b.pax.indexed)
                    ChoiceChip(label: Text(p.first), selected: page == i, selectedColor: navy, showCheckmark: false, labelStyle: TextStyle(color: page == i ? Colors.white : ink, fontWeight: FontWeight.w600), onSelected: (_) => setState(() => page = i)),
                ]),
              ),
            AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: BoardingPassCard(b, page, key: ValueKey(page))),
            const SizedBox(height: 18),
            PrimaryBtn('Download boarding pass', icon: Icons.download, onTap: () => doDownload(context, b, page)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: PrimaryBtn('Add to wallet', outline: true, icon: Icons.account_balance_wallet_outlined, onTap: () => toast(context, 'Added to wallet (demo)'))),
              const SizedBox(width: 10),
              Expanded(child: PrimaryBtn('Flight status', outline: true, icon: Icons.radar, onTap: () => Navigator.of(context).pushNamed('status', arguments: b.flight.number))),
            ]),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}

// ================================================================ CHECK-IN
class CheckInPage extends StatefulWidget {
  final String? ref;
  const CheckInPage({super.key, this.ref});
  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  int step = 0;
  late final TextEditingController ref;
  final last = TextEditingController();
  Booking? b;
  bool paxOk = false, dgOk = false, busy = false;
  List<String> seats = [];

  @override
  void initState() {
    super.initState();
    ref = TextEditingController(text: widget.ref ?? '');
    if (widget.ref != null) last.text = 'Morgan';
  }

  void retrieve() async {
    final a = context.app;
    final f = a.byRef(ref.text);
    if (f == null || !f.upcoming) {
      toast(context, 'No eligible booking found for that reference');
      return;
    }
    if (last.text.trim().isNotEmpty && !f.pax.any((p) => p.last.toLowerCase() == last.text.trim().toLowerCase())) {
      toast(context, 'Surname does not match this booking');
      return;
    }
    setState(() => busy = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      busy = false;
      b = f;
      seats = List.of(f.seats);
      if (f.checkedIn) step = 4; else step = 1;
    });
  }

  void confirm() async {
    final a = context.app;
    setState(() => busy = true);
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    a.updateBooking(b!, seats: seats, checkedIn: true);
    setState(() {
      busy = false;
      step = 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = context.app;
    const labels = ['Retrieve', 'Passengers', 'Seat', 'Confirm', 'Pass'];
    Widget body;
    Widget? bottom;
    switch (step) {
      case 0:
        body = ListView(padding: const EdgeInsets.all(18), children: [
          Text('Retrieve your booking', style: serif(22)),
          const SizedBox(height: 6),
          const Text('Online check-in opens 48 hours before departure.', style: TextStyle(color: muted)),
          const SizedBox(height: 16),
          CardBox(child: Column(children: [
            Field('Booking reference', c: ref, icon: Icons.confirmation_number_outlined),
            Field('Surname', c: last, icon: Icons.person_outline),
          ])),
          if (a.upcoming.isNotEmpty) ...[
            const H('Or pick a trip'),
            for (final t in a.upcoming)
              CardBox(
                padding: const EdgeInsets.all(14),
                onTap: () => setState(() {
                  ref.text = t.ref;
                  last.text = t.pax.first.last;
                }),
                child: Row(children: [
                  const Icon(Icons.flight_takeoff, color: gold),
                  const SizedBox(width: 12),
                  Expanded(child: Text('${t.flight.number}  |  ${t.flight.from} to ${t.flight.to}\n${fmtDate(t.date)}', style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4))),
                  Text(t.ref, style: const TextStyle(color: navy, fontWeight: FontWeight.w800)),
                ]),
              ),
          ],
        ]);
        bottom = PrimaryBtn('Retrieve booking', loading: busy, onTap: retrieve);
      case 1:
        body = ListView(padding: const EdgeInsets.all(18), children: [
          Text('Confirm passenger details', style: serif(22)),
          const SizedBox(height: 14),
          for (final p in b!.pax)
            CardBox(child: Column(children: [
              KV('Name', '${p.title} ${p.fullName}'),
              KV('Date of birth', p.dob.isEmpty ? '-' : p.dob),
              KV('Nationality', p.nationality),
              KV('Passport', p.passport.isEmpty ? '-' : p.passport),
            ])),
          CheckboxListTile(
            value: paxOk, onChanged: (v) => setState(() => paxOk = v!), activeColor: navy,
            controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero,
            title: const Text('The passenger details above are correct and match my travel documents.', style: TextStyle(fontSize: 14)),
          ),
        ]);
        bottom = PrimaryBtn('Continue', onTap: () {
          if (!paxOk) {
            toast(context, 'Please confirm the passenger details');
            return;
          }
          setState(() => step = 2);
        });
      case 2:
        body = ListView(padding: const EdgeInsets.all(18), children: [
          Text('Select your seat', style: serif(22)),
          const SizedBox(height: 4),
          Text(seats.isEmpty ? 'Tap a seat on the map' : 'Selected: ${seats.join(', ')}', style: const TextStyle(color: muted)),
          const SizedBox(height: 14),
          SeatMap(cabin: b!.flight.cabin, seed: '${b!.flight.number}${b!.date.day}', selected: seats, max: b!.pax.length, mine: b!.seats, onChanged: (v) => setState(() => seats = v)),
        ]);
        bottom = PrimaryBtn(seats.length == b!.pax.length ? 'Confirm ${seats.join(', ')}' : 'Select ${b!.pax.length} seat(s)', onTap: () {
          if (seats.length != b!.pax.length) {
            toast(context, 'Please select a seat for each passenger');
            return;
          }
          setState(() => step = 3);
        });
      case 3:
        final f = b!.flight;
        body = ListView(padding: const EdgeInsets.all(18), children: [
          Text('Confirm check-in', style: serif(22)),
          const SizedBox(height: 14),
          CardBox(child: Column(children: [
            RouteRow(from: f.from, to: f.to, dep: f.dep, arr: f.arr, dur: f.duration),
            const Divider(height: 26, color: line),
            KV('Flight', f.number),
            KV('Date', fmtDate(b!.date)),
            KV('Passengers', b!.pax.map((p) => p.fullName).join(', ')),
            KV('Seats', seats.join(', ')),
          ])),
          CheckboxListTile(
            value: dgOk, onChanged: (v) => setState(() => dgOk = v!), activeColor: navy,
            controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero,
            title: const Text('I confirm that I am not carrying dangerous goods, and I accept the conditions of carriage.', style: TextStyle(fontSize: 14)),
          ),
        ]);
        bottom = PrimaryBtn('Confirm check-in', goldStyle: true, icon: Icons.check_circle_outline, loading: busy, onTap: () {
          if (!dgOk) {
            toast(context, 'Please accept the declaration to continue');
            return;
          }
          confirm();
        });
      default:
        body = ListView(padding: const EdgeInsets.all(18), children: [
          Row(children: [
            const Icon(Icons.check_circle, color: good, size: 30),
            const SizedBox(width: 10),
            Expanded(child: Text('You\'re checked in!', style: serif(22))),
          ]),
          const SizedBox(height: 14),
          BoardingPassCard(b!, 0),
          const SizedBox(height: 16),
          PrimaryBtn('Download boarding pass', icon: Icons.download, onTap: () => doDownload(context, b!, 0)),
          const SizedBox(height: 10),
          PrimaryBtn('View full boarding pass', outline: true, icon: Icons.qr_code_2, onTap: () => Navigator.of(context).pushReplacementNamed('pass', arguments: b!.ref)),
          const SizedBox(height: 20),
        ]);
    }
    return Screen(
      title: 'Online check-in',
      bottom: bottom,
      body: Column(children: [
        StepBar(step, labels),
        Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: KeyedSubtree(key: ValueKey(step), child: body))),
      ]),
    );
  }
}
