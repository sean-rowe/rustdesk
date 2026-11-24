# Nimbus redesign: handoff

This hands the Nimbus redesign of the RustDesk desktop app to whoever finishes
it. Branch `nimbus-theme`, PR #1 against `master` of `sean-rowe/rustdesk`.

The visual and behavioral reference is `docs/nimbus/demo.html`. Open it in a
browser and click through it; every control works. It is a single 380 KB file
with the wallpaper embedded as a data URI, so read it by searching for what you
need instead of reading it whole. The demo calls the app "Tether" (see Open
decisions).

Read `AGENTS.md` first. Its rules apply here: minimal diffs, prefer additive
changes over reshaping existing code, Dart tests in `flutter/test/*_test.dart`,
never run `flutter_rust_bridge_codegen`, new language keys in sentence case.

## Where things stand

Every screen the demo shows is built. All 28 CodeRabbit review threads on PR #1
are resolved, and the last review's 7 findings were fixed in `b7d3294`.

| Area | Files | Commit |
| --- | --- | --- |
| Tokens: `NimbusColors`, `NimbusRadii`, `NimbusSpace`, `NimbusType`, `NimbusMotion`, `NimbusShadows` | `flutter/lib/common/theme/nimbus.dart` | `306a7f4` |
| Shared widgets: `NimbusPressable`, `NimbusSidebarRow`, `NimbusPanel`, `NimbusSegmentedControl`, `NimbusIconButton`, `NimbusTitleBar`, `NimbusWindowFrame` | `flutter/lib/desktop/widgets/nimbus/` | `306a7f4`, `421c06a` |
| Traffic lights | `flutter/lib/desktop/widgets/traffic_lights.dart` | `306a7f4` |
| Main window, sidebar, peer cards, Settings, connection manager, remote toolbar, popup menus | `desktop_tab_page.dart`, `desktop_home_page.dart`, `connection_page.dart`, `peer_tab_page.dart`, `peer_card.dart`, `desktop_setting_page.dart`, `server_page.dart`, `remote_toolbar.dart`, `popup_menu.dart` | `306a7f4`, `421c06a` |
| Terminal theme | `terminal_page.dart`, `widgets/nimbus/nimbus_terminal.dart` | `5d6b730` |
| Change ID: inline errors, notification on success | `common/widgets/dialog.dart` | `2640bab` |
| TCP tunneling card table and port validation | `port_forward_page.dart` | `a5818bf` |
| Remote overlays: quality monitor card, input-blocked pill | `remote_page.dart`, `common/widgets/overlay.dart`, `common/widgets/toolbar.dart` | `7bac4b2` |
| File transfer panes and Transfers panel | `file_manager_page.dart` | `7cc6641` |
| Log in dialog with providers, Accessible devices empty state and owner labels | `common/widgets/login.dart`, `common/widgets/my_group.dart` | `d0b830c` |
| Recording pill with HH:MM:SS timer | `widgets/nimbus/recording_pill.dart`, `RecordingModel` | `2050fb2` |
| View camera chrome | `view_camera_page.dart`, `widgets/nimbus/camera_overlays.dart` | `8d594c7` |
| Tray menu header and Copy ID | `src/tray.rs` | `81ce7b8`, `b7d3294` |
| Linux blur hint to the compositor | Linux runner | `fd9e1ae` |

The theme is always dark on desktop. On Linux, windows are real glass when a
compositor runs: `nimbusWindowFill()` is translucent there and opaque elsewhere.

## What has not been verified

The branch was built in a cloud sandbox without RustDesk's native
dependencies. So:

- **The native code has never been compiled.** That covers `src/tray.rs`
  (`81ce7b8`, `b7d3294`), the new translation keys in `src/lang/*.rs`, and
  the Linux runner change in `my_application.cc` (`fd9e1ae`). Build first.
- **Most Flutter tests have never run.** 33 of the 42 test files, including
  every Nimbus test except `nimbus_pressable_test.dart`, import app code that
  needs `flutter/lib/generated_bridge.dart`. That file is gitignored and made
  by CI codegen, so in the sandbox those files fail to compile. The other
  tests pass. The branch adds no FFI functions, so an existing bridge from
  `master` works.
- **The app has never been run.** Every screen was checked only by
  `flutter analyze` and the demo, never on a real desktop.
- `flutter analyze` is clean apart from the known baseline: the missing
  generated FFI bridge, and the `int` to `double` assignment in
  `file_manager_page.dart` (line 1510 on `master`, about 1564 on this branch).

## Work items

Do these in order.

### 1. Build and run on Linux

Build the app, which also produces `flutter/lib/generated_bridge.dart`, and fix
whatever the compiler finds. Do not run `flutter_rust_bridge_codegen` yourself
(see `AGENTS.md`); use the bridge your normal build or CI already gives you.
Then run `flutter test test/` and fix any failures in the Nimbus tests. Last,
run the app and walk every screen against the demo at the same window size,
using "How to check the work" below. Fix differences in the Flutter code, not
the demo, unless the demo is wrong.

**Done when:** the app builds and runs on Linux, `flutter test test/` passes,
and the tray's Copy ID puts the ID on the clipboard and it is still there after
the tray menu closes, with no clipboard manager running.

### 2. Bring the main window up to the latest demo

Commit `a85da0f` tightened the demo to match the Nimbus design system's
component sources. The Flutter code still follows the earlier demo. Close
these gaps:

