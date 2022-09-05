import 'dart:io';

import 'package:news/Helper/String.dart';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return  goBannerId;
    } else if (Platform.isIOS) {
      return iosGoBannerId;
    }
    throw new UnsupportedError("Unsupported platform");
  }

  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return goNativeUnitId;
    } else if (Platform.isIOS) {
      return iosGoNativeUnitId;
    }
    throw new UnsupportedError("Unsupported platform");
  }

  static String get interstitialAdUnitId {
    if (Platform.isIOS) {
      return iosGoNativeUnitId;
    } else if (Platform.isAndroid) {
      return goInterstitialId;
    }
    throw new UnsupportedError("Unsupported platform");
  }

  static String get rewardAdUnitId {
    if (Platform.isIOS) {
      return iosGoRewardedVideoId;
    } else if (Platform.isAndroid) {
      return goRewardedVideoId;
    }
    throw new UnsupportedError("Unsupported platform");
  }
}
