
class ReleaseVersion {
  final int? version;

  ReleaseVersion(this.version);

  ReleaseVersion.resetFirstLaunch() : this.version = null;

  /// This is represents a first launch of the app since the V1 UI.
  bool get isFirstLaunch {
    return version == null;
  }

  // Compare versions or return true if first launch.
  bool isOlderThan(ReleaseVersion other) {
    if (version == null || other.version == null) {
      return true;
    }
    return version! < other.version!;
  }

  @override
  String toString() {
    return 'ReleaseVersion{version: $version}';
  }
}
