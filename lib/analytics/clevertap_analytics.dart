import 'dart:developer' as developer;

import 'package:clevertap_plugin/clevertap_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../state.dart';

class CleverTapAnalytics {
  CleverTapAnalytics._();

  static final CleverTapAnalytics instance = CleverTapAnalytics._();

  bool _initialized = false;
  int _lastTapTimestamp = 0;
  Offset? _lastTapPosition;

  Future<void> init(AppState state) async {
    if (_initialized) return;
    _initialized = true;

    if (kDebugMode) {
      await CleverTapPlugin.setDebugLevel(3);
    }

    await _identifyUser(state);
    await trackEvent('app_started', {
      'platform': defaultTargetPlatform.name,
      'onboarded': state.onboarded,
    });
  }

  Future<void> identifyUpdatedUser(AppState state) async {
    if (!_initialized) return;
    await _identifyUser(state);
  }

  Future<void> trackScreen(
    String screenName, {
    Map<String, dynamic>? props,
  }) async {
    await trackEvent('screen_view', {'screen_name': screenName, ...?props});
  }

  Future<void> trackTap({
    required String source,
    required String screen,
    Offset? globalPosition,
    Map<String, dynamic>? props,
  }) async {
    await trackEvent('user_click', {
      'source': source,
      'screen': screen,
      if (globalPosition != null) 'x': globalPosition.dx.round(),
      if (globalPosition != null) 'y': globalPosition.dy.round(),
      ...?props,
    });
  }

  Future<void> trackEvent(String name, [Map<String, dynamic>? props]) async {
    final clean = _sanitizeProps(props);
    developer.log('CleverTap event => $name $clean', name: 'analytics');
    try {
      await CleverTapPlugin.recordEvent(name, clean);
    } catch (e, st) {
      developer.log(
        'CleverTap recordEvent failed: $e',
        name: 'analytics',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> captureGlobalTap(
    BuildContext context,
    PointerUpEvent event,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final pos = event.position;

    // Avoid duplicate tap events from the same pointer release.
    if (_lastTapPosition != null) {
      final isSameSpot = (pos - _lastTapPosition!).distance <= 1.0;
      final isImmediate = now - _lastTapTimestamp <= 70;
      if (isSameSpot && isImmediate) return;
    }

    _lastTapTimestamp = now;
    _lastTapPosition = pos;

    await trackTap(
      source: 'global_pointer_up',
      screen: _screenName(context),
      globalPosition: pos,
      props: {'pointer_kind': event.kind.name},
    );
  }

  Future<void> _identifyUser(AppState state) async {
    final profile = {
      'Identity': state.profile.memberNo,
      'Name': state.profile.name,
      'Email': state.profile.email,
      'Phone': state.profile.phone,
      'Tier': state.profile.tier,
      'HomeAirport': state.profile.home,
    };
    try {
      await CleverTapPlugin.onUserLogin(profile);
      await CleverTapPlugin.profileSet(profile);
    } catch (e, st) {
      developer.log(
        'CleverTap profile setup failed: $e',
        name: 'analytics',
        error: e,
        stackTrace: st,
      );
    }
  }

  String _screenName(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    if (route != null && route.isNotEmpty) return route;
    return 'tab_${context.app.tab.value}';
  }

  Map<String, dynamic> _sanitizeProps(Map<String, dynamic>? props) {
    if (props == null) return {};
    final out = <String, dynamic>{};
    props.forEach((key, value) {
      if (value == null) return;
      if (value is num || value is bool || value is String) {
        out[key] = value;
        return;
      }
      out[key] = value.toString();
    });
    return out;
  }
}
