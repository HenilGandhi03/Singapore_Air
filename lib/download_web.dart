// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<bool> downloadTextFile(String name, String content, String mime) async {
  final blob = html.Blob([content], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final a = html.AnchorElement(href: url)..download = name;
  html.document.body?.append(a);
  a.click();
  a.remove();
  html.Url.revokeObjectUrl(url);
  return true;
}
