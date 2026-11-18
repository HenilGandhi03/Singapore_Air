import 'dart:math';

class Airport {
  final String code, city, name, country;
  final double lat, lon, tz;
  const Airport(this.code, this.city, this.name, this.country, this.lat,
      this.lon, this.tz);
  String get label => '$city ($code)';
}

const airports = <Airport>[
  Airport('BOM', 'Mumbai', 'Chhatrapati Shivaji Maharaj Intl', 'India', 19.09, 72.87, 5.5),
  Airport('DEL', 'Delhi', 'Indira Gandhi Intl', 'India', 28.56, 77.10, 5.5),
  Airport('BLR', 'Bengaluru', 'Kempegowda Intl', 'India', 13.20, 77.71, 5.5),
  Airport('SIN', 'Singapore', 'Changi Airport', 'Singapore', 1.36, 103.99, 8),
  Airport('SGN', 'Ho Chi Minh City', 'Tan Son Nhat Intl', 'Vietnam', 10.82, 106.65, 7),
  Airport('BKK', 'Bangkok', 'Suvarnabhumi', 'Thailand', 13.69, 100.75, 7),
  Airport('KUL', 'Kuala Lumpur', 'Kuala Lumpur Intl', 'Malaysia', 2.74, 101.70, 8),
  Airport('HKG', 'Hong Kong', 'Hong Kong Intl', 'Hong Kong', 22.31, 113.91, 8),
  Airport('NRT', 'Tokyo', 'Narita Intl', 'Japan', 35.77, 140.39, 9),
  Airport('SYD', 'Sydney', 'Kingsford Smith', 'Australia', -33.94, 151.18, 11),
  Airport('LHR', 'London', 'Heathrow', 'United Kingdom', 51.47, -0.45, 0),
  Airport('DXB', 'Dubai', 'Dubai Intl', 'UAE', 25.25, 55.36, 4),
  Airport('JFK', 'New York', 'John F. Kennedy Intl', 'USA', 40.64, -73.78, -5),
  Airport('DPS', 'Bali', 'Ngurah Rai Intl', 'Indonesia', -8.75, 115.17, 8),
  Airport('ICN', 'Seoul', 'Incheon Intl', 'South Korea', 37.46, 126.44, 9),
];

Airport airportBy(String code) =>
    airports.firstWhere((a) => a.code == code, orElse: () => airports.first);

const cabins = ['Economy', 'Premium Economy', 'Business', 'First'];
const cabinMult = {
  'Economy': 1.0,
  'Premium Economy': 1.7,
  'Business': 3.2,
  'First': 5.5,
};

double distanceKm(Airport a, Airport b) {
  const r = 6371.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(b.lat - a.lat), dLon = rad(b.lon - a.lon);
  final h = pow(sin(dLat / 2), 2) +
      cos(rad(a.lat)) * cos(rad(b.lat)) * pow(sin(dLon / 2), 2);
  return 2 * r * asin(sqrt(h));
}

