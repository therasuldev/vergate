import 'package:flutter/foundation.dart';

import '../models/vergate_platform.dart';

/// Maps the running Flutter platform to a [VergatePlatform].
///
/// Web and desktop targets return [VergatePlatform.other], which means
/// no version rules are applied there.
VergatePlatform detectVergatePlatform() {
  if (kIsWeb) return .other;

  switch (defaultTargetPlatform) {
    case .android:
      return .android;
    case .iOS:
      return .ios;
    case .fuchsia:
    case .linux:
    case .macOS:
    case .windows:
      return .other;
  }
}
