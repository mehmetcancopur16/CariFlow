#!/usr/bin/env bash
set -euo pipefail

# Keep startup output minimal while preserving warnings/errors.
flutter config --no-analytics >/dev/null 2>&1 || true
flutter run --suppress-analytics --no-pub "$@" 2>&1 | awk '
!/^\[ +\d+ ms\]/ &&
!/^Syncing files to device/ &&
!/^Performing hot reload/ &&
!/^Performing hot restart/ &&
!/^Reloaded [0-9]+ of [0-9]+ libraries/ &&
!/^Restarted application in/ &&
!/^To hot reload changes while running, press "r"/ &&
!/^To hot restart \(and rebuild state\), press "R"/ &&
!/^For a more detailed help message, press "h"/ &&
!/^To detach \(terminate "flutter run" but leave application running\), press "d"/ &&
!/^To clear the screen, press "c"/ &&
!/^To quit \(terminate the application on the device\), press "q"/ &&
!/^A Dart VM Service on / &&
!/^The Flutter DevTools debugger and profiler on /
'
