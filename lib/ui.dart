import 'dart:math';
import 'package:flutter/material.dart';

const navy = Color(0xFF00267F);
const navy2 = Color(0xFF123F8F);
const sqBlue = Color(0xFF0A73C9);
const gold = Color(0xFFB8893A);
const goldSoft = Color(0xFFF6EEDB);
const bg = Color(0xFFF4F5F9);
const ink = Color(0xFF1B2335);
const muted = Color(0xFF6B7488);
const line = Color(0xFFE3E6EE);
const good = Color(0xFF1E8E5A);
const bad = Color(0xFFC0392B);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy, secondary: gold),
    scaffoldBackgroundColor: bg,
    fontFamily: 'Helvetica Neue',
    fontFamilyFallback: const ['Roboto', 'Arial'],
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: .3),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: navy, width: 1.6)),
      labelStyle: const TextStyle(color: muted),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: navy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
    }),
  );
}

void toast(BuildContext c, String msg) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
}

TextStyle serif(double s, {Color c = navy, FontWeight w = FontWeight.w600}) =>
    TextStyle(fontFamily: 'Georgia', fontFamilyFallback: const ['Times New Roman', 'serif'], fontSize: s, color: c, fontWeight: w);

// ---------------------------------------------------------------- logo
class Logo extends StatelessWidget {
  final double size;
  final bool light;
  const Logo({super.key, this.size = 64, this.light = true});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _LogoPainter(light)),
      );
}

class _LogoPainter extends CustomPainter {
  final bool light;
  _LogoPainter(this.light);
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = gold..style = PaintingStyle.stroke..strokeWidth = s.width * .05..strokeCap = StrokeCap.round;
    c.drawCircle(s.center(Offset.zero), s.width * .46, p);
    final f = Paint()..color = light ? Colors.white : navy;
    // stylised bird / wing mark
    final path = Path()
      ..moveTo(s.width * .2, s.height * .62)
      ..quadraticBezierTo(s.width * .45, s.height * .5, s.width * .8, s.height * .28)
      ..quadraticBezierTo(s.width * .6, s.height * .52, s.width * .5, s.height * .75)
      ..quadraticBezierTo(s.width * .46, s.height * .58, s.width * .2, s.height * .62)
      ..close();
    c.drawPath(path, f);
    final w2 = Path()
      ..moveTo(s.width * .3, s.height * .7)
      ..quadraticBezierTo(s.width * .5, s.height * .62, s.width * .7, s.height * .56)
      ..quadraticBezierTo(s.width * .55, s.height * .72, s.width * .5, s.height * .82)
      ..close();
    c.drawPath(w2, Paint()..color = gold);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ---------------------------------------------------------------- basic widgets
class Pad extends StatelessWidget {
  final Widget child;
  const Pad(this.child, {super.key});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: child);
}

class CardBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  final EdgeInsets margin;
  const CardBox({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color = Colors.white, this.margin = const EdgeInsets.only(bottom: 12)});
  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: navy.withValues(alpha: .06), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      );
}

class PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool outline, loading, goldStyle;
  const PrimaryBtn(this.label, {super.key, this.onTap, this.icon, this.outline = false, this.loading = false, this.goldStyle = false});
  @override
  Widget build(BuildContext context) {
    final fg = outline ? navy : (goldStyle ? navy : Colors.white);
    final bgc = outline ? Colors.transparent : (goldStyle ? gold : navy);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgc, foregroundColor: fg, elevation: 0,
          disabledBackgroundColor: bgc.withValues(alpha: .6),
          side: outline ? const BorderSide(color: navy, width: 1.4) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: .3),
        ),
        child: loading
            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ]),
      ),
    );
  }
}

class SmallBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool danger;
  const SmallBtn(this.label, this.onTap, {super.key, this.icon, this.danger = false});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon ?? Icons.chevron_right, size: 17),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: danger ? bad : navy,
          side: BorderSide(color: danger ? bad.withValues(alpha: .5) : line, width: 1.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
}

class H extends StatelessWidget {
  final String t;
  final Widget? trailing;
  const H(this.t, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(t, style: serif(19)),
          if (trailing != null) trailing!,
        ]),
      );
}

