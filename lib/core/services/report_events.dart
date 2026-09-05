import 'package:flutter/foundation.dart';

/// Fires whenever a report is submitted successfully, so any already-mounted
/// screen showing incidents (map/home) can refetch in place instead of
/// requiring the user to leave and reopen the app to see it.
class ReportEvents {
  ReportEvents._();

  static final ValueNotifier<int> submitted = ValueNotifier<int>(0);

  static void notifySubmitted() {
    submitted.value++;
  }
}
