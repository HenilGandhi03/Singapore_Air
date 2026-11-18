import 'models.dart';
import 'ui.dart';

/// Builds a self-contained HTML boarding pass (demo file) for download.
String boardingPassHtml(Booking b, int paxIndex) {
  final p = b.pax[paxIndex];
  final from = airportBy(b.flight.from), to = airportBy(b.flight.to);
  final seat = paxIndex < b.seats.length ? b.seats[paxIndex] : 'TBA';
  final boarding = hm(b.flight.depMin - 45);
  final m = qrMatrix('${b.ref}|${b.flight.number}|${p.fullName}|$seat');
  const cell = 5;
  final rects = StringBuffer();
  for (var y = 0; y < m.length; y++) {
    for (var x = 0; x < m.length; x++) {
      if (m[y][x]) rects.write('<rect x="${x * cell}" y="${y * cell}" width="$cell" height="$cell"/>');
    }
  }
  final size = m.length * cell;
  return '''<!doctype html><html><head><meta charset="utf-8"><title>Boarding pass ${b.ref}</title>
<style>body{font-family:Helvetica,Arial,sans-serif;background:#eef0f6;padding:30px}
.p{max-width:520px;margin:auto;background:#fff;border-radius:22px;overflow:hidden;box-shadow:0 10px 30px rgba(11,31,68,.15)}
.h{background:#0B1F44;color:#fff;padding:18px 24px;display:flex;justify-content:space-between}
.h b{color:#C9A55C}.r{display:flex;justify-content:space-between;padding:22px 24px 8px}
.r div{font-size:34px;color:#0B1F44;font-family:Georgia,serif}.r small{display:block;font:12px Helvetica;color:#6B7488}
.g{display:grid;grid-template-columns:repeat(3,1fr);gap:14px;padding:12px 24px}
.g span{font-size:11px;color:#6B7488;display:block}.g b{font-size:16px;color:#1B2335}
.q{text-align:center;padding:16px;border-top:2px dashed #E3E6EE}.f{font-size:11px;color:#6B7488;text-align:center;padding-bottom:14px}</style></head><body>
<div class="p"><div class="h"><span><b>SINGAPORE AIRLINES</b> &nbsp; Boarding pass</span><span>${b.flight.cabin}</span></div>
<div class="r"><div>${from.code}<small>${from.city}</small></div><div>&#9992;</div><div>${to.code}<small>${to.city}</small></div></div>
<div class="g"><p><span>PASSENGER</span><b>${p.fullName.toUpperCase()}</b></p><p><span>FLIGHT</span><b>${b.flight.number}</b></p><p><span>DATE</span><b>${fmtShort(b.date)} ${b.date.year}</b></p>
<p><span>BOARDING</span><b>$boarding</b></p><p><span>GATE</span><b>${b.gate}</b></p><p><span>SEAT</span><b>$seat</b></p>
<p><span>DEPARTS</span><b>${b.flight.dep}</b></p><p><span>TERMINAL</span><b>${b.terminal}</b></p><p><span>BOOKING</span><b>${b.ref}</b></p></div>
<div class="q"><svg width="150" height="150" viewBox="0 0 $size $size" fill="#0B1F44">$rects</svg></div>
<div class="f">Demo boarding pass for prototype purposes only. Not valid for travel.</div></div></body></html>''';
}

String boardingPassName(Booking b) => 'boarding-pass-${b.ref}-${b.flight.number.replaceAll(' ', '')}.html';

