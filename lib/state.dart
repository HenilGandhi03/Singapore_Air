import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  static const _key = 'sia_demo_state_v2';
  SharedPreferences? _p;

  bool onboarded = false;
  late Profile profile;
  List<Booking> bookings = [];
  List<Notif> notifs = [];
  List<Txn> txns = [];
  int miles = 48250, earned = 126400, redeemed = 78150;

  // search form
  String from = 'BOM', to = 'SIN', cabin = 'Economy', tripType = 'Return';
  DateTime depart = DateTime.now().add(const Duration(days: 14));
  DateTime? ret = DateTime.now().add(const Duration(days: 21));
  int adults = 1;

  // booking draft
  Flight? flight;
  List<PassengerInfo> draftPax = [];
  List<String> draftSeats = [];
  String draftMeal = 'Standard';
  int draftBaggage = 0;
  bool draftInsurance = false;

  // tab navigation
  final tab = ValueNotifier<int>(0);
  final navKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    final raw = _p!.getString(_key);
    if (raw != null) {
      try {
        _load(jsonDecode(raw));
        return;
      } catch (_) {}
    }
    _seed();
  }

  void _load(Map<String, dynamic> j) {
    onboarded = j['onboarded'] ?? false;
    profile = Profile.fromJson(Map<String, dynamic>.from(j['profile']));
    bookings = (j['bookings'] as List).map((e) => Booking.fromJson(Map<String, dynamic>.from(e))).toList();
    notifs = (j['notifs'] as List).map((e) => Notif.fromJson(Map<String, dynamic>.from(e))).toList();
    txns = (j['txns'] as List).map((e) => Txn.fromJson(Map<String, dynamic>.from(e))).toList();
    miles = j['miles'];
    earned = j['earned'];
    redeemed = j['redeemed'];
  }

  void _save() {
    _p?.setString(
        _key,
        jsonEncode({
          'onboarded': onboarded,
          'profile': profile.toJson(),
          'bookings': bookings.map((e) => e.toJson()).toList(),
          'notifs': notifs.map((e) => e.toJson()).toList(),
          'txns': txns.map((e) => e.toJson()).toList(),
          'miles': miles,
          'earned': earned,
          'redeemed': redeemed,
        }));
  }

  void _seed() {
    final today = DateTime.now();
    DateTime d(int off) => DateTime(today.year, today.month, today.day).add(Duration(days: off));
    profile = Profile(
      name: 'Alex Morgan',
      email: 'alex.morgan@example.com',
      phone: '+91 98765 43210',
      memberNo: '8820 4417 55',
      tier: 'Gold',
      seatPref: 'Window',
      mealPref: 'Vegetarian',
      language: 'English',
      home: 'BOM',
      notify: {'Flight updates': true, 'Check-in reminders': true, 'Offers & promotions': false, 'Miles activity': true},
      saved: [
        PassengerInfo(title: 'Ms', first: 'Priya', last: 'Morgan', dob: '12/03/1992', nationality: 'Indian', passport: 'Z1234567', email: 'priya.morgan@example.com', phone: '+91 98200 11122'),
        PassengerInfo(title: 'Mr', first: 'Sam', last: 'Morgan', dob: '04/09/2015', nationality: 'Indian', passport: 'Z7654321'),
      ],
    );
    final alex = PassengerInfo(title: 'Mr', first: 'Alex', last: 'Morgan', dob: '21/07/1990', nationality: 'Indian', passport: 'N8820441', email: 'alex.morgan@example.com', phone: '+91 98765 43210');
    Flight f(String from, String to, String cabin, int i) => searchFlights(from, to, cabin)[i];
    bookings = [
      Booking(ref: 'MR4K7P', flight: f('BOM', 'SIN', 'Business', 0), date: d(1), pax: [alex], seats: ['4A'], meal: 'Vegetarian', total: f('BOM', 'SIN', 'Business', 0).price + 46, gate: 'B12', terminal: 'T2'),
      Booking(ref: 'KT9Z2L', flight: f('SIN', 'BKK', 'Economy', 1), date: d(24), pax: [alex], seats: ['31C'], total: f('SIN', 'BKK', 'Economy', 1).price, gate: 'C7', terminal: 'T3'),
      Booking(ref: 'QP3N8D', flight: f('SIN', 'BOM', 'Economy', 2), date: d(-38), pax: [alex], seats: ['27K'], status: 'Confirmed', checkedIn: true, total: f('SIN', 'BOM', 'Economy', 2).price, gate: 'A5', terminal: 'T1'),
      Booking(ref: 'HW6C1V', flight: f('SIN', 'HKG', 'Premium Economy', 0), date: d(-120), pax: [alex], seats: ['12A'], checkedIn: true, total: f('SIN', 'HKG', 'Premium Economy', 0).price, gate: 'D3', terminal: 'T3'),
    ];
    txns = const [
      Txn('12 Oct', 'Flight SIN to BOM (Economy)', 2350),
      Txn('02 Oct', 'Redeemed: Lounge pass', -6000),
      Txn('18 Sep', 'Partner: Changi Shop & Dine', 420),
      Txn('29 Aug', 'Flight SIN to HKG (Premium Economy)', 3120),
      Txn('15 Aug', 'Redeemed: Extra 10kg baggage', -3500),
      Txn('01 Aug', 'Welcome bonus, Gold renewal', 5000),
    ];
    notifs = [
      Notif('n1', 'Booking confirmed', 'Your trip Mumbai to Singapore (MR4K7P) is confirmed.', '2 days ago', 'trip', arg: 'MR4K7P', read: true),
      Notif('n2', 'Check-in is now open', 'Online check-in for SQ 4xx opens now. Pick your seat.', '1h ago', 'checkin', arg: 'MR4K7P'),
      Notif('n3', 'Your flight departs tomorrow', 'Mumbai to Singapore leaves tomorrow. Pack your passport.', '3h ago', 'trip', arg: 'MR4K7P'),
      Notif('n4', 'Your boarding pass is ready', 'Tap to view the boarding pass for Singapore to Bangkok.', '5h ago', 'pass', arg: 'QP3N8D'),
      Notif('n5', 'Exclusive travel offer available', 'Members save up to 20% on Tokyo this spring.', 'Yesterday', 'offer', arg: 'tokyo'),
    ];
    miles = 48250;
    earned = 126400;
    redeemed = 78150;
    _save();
  }

  int get unread => notifs.where((n) => !n.read).length;

  Booking? byRef(String ref) {
    for (final b in bookings) {
      if (b.ref.toUpperCase() == ref.trim().toUpperCase()) return b;
    }
    return null;
  }

  List<Booking> get upcoming =>
      bookings.where((b) => b.upcoming).toList()..sort((a, b) => a.date.compareTo(b.date));
  List<Booking> get past =>
      bookings.where((b) => !b.upcoming).toList()..sort((a, b) => b.date.compareTo(a.date));
  Booking? get nextTrip => upcoming.isEmpty ? null : upcoming.first;

  void notify() => notifyListeners();

  void finishOnboarding() {
    onboarded = true;
    _save();
    notifyListeners();
  }

  void goTab(int i, [String? route, Object? args]) {
    tab.value = i;
    final nav = navKeys[i].currentState;
    if (nav != null) {
      nav.popUntil((r) => r.isFirst);
      if (route != null) nav.pushNamed(route, arguments: args);
    }
  }

  // ---- search / draft
  void swap() {
    final t = from;
    from = to;
    to = t;
    notifyListeners();
  }

  void startDraft(Flight fl) {
    flight = fl;
    final lead = PassengerInfo(
        first: profile.first, last: profile.name.split(' ').last, email: profile.email,
        phone: profile.phone, dob: '21/07/1990', passport: 'N8820441');
    draftPax = [lead, for (var i = 1; i < adults; i++) PassengerInfo(title: 'Mr')];
    draftSeats = [];
    draftMeal = profile.mealPref;
    draftBaggage = 0;
    draftInsurance = false;
    notifyListeners();
  }

  double seatFee(String s) {
    final row = int.tryParse(s.replaceAll(RegExp(r'[A-Z]'), '')) ?? 0;
    if (cabin == 'Economy' && (row <= 24 || row == 33)) return 28; // extra legroom / exit
    return 0;
  }

  double get addonsTotal =>
      draftSeats.fold<double>(0, (a, s) => a + seatFee(s)) +
      draftBaggage * 9.0 +
      (draftInsurance ? 24.0 * adults : 0) +
      (draftMeal.startsWith('Book the Cook') ? 35.0 * adults : 0);
  double get fareTotal => (flight?.price ?? 0) * adults * (tripType == 'Return' ? 1 : 1);
  double get taxes => fareTotal * 0.11;
  double get grandTotal => fareTotal + taxes + addonsTotal;

  Booking confirmBooking(String method) {
    final r = Random();
    const ch = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    String ref;
    do {
      ref = List.generate(6, (_) => ch[r.nextInt(ch.length)]).join();
    } while (byRef(ref) != null);
    final b = Booking(
      ref: ref, flight: flight!, date: depart,
      returnDate: tripType == 'Return' ? ret : null,
      pax: List.of(draftPax), seats: List.of(draftSeats),
      meal: draftMeal, baggageKg: draftBaggage, insurance: draftInsurance,
      total: grandTotal, method: method,
      gate: '${'ABCD'[r.nextInt(4)]}${2 + r.nextInt(20)}',
      terminal: 'T${1 + r.nextInt(3)}',
    );
    bookings.insert(0, b);
    final pts = (distanceKm(airportBy(flight!.from), airportBy(flight!.to)) * 0.6 * (cabinMult[cabin] ?? 1)).round();
    earned += pts;
    miles += pts;
    txns = [Txn(fmtShort(DateTime.now()), 'Flight ${flight!.from} to ${flight!.to} ($cabin)', pts), ...txns];
    notifs.insert(0, Notif('n${DateTime.now().millisecondsSinceEpoch}', 'Booking confirmed',
        '${airportBy(flight!.from).city} to ${airportBy(flight!.to).city}, ref $ref. You earned ${num0(pts)} miles.', 'Just now', 'trip', arg: ref));
    _save();
    notifyListeners();
    return b;
  }

  void cancel(Booking b) {
    b.status = 'Cancelled';
    notifs.insert(0, Notif('n${DateTime.now().millisecondsSinceEpoch}', 'Booking cancelled',
        'Booking ${b.ref} was cancelled. Your refund will arrive in 5-7 days.', 'Just now', 'trip', arg: b.ref));
    _save();
    notifyListeners();
  }

  void updateBooking(Booking b, {List<String>? seats, int? baggage, bool? checkedIn}) {
    if (seats != null) b.seats = seats;
    if (baggage != null) {
      b.total += (baggage - b.baggageKg) * 9.0;
      b.baggageKg = baggage;
    }
    if (checkedIn == true && !b.checkedIn) {
      b.checkedIn = true;
      notifs.insert(0, Notif('n${DateTime.now().millisecondsSinceEpoch}', 'Your boarding pass is ready',
          'Checked in for ${b.flight.number}. Tap to view your boarding pass.', 'Just now', 'pass', arg: b.ref));
    }
    _save();
    notifyListeners();
  }

  bool redeem(Reward r) {
    if (miles < r.miles) return false;
    miles -= r.miles;
    redeemed += r.miles;
    txns = [Txn(fmtShort(DateTime.now()), 'Redeemed: ${r.title}', -r.miles), ...txns];
    _save();
    notifyListeners();
    return true;
  }

  void saveProfile() {
    _save();
    notifyListeners();
  }

  void markRead(Notif n) {
    n.read = true;
    _save();
    notifyListeners();
  }

  void markAllRead() {
    for (final n in notifs) {
      n.read = true;
    }
    _save();
    notifyListeners();
  }

  Future<void> resetDemo() async {
    await _p?.remove(_key);
    onboarded = true;
    _seed();
    onboarded = true;
    _save();
    notifyListeners();
  }

  Future<void> signOut() async {
    onboarded = false;
    _save();
    notifyListeners();
  }
}

class Scope extends InheritedNotifier<AppState> {
  const Scope({super.key, required AppState state, required super.child}) : super(notifier: state);
  static AppState of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<Scope>()!.notifier!;
}

extension Ctx on BuildContext {
  AppState get app => Scope.of(this);
}
