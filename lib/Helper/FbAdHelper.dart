import 'dart:io';

import 'package:news/Helper/String.dart';

class FbAdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return fbBannerId;
    } else if (Platform.isIOS) {
      return iosFbBannerId;
    }
    throw new UnsupportedError("Unsupported platform");
  }

  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return fbNativeUnitId;
    } else if (Platform.isIOS) {
      return iosFbNativeUnitId;
    }
    throw new UnsupportedError("Unsupported platform");
  }

  static String get interstitialAdUnitId {
    if (Platform.isIOS) {
      return iosFbInterstitialId;
    } else if (Platform.isAndroid) {
      return fbInterstitialId;
    }
    throw new UnsupportedError("Unsupported platform");
  }

  static String get rewardAdUnitId {
    if (Platform.isIOS) {
      return iosFbRewardedVideoId;
    } else if (Platform.isAndroid) {
      return fbRewardedVideoId;
    }
    throw new UnsupportedError("Unsupported platform");
  }
}