class Pill extends StatelessWidget {
  final String t;
  final Color color;
  const Pill(this.t, {super.key, this.color = good});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

class KV extends StatelessWidget {
  final String k, v;
  final bool bold;
  const KV(this.k, this.v, {super.key, this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k, style: TextStyle(color: bold ? ink : muted, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          const SizedBox(width: 12),
          Flexible(child: Text(v, textAlign: TextAlign.right, style: TextStyle(color: ink, fontWeight: bold ? FontWeight.w800 : FontWeight.w600))),
        ]),
      );
}

class Screen extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottom;
  final bool canPop;
  const Screen({super.key, required this.title, required this.body, this.actions, this.bottom, this.canPop = true});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: actions,
          automaticallyImplyLeading: canPop && Navigator.of(context).canPop(),
        ),
        body: body,
        bottomNavigationBar: bottom == null
            ? null
            : Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: navy.withValues(alpha: .08), blurRadius: 16, offset: const Offset(0, -4))]),
                child: SafeArea(top: false, child: bottom!),
              ),
      );
}

class StepBar extends StatelessWidget {
  final int step;
  final List<String> labels;
  const StepBar(this.step, this.labels, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        color: navy,
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        child: Row(children: [
          for (var i = 0; i < labels.length; i++) ...[
            Expanded(
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(color: i <= step ? gold : Colors.white24, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 6),
                Text(labels[i], style: TextStyle(color: i <= step ? Colors.white : Colors.white54, fontSize: 11, fontWeight: i == step ? FontWeight.w700 : FontWeight.w400)),
              ]),
            ),
            if (i < labels.length - 1) const SizedBox(width: 6),
          ]
        ]),
      );
}

class Field extends StatelessWidget {
  final String label;
  final TextEditingController? c;
  final String? hint;
  final TextInputType? type;
  final IconData? icon;
  final bool obscure, readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  const Field(this.label, {super.key, this.c, this.hint, this.type, this.icon, this.obscure = false, this.readOnly = false, this.onTap, this.onChanged, this.suffix});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c, keyboardType: type, obscureText: obscure, readOnly: readOnly, onTap: onTap, onChanged: onChanged,
          decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: icon == null ? null : Icon(icon, color: muted, size: 20), suffixIcon: suffix),
        ),
      );
}

class Pick<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T)? show;
  final ValueChanged<T> onChanged;
  final IconData? icon;
  const Pick(this.label, this.value, this.items, this.onChanged, {super.key, this.show, this.icon});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: label, prefixIcon: icon == null ? null : Icon(icon, color: muted, size: 20)),
          items: [for (final i in items) DropdownMenuItem(value: i, child: Text(show?.call(i) ?? '$i', overflow: TextOverflow.ellipsis))],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      );
}

class Stepper2 extends StatelessWidget {
  final int value, min, max, step;
  final ValueChanged<int> onChanged;
  const Stepper2(this.value, this.onChanged, {super.key, this.min = 0, this.max = 99, this.step = 1});
  @override
  Widget build(BuildContext context) {
    Widget b(IconData i, VoidCallback? f) => InkWell(
          onTap: f,
          borderRadius: BorderRadius.circular(20),
          child: Container(width: 34, height: 34, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: f == null ? line : navy)), child: Icon(i, size: 18, color: f == null ? line : navy)),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      b(Icons.remove, value - step >= min ? () => onChanged(value - step) : null),
      SizedBox(width: 46, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
      b(Icons.add, value + step <= max ? () => onChanged(value + step) : null),
    ]);
  }
}

Future<T?> sheet<T>(BuildContext c, Widget Function(BuildContext) b) => showModalBottomSheet<T>(
      context: c,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(margin: const EdgeInsets.only(top: 10, bottom: 6), width: 40, height: 4, decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(4))),
            Flexible(child: b(ctx)),
          ]),
        ),
      ),
    );

Future<bool> confirmDialog(BuildContext c, String title, String body, {String yes = 'Confirm', bool danger = false}) async {
  final r = await showDialog<bool>(
    context: c,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(title, style: serif(19)),
      content: Text(body, style: const TextStyle(color: muted, height: 1.4)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(yes, style: TextStyle(color: danger ? bad : navy, fontWeight: FontWeight.w700))),
      ],
    ),
  );
  return r ?? false;
}

