import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:rxdart/rxdart.dart';

/// Manage user notifications for the app.  User notifications are prioritized
/// and published, e.g. for display via a banner notification on the home screen.
class AppNotifications {
  static final AppNotifications _singleton = AppNotifications._internal();

  AppNotifications._internal() {
    debugPrint("constructed app notifications singleton");

    var api = OrchidAPI();

    // Listen to all notification data sources and pass the changes to the evaluation method.
    Rx.combineLatest2(
            api.networkConnectivity, api.syncStatus, _evaluateNotificationSources)
        .listen((AppNotificationType notificationType) {
      notification.add(notificationType);
    });
  }

  factory AppNotifications() {
    return _singleton;
  }

  /// Publish the highest priority notification at the current time or
  /// AppNotificationType.None if there are no notifications pending.
  BehaviorSubject<AppNotificationType> notification =
      BehaviorSubject.seeded(AppNotificationType.None);

  /// This method is called upon changes to any source of notification
  AppNotificationType _evaluateNotificationSources(
      NetworkConnectivityType connectivity, OrchidSyncStatus syncStatus) {
    // Prioritize connectivity
    if (connectivity == NetworkConnectivityType.NoConnectivity) {
      return AppNotificationType.InternetRequired;
    }

    if (syncStatus.state == OrchidSyncState.Required) {
      return AppNotificationType.SyncRequired;
    }

    // No notifications
    return AppNotificationType.None;
  }
}

/// Type of notifications the app may display.
enum AppNotificationType { None, InternetRequired, SyncRequired }

