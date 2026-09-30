## 0.1.0

Initial release.

* Force update, soft update (banner or dialog) and maintenance mode.
* Per-platform rules for Android and iOS, with release notes.
* Data sources: `JsonUrlSource`, `CallbackSource`, `ItunesLookupSource`
  and `FallbackSource`. Implement `VergateSource` for your own.
* "Remind me later" and "Skip this version", saved between launches.
* Maintenance window with live countdown and automatic re-check.
* Automatic re-check when the app returns to the foreground.
* Fail-open behavior: errors never block the user.
* `VergateTheme`, `VergateStrings` and `stringsBuilder` for full customization.
* Custom builders to replace any built-in screen.
* `debugOverrideStatus` to preview every state in debug mode.