- **Peer cards** (`peer_card.dart`): a glass card (`surfaceRaise` fill,
  `divider` hairline, `NimbusRadii.lg`) laid out as a row: a 40 px gradient
  icon tile (`NimbusRadii.md`, icon shadow), then the name at 14.5 px
  semibold, then a line with the status dot and the ID at 12.5 px in
  `textSecondary` with tabular figures. The options button sits at the right.
  No gradient header and no opaque fill. List mode is the same row at 28 px
  with no card fill.
- **Title bar** (`NimbusTitleBar`): the app icon (a 20 px gradient tile) and
  the title sit just right of the traffic lights. The Home and Settings
  switch stays centered.
- **Sidebar rows** (`NimbusSidebarRow`): 6 px by 8 px padding, `NimbusRadii.sm`.
  Icons take the row's text color instead of the accent.
- **Connect bar**: the field and buttons are 35 px tall, and the field text is
  14.5 px.
- **Popup menus**: 6 px padding, items with `NimbusRadii.sm`, separators inset
  8 px, and shortcut text at 70 % opacity.

**Done when:** the main window matches the demo side by side, and the existing
peer card tests (`peer_card_menu_semantics_test.dart`) still pass.

### 3. Ask for a final review

CodeRabbit has paused automatic reviews on this branch. After pushing, comment
`@coderabbitai review` on PR #1, then verify each finding against the code
before fixing it.

## Open decisions for Sean

Do not build these until Sean decides.

1. **Name.** The demo calls the app "Tether". Should the real app be renamed,
   or was the name only for the demo? Renaming touches packaging, the app ID and
   translations, so it is not a styling change.
2. **One click to connect.** In the demo, one click on a peer card connects.
   The branch keeps upstream behavior: one click selects and a double click
   connects (`peer_card.dart`). Changing it affects multi-select. Either keep
   upstream behavior, or make one click connect and move selection to a
   checkbox.
3. **App menu bar.** The demo puts Connection, Edit, View, Session, Window and
   Help in the top bar. Flutter's `PlatformMenuBar` only exports to the macOS
   menu bar, and the Linux build has no global menu. There are three options:
   - Skip the menu bar on Linux.
   - Draw an in-window menu row.
   - Implement the DBus `com.canonical.dbusmenu` export for an XFCE appmenu
     plugin.

## Ground rules for every screen

- Glass goes over the wallpaper. Window fill comes from `nimbusWindowFill()`. Menus
  use `NimbusColors.menuOpaque`, and dialogs use an almost opaque fill so the
  text behind them never shows through.
- Use one accent, `NimbusColors.accent`. Use the danger color only for
  destructive actions and for recording.
- Buttons and menu items use Title Case. Body text and tooltips use sentence case.
- No emoji. Numbers that change (IDs, timers, sizes, ports) use tabular figures:
  `FontFeature.tabularFigures()`.
- Icons are line icons, about 1.7 to 2 px stroke at 16 to 18 px size.
- Every new control is keyboard reachable through `NimbusPressable`, with the 2 px
  accent focus ring.
- Respect reduced motion. Animations use `NimbusMotion` durations.

## Out of scope for this repo

These are part of the Nimbus desktop, not the app, so they belong in the
Nimbus OS-XFCE project:

- The rest of the demo's top bar: the logo menu (About, Sleep, Restart, Shut
  Down, Lock Screen, Log Out), Wi-Fi, Bluetooth, Sound, Search, Control Center,
  the clock and notification panel, the lock screen and the startup animation.
- The dock.

## How to check the work

1. `cd flutter && flutter analyze`. The only errors should be the known baseline
   listed above. Nothing new.
2. `flutter test test/` passes, including the Nimbus tests:
   `nimbus_pressable_test.dart`, `nimbus_terminal_theme_test.dart`,
   `nimbus_login_group_test.dart`, `file_transfer_nimbus_test.dart`,
   `recording_timer_test.dart`, `camera_overlays_test.dart`,
   `remote_overlays_test.dart`, `port_forward_add_test.dart`,
   `change_id_dialog_test.dart` and `popup_menu_hover_test.dart`.
3. Build and run on Linux with picom running with blur turned on. picom's
   default blur method is `none`, and then correct glass looks plain
   translucent. Only one compositor can run at a time, so first stop any
   compositor that is already running:
   - XFCE's built-in one: `xfconf-query -c xfwm4 -p /general/use_compositing -s false`
   - Another picom: `pkill picom`

   Then start picom with blur. This needs picom 9 or newer, because picom 8
   has no `dual_kawase` blur; upgrade if `picom --version` reports 8.x.
   `--config /dev/null` keeps your own picom config, such as a
   `blur-background-exclude` rule, out of the check.
   - picom 10 or newer:
     `picom --config /dev/null --backend glx --blur-method dual_kawase --blur-strength 5`
   - picom 9.x, where `dual_kawase` needs the experimental backends:
     `picom --config /dev/null --experimental-backends --backend glx --blur-method dual_kawase --blur-strength 5`

   When you're done, stop this picom (`pkill picom`) and restore the compositor
   you had before. For XFCE's, run the same `xfconf-query` command with
   `-s true`. Check:
   - Window glass blurs the wallpaper.
   - Every new control can be reached with Tab and shows the focus ring.
   - Text never shows through dialogs.
4. Compare each screen side by side with `docs/nimbus/demo.html` at the same
   window size.
