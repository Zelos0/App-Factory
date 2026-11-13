/// Offizielle Test-Anzeigen-IDs von Google. Die einzigen IDs, die im
/// Quelltext stehen dürfen — tool/check_ad_ids.dart erlaubt genau dieses
/// Präfix und bricht bei jedem anderen.
///
/// Echte IDs kommen ausschließlich über --dart-define in den Release-Build.
class TestAdUnits {
  const TestAdUnits._();

  static const String androidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String iosBanner = 'ca-app-pub-3940256099942544/2934735716';

  static const String androidInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String iosInterstitial =
      'ca-app-pub-3940256099942544/4411468910';

  /// Liefert die ID für den laufenden Build. In Debug-Builds immer die
  /// Test-ID — auch dann, wenn über --dart-define eine echte übergeben wurde.
  static String bannerFor({required bool isAndroid, required bool isRelease}) {
    if (!isRelease) {
      return isAndroid ? androidBanner : iosBanner;
    }
    const String fromDefine = String.fromEnvironment('AD_UNIT_BANNER');
    if (fromDefine.isEmpty) {
      return isAndroid ? androidBanner : iosBanner;
    }
    return fromDefine;
  }
}
