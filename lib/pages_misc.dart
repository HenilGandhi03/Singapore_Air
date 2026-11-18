import 'package:flutter/material.dart';
import 'brand.dart';
import 'main.dart';
import 'models.dart';
import 'pages_book.dart' show mealOptions;
import 'state.dart';
import 'ui.dart';

// ================================================================ FLIGHT STATUS
class StatusPage extends StatefulWidget {
  final String? initial;
  const StatusPage({super.key, this.initial});
  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusInfo {
  final Flight f;
  final String status, terminal, gate;
  final int delay;
  final Color color;
  _StatusInfo(
    this.f,
    this.status,
    this.terminal,
    this.gate,
    this.delay,
    this.color,
  );
}

class _StatusPageState extends State<StatusPage> {
  final c = TextEditingController();
  _StatusInfo? info;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      c.text = widget.initial!;
      WidgetsBinding.instance.addPostFrameCallback((_) => search());
    }
  }

  _StatusInfo? lookup(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    final n = int.parse(digits);
    final key = 'SQ $n';
    Flight? known;
    String? gate, term;
    for (final b in context.app.bookings) {
      if (b.flight.number.replaceAll(' ', '') == key.replaceAll(' ', '')) {
        known = b.flight;
        gate = b.gate;
        term = b.terminal;
      }
    }
    const routes = [
      ('BOM', 'SIN'),
      ('SIN', 'BOM'),
      ('SIN', 'BKK'),
      ('SIN', 'HKG'),
      ('DEL', 'SIN'),
      ('SIN', 'LHR'),
      ('SIN', 'SYD'),
      ('NRT', 'SIN'),
    ];
    final r = routes[n % routes.length];
    final f =
        known ??
        Flight(
          key,
          r.$1,
          r.$2,
          'Airbus A350-900',
          'Economy',
          (6 * 60 + (n * 37) % 900),
          searchFlights(r.$1, r.$2, 'Economy')[0].durMin,
          0,
        );
    final k = n % 5;
    const st = [
      ('On time', good, 0),
      ('Boarding', Color(0xFF2A6BD6), 0),
      ('Delayed', Color(0xFFE08A00), 35),
      ('Departed', navy2, 0),
      ('Landed', muted, 0),
    ];
    return _StatusInfo(
      f,
      st[k].$1,
      term ?? 'T${1 + n % 3}',
      gate ?? '${'ABCD'[n % 4]}${3 + n % 18}',
      st[k].$3,
      st[k].$2,
    );
  }

  void search() async {
    FocusScope.of(context).unfocus();
    if (c.text.replaceAll(RegExp(r'\D'), '').isEmpty) {
      toast(context, 'Enter a flight number, e.g. SQ 423');
      return;
    }
    setState(() {
      busy = true;
      info = null;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      busy = false;
      info = lookup(c.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = context.app;
    final i = info;
    return Screen(
      title: 'Flight status',
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          CardBox(
            child: Column(
              children: [
                Field(
                  'Flight number',
                  c: c,
                  hint: 'e.g. SQ 423',
                  icon: Icons.flight,
                  suffix: IconButton(
                    onPressed: search,
                    icon: const Icon(Icons.search, color: navy),
                  ),
                ),
                PrimaryBtn('Check status', loading: busy, onTap: search),
              ],
            ),
          ),
          if (a.upcoming.isNotEmpty) ...[
            const H('Your flights'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in a.upcoming)
                  ActionChip(
                    backgroundColor: goldSoft,
                    side: BorderSide.none,
                    avatar: const Icon(Icons.flight, size: 16, color: navy),
                    label: Text(
                      '${b.flight.number}  ${b.flight.from}-${b.flight.to}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      c.text = b.flight.number;
                      search();
                    },
                  ),
              ],
            ),
          ],
          if (i != null) ...[
            const SizedBox(height: 18),
            CardBox(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(i.f.number, style: serif(22)),
                      const Spacer(),
                      Pill(i.status, color: i.color),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${fmtDate(DateTime.now())}  |  ${i.f.aircraft}',
                    style: const TextStyle(color: muted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 18),
                  RouteRow(
                    from: i.f.from,
                    to: i.f.to,
                    dep: i.f.dep,
                    arr: i.f.arr,
                    dur: i.f.duration,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        airportBy(i.f.from).city,
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                      const Spacer(),
                      Text(
                        airportBy(i.f.to).city,
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                  const Divider(height: 30, color: line),
                  KV('Origin', airportBy(i.f.from).name),
                  KV('Destination', airportBy(i.f.to).name),
                  KV('Scheduled departure', i.f.dep),
                  KV(
                    'Scheduled arrival',
                    '${i.f.arr}${i.f.dayOffset > 0 ? ' +${i.f.dayOffset}' : ''}',
                  ),
                  if (i.delay > 0)
                    KV('Estimated departure', hm(i.f.depMin + i.delay)),
                  KV('Terminal', i.terminal),
                  KV('Gate', i.gate),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ================================================================ MILES
class MilesPage extends StatelessWidget {
  const MilesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final a = context.app;
    final p = a.profile;
    const next = 150000;
    return Screen(
      title: 'KrisFlyer',

      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF07142E), navy2],
              ),
              boxShadow: [
                BoxShadow(
                  color: navy.withValues(alpha: .3),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SiaLogo(height: 32, light: true),
                    const SizedBox(width: 10),
                    Text(
                      'KRISFLYER',
                      style: serif(
                        13,
                        c: Colors.white,
                      ).copyWith(letterSpacing: 2),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [gold, Color(0xFFE8D29A)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        p.tier.toUpperCase(),
                        style: const TextStyle(
                          color: navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const Text(
                  'AVAILABLE MILES',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
                Text(num0(a.miles), style: serif(42, c: Colors.white)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            p.memberNo,
                            style: const TextStyle(
                              color: gold,
                              letterSpacing: 2,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    QrBox(p.memberNo, size: 54),
                  ],
                ),
              ],
            ),
          ),
          CardBox(
            margin: const EdgeInsets.only(top: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Progress to Platinum',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      '${num0(a.earned)} / ${num0(next)}',
                      style: const TextStyle(color: muted, fontSize: 12.5),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (a.earned / next).clamp(0, 1),
                    minHeight: 9,
                    backgroundColor: line,
                    color: gold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${num0((next - a.earned).clamp(0, next))} more miles to unlock lounge guests and priority upgrades.',
                  style: const TextStyle(color: muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _stat('Earned', num0(a.earned), Icons.trending_up, good),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _stat(
                  'Redeemed',
                  num0(a.redeemed),
                  Icons.redeem,
                  const Color(0xFFB4541F),
                ),
              ),
            ],
          ),
          const H('Redeem miles'),
          for (final r in rewards)
            CardBox(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: const BoxDecoration(
                      color: goldSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_ri(r.id), color: navy),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          r.sub,
                          style: const TextStyle(color: muted, fontSize: 12.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${num0(r.miles)} miles',
                          style: const TextStyle(
                            color: navy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (a.miles < r.miles) {
                          toast(
                            context,
                            'Not enough miles. You need ${num0(r.miles - a.miles)} more.',
                          );
                          return;
                        }
                        final ok = await confirmDialog(
                          context,
                          'Redeem ${r.title}?',
                          '${num0(r.miles)} miles will be deducted from your balance of ${num0(a.miles)}.',
                          yes: 'Redeem',
                        );
                        if (ok && context.mounted) {
                          a.redeem(r);
                          toast(
                            context,
                            '${r.title} redeemed. New balance ${num0(a.miles)} miles',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: a.miles >= r.miles ? navy : line,
                        foregroundColor: a.miles >= r.miles
                            ? Colors.white
                            : muted,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Redeem',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const H('Transaction history'),
          CardBox(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                for (final t in a.txns.take(12))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: (t.miles >= 0 ? good : bad).withValues(
                        alpha: .12,
                      ),
                      child: Icon(
                        t.miles >= 0 ? Icons.add : Icons.remove,
                        size: 16,
                        color: t.miles >= 0 ? good : bad,
                      ),
                    ),
                    title: Text(
                      t.desc,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(t.date),
                    trailing: Text(
                      '${t.miles >= 0 ? '+' : ''}${num0(t.miles)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: t.miles >= 0 ? good : bad,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _ri(String id) => switch (id) {
    'upgrade' => Icons.airline_seat_flat,
    'flight' => Icons.flight,
    'lounge' => Icons.weekend,
    'bag' => Icons.luggage,
    _ => Icons.event_seat,
  };

  Widget _stat(String t, String v, IconData i, Color c) => CardBox(
    child: Row(
      children: [
        Icon(i, color: c),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t, style: const TextStyle(color: muted, fontSize: 12)),
            Text(v, style: serif(20)),
          ],
        ),
      ],
    ),
  );
}

// ================================================================ PROFILE
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final name = TextEditingController(text: context.app.profile.name);
  late final email = TextEditingController(text: context.app.profile.email);
  late final phone = TextEditingController(text: context.app.profile.phone);
  late String seat = context.app.profile.seatPref;
  late String meal = context.app.profile.mealPref;
  late String lang = context.app.profile.language;
  late String home = context.app.profile.home;

  void save() {
    final a = context.app, p = a.profile;
    if (name.text.trim().isEmpty || !email.text.contains('@')) {
      toast(context, 'Please enter a name and a valid email');
      return;
    }
    p.name = name.text.trim();
    p.email = email.text.trim();
    p.phone = phone.text.trim();
    p.seatPref = seat;
    p.mealPref = meal;
    p.language = lang;
    p.home = home;
    a.saveProfile();
    FocusScope.of(context).unfocus();
    toast(context, 'Profile saved');
  }

  @override
  Widget build(BuildContext context) {
    final a = context.app;
    final p = a.profile;
    return Screen(
      title: 'Profile',

      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () => Navigator.of(context).pushNamed('notifications'),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: gold, width: 2.5),
                  color: navy,
                ),
                alignment: Alignment.center,
                child: Text(p.first[0], style: serif(30, c: Colors.white)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: serif(22)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          color: gold,
                          size: 17,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${p.tier}  |  ${p.memberNo}',
                          style: const TextStyle(color: muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const H('Personal details'),
          CardBox(
            child: Column(
              children: [
                Field('Full name', c: name, icon: Icons.person_outline),
                Field(
                  'Email',
                  c: email,
                  icon: Icons.mail_outline,
                  type: TextInputType.emailAddress,
                ),
                Field(
                  'Mobile number',
                  c: phone,
                  icon: Icons.phone_outlined,
                  type: TextInputType.phone,
                ),
              ],
            ),
          ),
          const H('Travel preferences'),
          CardBox(
            child: Column(
              children: [
                Pick<String>(
                  'Seat preference',
                  seat,
                  const ['Window', 'Aisle', 'Extra legroom', 'No preference'],
                  (v) => setState(() => seat = v),
                  icon: Icons.event_seat,
                ),
                Pick<String>(
                  'Meal preference',
                  meal,
                  mealOptions.where((m) => !m.startsWith('Book')).toList(),
                  (v) => setState(() => meal = v),
                  icon: Icons.restaurant,
                ),
                Pick<String>(
                  'Language',
                  lang,
                  const [
                    'English',
                    'Hindi',
                    'Mandarin',
                    'Malay',
                    'Tamil',
                    'Japanese',
                  ],
                  (v) => setState(() => lang = v),
                  icon: Icons.language,
                ),
                Pick<String>(
                  'Home airport',
                  home,
                  [for (final x in airports) x.code],
                  (v) => setState(() => home = v),
                  show: (c) => airportBy(c).label,
                  icon: Icons.home_outlined,
                ),
              ],
            ),
          ),
          PrimaryBtn(
            'Save changes',
            icon: Icons.check,
            goldStyle: true,
            onTap: save,
          ),
          const H('Notification preferences'),
          CardBox(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                for (final e in p.notify.entries)
                  SwitchListTile(
                    title: Text(
                      e.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    value: e.value,
                    activeColor: navy,
                    activeTrackColor: gold,
                    onChanged: (v) {
                      p.notify[e.key] = v;
                      a.saveProfile();
                    },
                  ),
              ],
            ),
          ),
          H(
            'Saved passengers',
            trailing: TextButton.icon(
              onPressed: () => _addPax(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ),
          CardBox(
            child: p.saved.isEmpty
                ? const Text(
                    'No saved passengers',
                    style: TextStyle(color: muted),
                  )
                : Column(
                    children: [
                      for (final s in p.saved)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: goldSoft,
                            child: Icon(Icons.person, color: navy),
                          ),
                          title: Text(
                            s.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('Passport ${s.passport}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: bad),
                            onPressed: () {
                              p.saved.remove(s);
                              a.saveProfile();
                              toast(context, '${s.first} removed');
                            },
                          ),
                        ),
                    ],
                  ),
          ),
          const H('Demo controls'),
          Row(
            children: [
              Expanded(
                child: PrimaryBtn(
                  'Reset demo data',
                  outline: true,
                  icon: Icons.restart_alt,
                  onTap: () async {
                    final ok = await confirmDialog(
                      context,
                      'Reset demo data?',
                      'This restores the sample bookings, miles and notifications.',
                      yes: 'Reset',
                    );
                    if (ok) {
                      await a.resetDemo();
                      name.text = a.profile.name;
                      email.text = a.profile.email;
                      phone.text = a.profile.phone;
                      if (context.mounted) toast(context, 'Demo data restored');
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryBtn(
                  'Sign out',
                  outline: true,
                  icon: Icons.logout,
                  onTap: () => a.signOut(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Singapore Airlines is a fictional demo. Not affiliated with any real airline.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _addPax(BuildContext c) {
    final f = TextEditingController(),
        l = TextEditingController(),
        pp = TextEditingController();
    sheet(
      c,
      (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add passenger', style: serif(20)),
            const SizedBox(height: 14),
            Field('First name', c: f),
            Field('Last name', c: l),
            Field('Passport number', c: pp),
            PrimaryBtn(
              'Save passenger',
              goldStyle: true,
              onTap: () {
                if (f.text.trim().isEmpty || l.text.trim().isEmpty) {
                  toast(c, 'Please enter first and last name');
                  return;
                }
                c.app.profile.saved.add(
                  PassengerInfo(
                    first: f.text.trim(),
                    last: l.text.trim(),
                    passport: pp.text.trim(),
                    nationality: 'Indian',
                  ),
                );
                c.app.saveProfile();
                Navigator.pop(ctx);
                toast(c, 'Passenger saved');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ================================================================ NOTIFICATIONS
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  IconData _icon(String r) => switch (r) {
    'trip' => Icons.confirmation_number_outlined,
    'checkin' => Icons.how_to_reg,
    'pass' => Icons.qr_code_2,
    'offer' => Icons.local_offer_outlined,
    _ => Icons.notifications_none,
  };

  @override
  Widget build(BuildContext context) {
    final a = context.app;
    return Screen(
      title: 'Notifications',
      actions: [
        IconButton(
          tooltip: 'Simulate a notification',
          icon: const Icon(Icons.add_alert_outlined),
          onPressed: () {
            final b = a.nextTrip;
            a.notifs.insert(
              0,
              Notif(
                'n${DateTime.now().millisecondsSinceEpoch}',
                'Gate update',
                b == null
                    ? 'Gate changed to B14 for your next flight.'
                    : 'Your gate for ${b.flight.number} has changed to B14.',
                'Just now',
                b == null ? 'home' : 'trip',
                arg: b?.ref,
              ),
            );
            a.saveProfile();
          },
        ),
        TextButton(
          onPressed: a.markAllRead,
          child: const Text('Read all', style: TextStyle(color: gold)),
        ),
      ],
      body: a.notifs.isEmpty
          ? const Center(
              child: Text(
                'You\'re all caught up',
                style: TextStyle(color: muted),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                for (final n in a.notifs)
                  CardBox(
                    padding: const EdgeInsets.all(14),
                    color: n.read ? Colors.white : const Color(0xFFFFFBF0),
                    onTap: () => goNotif(context, n),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: goldSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_icon(n.route), color: navy, size: 21),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: TextStyle(
                                        fontWeight: n.read
                                            ? FontWeight.w600
                                            : FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  if (!n.read)
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: const BoxDecoration(
                                        color: gold,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                n.body,
                                style: const TextStyle(
                                  color: muted,
                                  height: 1.35,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                n.time,
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 11.5,
                                ),
                              ),
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
}

// ================================================================ OFFER
class OfferPage extends StatelessWidget {
  final String id;
  const OfferPage({super.key, required this.id});
  @override
  Widget build(BuildContext context) {
    final o = offers.firstWhere((x) => x.id == id, orElse: () => offers.first);
    final a = context.app;
    final dest = airportBy(o.to);
    return Screen(
      title: dest.city,
      bottom: PrimaryBtn(
        'Book ${a.profile.home} to ${o.to}',
        goldStyle: true,
        icon: Icons.flight_takeoff,
        onTap: () {
          a.from = a.profile.home == o.to ? 'SIN' : a.profile.home;
          a.to = o.to;
          a.notify();
          a.goTab(1, 'results');
        },
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Scenic(
            c1: o.c1,
            c2: o.c2,
            height: 240,
            radius: 0,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: gold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      o.tag,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: navy,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(o.title, style: serif(28, c: Colors.white)),
                  Text(
                    '${o.sub} ${money(o.from)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          Pad(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const H('What\'s included'),
                for (final t in [
                  'Complimentary meals and entertainment',
                  '30kg checked baggage in Economy',
                  'Earn double KrisFlyer on this route',
                  'Free change of date up to 24 hours before departure',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: gold, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(t, style: const TextStyle(height: 1.3)),
                        ),
                      ],
                    ),
                  ),
                const H('About this offer'),
                Text(
                  'Experience ${dest.city} with fares from ${money(o.from)} return. Travel is available on selected dates, subject to availability. This is a simulated offer for demonstration only.',
                  style: const TextStyle(color: muted, height: 1.5),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================ MORE
class MorePage extends StatelessWidget {
  const MorePage({super.key});
  @override
  Widget build(BuildContext context) {
    final a = context.app;
    Widget tile(
      IconData i,
      String t,
      String sub,
      VoidCallback f, {
      int badge = 0,
    }) => CardBox(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: f,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFEAF0FA),
              shape: BoxShape.circle,
            ),
            child: Icon(i, color: navy, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(sub, style: const TextStyle(color: muted, fontSize: 12.5)),
              ],
            ),
          ),
          if (badge > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFD0021B),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const Icon(Icons.chevron_right, color: muted),
        ],
      ),
    );
    return Screen(
      title: 'More',
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Row(children: [
          //   const SiaLogo(height: 40),
          // ]),
          const SizedBox(height: 16),
          tile(
            Icons.workspace_premium,
            'KrisFlyer',
            '${a.profile.tier}  |  ${num0(a.miles)} miles',
            () => Navigator.of(context).pushNamed('miles'),
          ),
          tile(
            Icons.person_outline,
            'Profile',
            'Details, preferences, saved passengers',
            () => Navigator.of(context).pushNamed('profile'),
          ),
          tile(
            Icons.notifications_none,
            'Notifications',
            'Trip alerts and offers',
            () => Navigator.of(context).pushNamed('notifications'),
            badge: a.unread,
          ),
          tile(
            Icons.how_to_reg,
            'Online check-in',
            'Check in and get your boarding pass',
            () => a.goTab(2, 'checkin'),
          ),
          tile(
            Icons.qr_code_2,
            'Boarding pass',
            'View your digital boarding pass',
            () => openRoute(
              context,
              'pass',
              (a.upcoming.where((b) => b.checkedIn).firstOrNull ??
                          a.upcoming.firstOrNull)
                      ?.ref ??
                  '',
              2,
            ),
          ),
          tile(
            Icons.local_offer_outlined,
            'Offers',
            'Latest deals and promotions',
            () => Navigator.of(context).pushNamed('offer', arguments: 'tokyo'),
          ),
        ],
      ),
    );
  }
}
