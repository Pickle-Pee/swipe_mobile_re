import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/events/navigation_event.dart';

final navigationEventsProvider = Provider<NavigationEvents>((ref) {
  return NavigationEvents();
});

class NavigationEvents {
  final _controller = StreamController<NavigationEvent>.broadcast();

  Stream<NavigationEvent> get stream => _controller.stream;

  void navigate(String route) {
    _controller.add(NavigationEvent(route));
  }
}
