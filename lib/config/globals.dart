import 'package:flutter/material.dart';

/// Global NavigatorKey untuk navigasi dari mana saja (termasuk provider/service).
/// Dipasang di `ShadApp` di main.dart.
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();