String two(int n) => n.toString().padLeft(2, '0');
String hm(int minOfDay) {
  final m = ((minOfDay % 1440) + 1440) % 1440;
  return '${two(m ~/ 60)}:${two(m % 60)}';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
String fmtDate(DateTime d) => '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';
String fmtShort(DateTime d) => '${d.day} ${_months[d.month - 1]}';
String money(num v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return 'SGD $b';
}

String num0(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return (v < 0 ? '-' : '') + b.toString();
}

class Flight {
  final String number, from, to, aircraft, cabin;
  final int depMin, durMin;
  final double price; // per passenger, in chosen cabin
  const Flight(this.number, this.from, this.to, this.aircraft, this.cabin,
      this.depMin, this.durMin, this.price);

  int get arrMinLocal {
    final a = airportBy(from), b = airportBy(to);
    final diff = ((b.tz - a.tz) * 60).round();
    return depMin + durMin + diff;
  }

  String get dep => hm(depMin);
  String get arr => hm(arrMinLocal);
  int get dayOffset => (arrMinLocal / 1440).floor();
  String get duration => '${durMin ~/ 60}h ${two(durMin % 60)}m';
  bool get nonstop => true;

  Map<String, dynamic> toJson() => {
        'number': number, 'from': from, 'to': to, 'aircraft': aircraft,
        'cabin': cabin, 'depMin': depMin, 'durMin': durMin, 'price': price,
      };
  factory Flight.fromJson(Map<String, dynamic> j) => Flight(
      j['number'], j['from'], j['to'], j['aircraft'], j['cabin'],
      j['depMin'], j['durMin'], (j['price'] as num).toDouble());
}

List<Flight> searchFlights(String from, String to, String cabin) {
  final a = airportBy(from), b = airportBy(to);
  final km = distanceKm(a, b);
  final dur = (km / 840 * 60 + 35).round();
  final base = 60 + km * 0.085;
  final seed = (from.codeUnits.fold<int>(0, (x, y) => x + y) * 7 +
      to.codeUnits.fold<int>(0, (x, y) => x + y) * 13);
  final aircraft = km > 6500 ? 'Airbus A350-900' : km > 3000 ? 'Boeing 787-10' : 'Airbus A320neo';
  final dep = [(5 * 60 + 45), (13 * 60 + 20), (22 * 60 + 5)];
  final fm = cabinMult[cabin] ?? 1.0;
  final mult = [1.0, 1.12, 0.93];
  return List.generate(3, (i) {
    final n = 400 + (seed * (i + 3)) % 480;
    return Flight('SQ $n', from, to, aircraft, cabin, dep[i],
        dur + (i == 1 ? 10 : i == 2 ? -5 : 0), (base * fm * mult[i]).roundToDouble());
  });
}

class PassengerInfo {
  String title, first, last, dob, nationality, passport, email, phone;
  PassengerInfo({
    this.title = 'Mr',
    this.first = '',
    this.last = '',
    this.dob = '',
    this.nationality = 'Indian',
    this.passport = '',
    this.email = '',
    this.phone = '',
  });
  String get fullName => '$first $last'.trim();
  Map<String, dynamic> toJson() => {
        'title': title, 'first': first, 'last': last, 'dob': dob,
        'nationality': nationality, 'passport': passport, 'email': email,
        'phone': phone,
      };
  factory PassengerInfo.fromJson(Map<String, dynamic> j) => PassengerInfo(
        title: j['title'] ?? 'Mr', first: j['first'] ?? '', last: j['last'] ?? '',
        dob: j['dob'] ?? '', nationality: j['nationality'] ?? '',
        passport: j['passport'] ?? '', email: j['email'] ?? '', phone: j['phone'] ?? '',
      );
}

class Booking {
  String ref, status, meal;
  Flight flight;
  DateTime date;
  DateTime? returnDate;
  List<PassengerInfo> pax;
  List<String> seats;
  int baggageKg;
  bool insurance, checkedIn;
  double total;
  String method, gate, terminal;
  DateTime created;
  Booking({
    required this.ref,
    required this.flight,
    required this.date,
    this.returnDate,
    required this.pax,
    required this.seats,
    this.status = 'Confirmed',
    this.meal = 'Standard',
    this.baggageKg = 0,
    this.insurance = false,
    this.checkedIn = false,
    this.total = 0,
    this.method = 'Card',
    this.gate = 'B12',
    this.terminal = 'T3',
    DateTime? created,
  }) : created = created ?? DateTime.now();

  bool get isPast => status != 'Cancelled' &&
      date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
  bool get upcoming => status == 'Confirmed' && !isPast;
  String get lead => pax.isEmpty ? '' : pax.first.fullName;

  Map<String, dynamic> toJson() => {
        'ref': ref, 'status': status, 'meal': meal, 'flight': flight.toJson(),
        'date': date.toIso8601String(), 'returnDate': returnDate?.toIso8601String(),
        'pax': pax.map((p) => p.toJson()).toList(), 'seats': seats,
        'baggageKg': baggageKg, 'insurance': insurance, 'checkedIn': checkedIn,
        'total': total, 'method': method, 'gate': gate, 'terminal': terminal,
        'created': created.toIso8601String(),
      };
  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        ref: j['ref'], status: j['status'], meal: j['meal'],
        flight: Flight.fromJson(Map<String, dynamic>.from(j['flight'])),
        date: DateTime.parse(j['date']),
        returnDate: j['returnDate'] == null ? null : DateTime.parse(j['returnDate']),
        pax: (j['pax'] as List).map((e) => PassengerInfo.fromJson(Map<String, dynamic>.from(e))).toList(),
        seats: List<String>.from(j['seats']),
        baggageKg: j['baggageKg'], insurance: j['insurance'], checkedIn: j['checkedIn'],
        total: (j['total'] as num).toDouble(), method: j['method'],
        gate: j['gate'], terminal: j['terminal'], created: DateTime.parse(j['created']),
      );
}

