import 'dart:math';
import 'package:orchid/api/orchid_log.dart';

/// Search over an index to find a series of values which may appear at
/// irregular intervals.
/// This class implements an exponential windowed binary search where the
/// "expected" interval hint is used as the initial size for the window
/// such that when the series tends toward being regularly spaced there is no
/// penalty over directly addressing it.
/// The values of type T are expected to be sorted increasing with index.
class SeriesBinarySearch<T> {
  /// The hard limits (inclusive) and start index
  final int minIndex, maxIndex, startIndex;

  /// The best case or average index interval between series items.
  final int seriesExpectedInterval;

  /// The value getter
  final Future<T> Function(int index) valueForIndex;

  // Working values
  int _currentIndex; // start for next search
  T? _currentValue;

  SeriesBinarySearch({
    required this.minIndex,
    required this.maxIndex,
    required this.startIndex,
    required this.valueForIndex,
    required this.seriesExpectedInterval,
  }) : this._currentIndex = startIndex;

  Future<T?> findNext(Comparable<T> comparable) async {
    // Ensure that we have evaluated the current index.
    T value = _currentValue ?? await valueForIndex(_currentIndex);
    _currentValue = value;
    var comparison = comparable.compareTo(value);
    if (comparison == 0) {
      return value; // found it, done!
    }

    //
    // Find a window that bounds the current search
    //
    final findWindowForward = comparison > 0;
    // log("findFoward = $findWindowForward");
    int winMin = _currentIndex;
    int winMax = _currentIndex;
    var winSteps = 0;
    var stepCount = 0; // sanity check
    do {
      final winStepSize = seriesExpectedInterval * (pow(2, winSteps)).toInt();
      if (findWindowForward) {
        if (_currentIndex >= maxIndex) {
          // log("Ran out of window room: window forward");
          return null; // Can't move the window forward
        }
        winMax = min(_currentIndex + winStepSize, maxIndex);
        _currentIndex = winMax;
      } else {
        if (_currentIndex <= minIndex) {
          // log("Ran out of window room: window backward");
          return null; // Can't move the window back
        }
        winMin = max(_currentIndex - winStepSize, minIndex);
        _currentIndex = winMin;
      }
      // log("win: step size = $winStepSize, winMin = $winMin, winMax = $winMax");

      // Evaluate
      try {
        value = await valueForIndex(_currentIndex);
      } catch (err) {
        log("err = $err");
        return null;
      }
      comparison = comparable.compareTo(value);
      if (comparison == 0) {
        return value; // found it, done!
      }

      // Step (double) the window size
      winSteps += 1;
      if (stepCount++ > 99) {
        throw Exception();
      }
    } while ((!findWindowForward && comparison < 0) ||
        (findWindowForward && comparison > 0));

    //
    // Search the window
    //
    log("binary search proceeding with win steps = $winSteps");
    stepCount = 0; // sanity check
    do {
      final findForward = comparison > 0; // (desired, eval)
      // step the binary search
      final step = findForward
          ? ((winMax - _currentIndex) ~/ 2)
          : -((_currentIndex - winMin) ~/ 2);
      if (step == 0) {
        // Nothing more to search, not found.
        // log("binary search step is zero, ending");
        return null;
      }
      _currentIndex += step;

      // evaluate
      try {
        value = await valueForIndex(_currentIndex);
      } catch (err) {
        log("err = $err");
        return null;
      }
      comparison = comparable.compareTo(value);
      if (comparison == 0) {
        return value; // found it, done!
      }

      // update window bounds
      if (comparison > 0) {
        winMin = _currentIndex;
      } else {
        winMax = _currentIndex;
      }

      if (stepCount++ > 99) {
        throw Exception();
      }
    } while (true);
  }
}

/// Fuzzy date comparison.
class DateTimeComparable extends Comparable<DateTime> {
  final DateTime date;
  final Duration within;

  DateTimeComparable({required this.date, required this.within});

  @override
  int compareTo(DateTime other) {
    final diff = date.difference(other);
    if (diff.abs() <= within) {
      return 0;
    } else {
      // return -1 if 'this' is ordered before 'other'
      return diff.isNegative ? -1 : 1;
    }
  }

  @override
  String toString() {
    return 'DateTimeComparable{date: $date, within: $within}';
  }
}

