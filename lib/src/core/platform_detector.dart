import 'package:flutter/foundation.dart';

import '../models/vergate_platform.dart';

/// Maps the running Flutter platform to a [VergatePlatform].
///
/// Web and desktop targets return [VergatePlatform.other], which means
/// no version rules are applied there.
VergatePlatform detectVergatePlatform() {
  if (kIsWeb) return VergatePlatform.other;

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return VergatePlatform.android;
    case TargetPlatform.iOS:
      return VergatePlatform.ios;
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      return VergatePlatform.other;
  }
}