class Txn {
  final String date, desc;
  final int miles;
  const Txn(this.date, this.desc, this.miles);
  Map<String, dynamic> toJson() => {'date': date, 'desc': desc, 'miles': miles};
  factory Txn.fromJson(Map<String, dynamic> j) => Txn(j['date'], j['desc'], j['miles']);
}

class Notif {
  final String id, title, body, time, route;
  final String? arg;
  bool read;
  Notif(this.id, this.title, this.body, this.time, this.route, {this.arg, this.read = false});
  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'body': body, 'time': time, 'route': route,
        'arg': arg, 'read': read,
      };
  factory Notif.fromJson(Map<String, dynamic> j) => Notif(
      j['id'], j['title'], j['body'], j['time'], j['route'], arg: j['arg'], read: j['read']);
}

class Profile {
  String name, email, phone, memberNo, tier, seatPref, mealPref, language, home;
  Map<String, bool> notify;
  List<PassengerInfo> saved;
  Profile({
    required this.name,
    required this.email,
    required this.phone,
    required this.memberNo,
    required this.tier,
    required this.seatPref,
    required this.mealPref,
    required this.language,
    required this.home,
    required this.notify,
    required this.saved,
  });
  String get first => name.split(' ').first;
  Map<String, dynamic> toJson() => {
        'name': name, 'email': email, 'phone': phone, 'memberNo': memberNo,
        'tier': tier, 'seatPref': seatPref, 'mealPref': mealPref,
        'language': language, 'home': home, 'notify': notify,
        'saved': saved.map((e) => e.toJson()).toList(),
      };
  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        name: j['name'], email: j['email'], phone: j['phone'],
        memberNo: j['memberNo'], tier: j['tier'], seatPref: j['seatPref'],
        mealPref: j['mealPref'], language: j['language'], home: j['home'],
        notify: Map<String, bool>.from(j['notify']),
        saved: (j['saved'] as List).map((e) => PassengerInfo.fromJson(Map<String, dynamic>.from(e))).toList(),
      );
}

class Offer {
  final String id, title, sub, tag;
  final String to;
  final int c1, c2;
  final double from;
  const Offer(this.id, this.title, this.sub, this.tag, this.to, this.c1, this.c2, this.from);
}

const offers = <Offer>[
  Offer('tokyo', 'Cherry blossom season', 'Fly to Tokyo from', 'LIMITED OFFER', 'NRT', 0xFF8E2C5B, 0xFF1B2A55, 780),
  Offer('bali', 'Island escape to Bali', 'Return fares from', 'EXCLUSIVE', 'DPS', 0xFF0E6E7E, 0xFF0B1F44, 320),
  Offer('sydney', 'Summer down under', 'Fly to Sydney from', 'MEMBERS ONLY', 'SYD', 0xFFB4541F, 0xFF0B1F44, 1180),
  Offer('london', 'Weekend in London', 'Non-stop from', 'NEW ROUTE', 'LHR', 0xFF3B3F7A, 0xFF0B1F44, 1420),
];

class Reward {
  final String id, title, sub;
  final int miles;
  const Reward(this.id, this.title, this.sub, this.miles);
}

const rewards = <Reward>[
  Reward('upgrade', 'Cabin upgrade', 'Economy to Premium Economy, one way', 18000),
  Reward('flight', 'Saver award flight', 'Singapore to Bangkok, Economy', 15500),
  Reward('lounge', 'Lounge pass', 'Single visit, Changi flagship lounge', 6000),
  Reward('bag', 'Extra 10kg baggage', 'Valid on any Singapore Airlines flight', 3500),
  Reward('seat', 'Extra-legroom seat', 'Choose on any upcoming trip', 2500),
];
