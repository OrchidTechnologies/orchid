import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rxdart/rxdart.dart';
import 'package:connectivity/connectivity.dart';

/// Manage user notifications for the app.  User notifications are prioritized
/// and published, e.g. for display via a banner notification on the home screen.
class AppNotifications {
  static final AppNotifications _singleton = new AppNotifications._internal();

  AppNotifications._internal() {
    debugPrint("constructed app notifications singleton");

    // Listen for connectivity changes.
    Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult connectivity) {
      _connectivity.add(connectivity);
    });

    // Listen to all notification data sources and pass the changes to the evaluation method.
    Observable.combineLatest2(
            _connectivity, _syncRequired, _evaluateNotificationSources)
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

  /// Internal observable for connectivity
  BehaviorSubject<ConnectivityResult> _connectivity =
      BehaviorSubject.seeded(ConnectivityResult.mobile);

  /// Internal observable for sync issues
  BehaviorSubject<bool> _syncRequired = BehaviorSubject.seeded(false);

  /// This method is called upon changes to any source of notification
  AppNotificationType _evaluateNotificationSources(
      ConnectivityResult connectivity, bool syncRequired) {
    //debugPrint("Evaluate notification sources, connectivity: $connectivity, syncRequired: $syncRequired");
    // Prioritize connectivity
    if (connectivity == ConnectivityResult.none) {
      return AppNotificationType.InternetRequired;
    }

    if (syncRequired) {
      return AppNotificationType.SyncRequired;
    }

    // No notifications
    return AppNotificationType.None;
  }

  /// Unused. Currently these live for the lifetime of the app.
  void dispose() {
    _syncRequired.close();
    _connectivity.close();
  }
}

/// Type of notifications the app may display.
enum AppNotificationType { None, InternetRequired, SyncRequired }