// ---------------------------------------------------------------- scenic art
class Scenic extends StatelessWidget {
  final int c1, c2;
  final double height;
  final Widget? child;
  final double radius;
  const Scenic({super.key, required this.c1, required this.c2, this.height = 180, this.child, this.radius = 24});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          height: height,
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(c1), Color(c2)])),
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _ScenePainter())),
            if (child != null) Positioned.fill(child: child!),
          ]),
        ),
      );
}

class _ScenePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.drawCircle(Offset(s.width * .78, s.height * .3), s.height * .22, Paint()..color = Colors.white.withValues(alpha: .16));
    c.drawCircle(Offset(s.width * .78, s.height * .3), s.height * .14, Paint()..color = gold.withValues(alpha: .55));
    final r = Random(7);
    final p = Paint()..color = Colors.black.withValues(alpha: .22);
    double x = 0;
    while (x < s.width) {
      final w = 14 + r.nextDouble() * 26, h = s.height * (.12 + r.nextDouble() * .3);
      c.drawRect(Rect.fromLTWH(x, s.height - h, w, h), p);
      x += w + 2;
    }
    final wave = Path()..moveTo(0, s.height * .9);
    for (double i = 0; i <= s.width; i += 10) {
      wave.lineTo(i, s.height * .9 + sin(i / 22) * 4);
    }
    wave..lineTo(s.width, s.height)..lineTo(0, s.height)..close();
    c.drawPath(wave, Paint()..color = Colors.black.withValues(alpha: .25));
  }

  @override
  bool shouldRepaint(_) => false;
}

// ---------------------------------------------------------------- QR / barcode
class QrBox extends StatelessWidget {
  final String data;
  final double size;
  const QrBox(this.data, {super.key, this.size = 150});
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size, child: CustomPaint(painter: QrPainter(data)));
}

List<List<bool>> qrMatrix(String data, [int n = 29]) {
  var h = 17;
  for (final u in data.codeUnits) {
    h = (h * 31 + u) & 0x7fffffff;
  }
  final r = Random(h);
  final m = List.generate(n, (_) => List.generate(n, (_) => r.nextDouble() > .5));
  void finder(int ox, int oy) {
    for (var y = -1; y <= 7; y++) {
      for (var x = -1; x <= 7; x++) {
        final px = ox + x, py = oy + y;
        if (px < 0 || py < 0 || px >= n || py >= n) continue;
        final edge = x == 0 || x == 6 || y == 0 || y == 6;
        final inner = x >= 2 && x <= 4 && y >= 2 && y <= 4;
        m[py][px] = (x >= 0 && x <= 6 && y >= 0 && y <= 6) && (edge || inner);
      }
    }
  }

  finder(0, 0);
  finder(n - 7, 0);
  finder(0, n - 7);
  return m;
}

class QrPainter extends CustomPainter {
  final String data;
  QrPainter(this.data);
  @override
  void paint(Canvas c, Size s) {
    final m = qrMatrix(data);
    final n = m.length;
    final cell = s.width / n;
    final p = Paint()..color = navy;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (m[y][x]) c.drawRect(Rect.fromLTWH(x * cell, y * cell, cell + .4, cell + .4), p);
      }
    }
  }

  @override
  bool shouldRepaint(QrPainter o) => o.data != data;
}

