import 'dart:collection';
import 'package:orchid/pages/common/name_value_setting.dart';

/// Support for a dynamic list of name-value pairs as developer settings.
/// A list of "well-known" developer settings is provided as defaults with optional
/// labels and restricted values, however arbitrary name-value settings may be
/// returned by the API and will be presented in the UI using their name as the label.
class DeveloperSettings {

  /// The default list of settings to display.
  static List<NameValueSetting> defaults = [
    // @formatter:off
    NameValueSetting(label: "Foo", name: "foo"),
    NameValueSetting(label: "Bar", name: "bar", initialValue: "someValue"),
    NameValueSetting(label: "Baz", name: "baz", options: ["one", "two", "three"], initialValue: "one")
    // @formatter:on
  ];

  /// Parse a map of name-value pairs and return a list of NameValueSettings,
  /// annotating the metadata for any recognized names from the defaults list.
  /// All items from [defaults] will be returned, in order, first followed by
  /// any additional pairs from the supplied map.
  static List<NameValueSetting> fromMap(Map<String, String> map, {
    Function({String name, String value}) onChanged}) {
    // Default settings by name
    Map<String, NameValueSetting> defaultSettings = Map.fromIterable(defaults,
        key: (item) => item.name, value: (item) => item);

    // Map settings by name
    LinkedHashMap<String, NameValueSetting> mapSettings =
    LinkedHashMap.fromIterable(
        map.entries.map((MapEntry<String, String> entry) {
          var setting = defaultSettings[entry.key];
          return NameValueSetting(
            label: setting?.label,
            options: setting?.options,
            name: entry.key,
            initialValue: entry.value,
            onChanged: onChanged,
          );
        }),
        key: (item) => item.name, value: (item) => item);

    // The merged result list, ordered first by defaults order and secondarily by map order
    Iterable<NameValueSetting> knownSettings = defaults.map((setting) =>
      mapSettings[setting.name] ?? defaultSettings[setting.name].cloneWith(onChanged));

    Iterable<NameValueSetting> unknownSettings = mapSettings.entries
        .where((setting) => !defaultSettings.containsKey(setting.key))
        .map((entry) => entry.value);

    return knownSettings.followedBy(unknownSettings).toList();
  }
}