class BarcodePainter extends CustomPainter {
  final String data;
  BarcodePainter(this.data);
  @override
  void paint(Canvas c, Size s) {
    var h = 5;
    for (final u in data.codeUnits) {
      h = (h * 33 + u) & 0x7fffffff;
    }
    final r = Random(h);
    double x = 0;
    final p = Paint()..color = ink;
    while (x < s.width) {
      final w = 1.0 + r.nextInt(3);
      if (r.nextBool()) c.drawRect(Rect.fromLTWH(x, 0, w, s.height), p);
      x += w + 1;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ---------------------------------------------------------------- seat map
const _layouts = {
  'Economy': (start: 20, rows: 17, groups: [['A', 'B', 'C'], ['D', 'E', 'F']]),
  'Premium Economy': (start: 10, rows: 8, groups: [['A', 'B'], ['D', 'E', 'F'], ['H', 'K']]),
  'Business': (start: 1, rows: 8, groups: [['A'], ['D', 'G'], ['K']]),
  'First': (start: 1, rows: 4, groups: [['A'], ['K']]),
};

class SeatMap extends StatelessWidget {
  final String cabin, seed;
  final List<String> selected;
  final int max;
  final ValueChanged<List<String>> onChanged;
  final List<String> mine; // seats already owned (never shown as taken)
  const SeatMap({super.key, required this.cabin, required this.seed, required this.selected, required this.max, required this.onChanged, this.mine = const []});

  bool taken(String s) {
    if (mine.contains(s)) return false;
    var h = 3;
    for (final u in '$seed$s'.codeUnits) {
      h = (h * 31 + u) & 0x7fffffff;
    }
    return h % 100 < 30;
  }

  @override
  Widget build(BuildContext context) {
    final l = _layouts[cabin] ?? _layouts['Economy']!;
    Widget seat(String id, bool legroom) {
      final t = taken(id), sel = selected.contains(id);
      return GestureDetector(
        onTap: t
            ? null
            : () {
                final n = List<String>.of(selected);
                if (sel) {
                  n.remove(id);
                } else {
                  if (max == 1) {
                    n.clear();
                  } else if (n.length >= max) {
                    toast(context, 'All $max seat(s) already chosen. Tap one to change it.');
                    return;
                  }
                  n.add(id);
                }
                onChanged(n);
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 34, height: 34, margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: sel ? gold : t ? const Color(0xFFD9DDE6) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10), bottom: Radius.circular(5)),
            border: Border.all(color: sel ? gold : legroom && !t ? gold : line, width: legroom && !t ? 1.6 : 1.2),
          ),
          alignment: Alignment.center,
          child: t
              ? const Icon(Icons.close, size: 14, color: Colors.white)
              : Text(id.replaceAll(RegExp(r'\d'), ''), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sel ? navy : muted)),
        ),
      );
    }

    return Column(children: [
      Wrap(spacing: 14, runSpacing: 6, alignment: WrapAlignment.center, children: [
        _legend(Colors.white, line, 'Free'),
        _legend(Colors.white, gold, cabin == 'Economy' ? 'Legroom +SGD 28' : 'Premium'),
        _legend(gold, gold, 'Selected'),
        _legend(const Color(0xFFD9DDE6), const Color(0xFFD9DDE6), 'Taken'),
      ]),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFFF1F3F8), borderRadius: BorderRadius.circular(28)),
        child: Column(children: [
          for (var i = 0; i < l.rows; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var g = 0; g < l.groups.length; g++) ...[
                  if (g > 0)
                    SizedBox(width: 30, child: g == 1 ? Center(child: Text('${l.start + i}', style: const TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w600))) : null),
                  for (final ch in l.groups[g]) seat('${l.start + i}$ch', cabin == 'Economy' ? (l.start + i) <= 24 : cabin != 'Economy'),
                ],
              ]),
            ),
        ]),
      ),
    ]);
  }

  Widget _legend(Color fill, Color border, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(5), border: Border.all(color: border, width: 1.4))),
        const SizedBox(width: 5),
        Text(t, style: const TextStyle(fontSize: 12, color: muted)),
      ]);
}

// ---------------------------------------------------------------- flight route row
class RouteRow extends StatelessWidget {
  final String from, to, dep, arr, dur;
  final bool light;
  const RouteRow({super.key, required this.from, required this.to, required this.dep, required this.arr, required this.dur, this.light = false});
  @override
  Widget build(BuildContext context) {
    final fg = light ? Colors.white : navy;
    final sub = light ? Colors.white70 : muted;
    Widget side(String code, String time, CrossAxisAlignment a) => Column(crossAxisAlignment: a, children: [
          Text(code, style: serif(28, c: fg)),
          Text(time, style: TextStyle(color: sub, fontSize: 13, fontWeight: FontWeight.w600)),
        ]);
    return Row(children: [
      side(from, dep, CrossAxisAlignment.start),
      Expanded(
        child: Column(children: [
          Text(dur, style: TextStyle(color: sub, fontSize: 12)),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(child: Container(height: 1.4, color: sub.withValues(alpha: .5))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.flight, color: gold, size: 20)),
            Expanded(child: Container(height: 1.4, color: sub.withValues(alpha: .5))),
          ]),
          const SizedBox(height: 4),
          Text('Non-stop', style: TextStyle(color: sub, fontSize: 11)),
        ]),
      ),
      side(to, arr, CrossAxisAlignment.end),
    ]);
  }
}
