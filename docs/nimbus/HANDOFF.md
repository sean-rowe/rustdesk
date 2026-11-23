# Nimbus redesign: implementation handoff

This hands the Nimbus redesign of the desktop app to whoever builds the rest of
it. The visual and behavioral reference is `docs/nimbus/demo.html`. Open it in a
browser and click through it. Every control in it works, and this document says
which Flutter file each part belongs to.

Read `AGENTS.md` first. Its rules apply here: minimal diffs, Dart tests in
`flutter/test/*_test.dart`, never run `flutter_rust_bridge_codegen`, new
language keys in sentence case.

## Where things stand

Branch `nimbus-theme` (PR #1) already has:

- The tokens in `flutter/lib/common/theme/nimbus.dart`: `NimbusColors`, `NimbusRadii`,
  `NimbusSpace`, `NimbusType`, `NimbusMotion` and `NimbusShadows`. Use these,
  never raw values.
- Shared widgets in `flutter/lib/desktop/widgets/nimbus/`: `NimbusPressable` (keyboard
  focus and activation), `NimbusSidebarRow`, `NimbusPanel`,
  `NimbusSegmentedControl`, `NimbusIconButton`, `NimbusTitleBar` and
  `NimbusWindowFrame`.
- `TrafficLights` in `flutter/lib/desktop/widgets/traffic_lights.dart`.
- Redesigned screens: the main window (`desktop_tab_page.dart`, `desktop_home_page.dart`,
  `connection_page.dart`, `peer_tab_page.dart`, `peer_card.dart`), Settings
  (`desktop_setting_page.dart`), the connection manager (`server_page.dart`), the remote
  toolbar (`remote_toolbar.dart`) and popup menus (`popup_menu.dart`).
- The theme is always dark. `getThemeModePreference()` returns `ThemeMode.dark`.
- On Linux, windows are real glass. The runner already gives windows an RGBA
  visual when a compositor runs. `nimbusWindowFill()` is translucent there and
  opaque elsewhere. `buildVirtualWindowFrame` draws the corner, edge and shadow.

The rest of this document covers what the demo shows that the branch does not
have yet.

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

## Work items

Each item lists what the demo does, the files to change, and when it is done.

### 1. File transfer (`file_manager_page.dart`, `file_manager_tab_page.dart`)

**In the demo:** Connection > Transfer File, or the folder button on the remote
toolbar.

- The window has two panes side by side, "This Computer" and the remote
  device. Each pane is a `NimbusPanel`.
- The pane header holds the device icon and name, then Up, New Folder and
  Delete icon buttons. Delete is disabled until something is selected.
- A breadcrumb path row sits under the header. Each segment is clickable.
- File rows have a checkbox, an icon, the name and a size. Folders show an item
  count instead of a size. Clicking a folder row opens it, and clicking the
  checkbox selects it. Clicking a file row toggles its selection.
- The footer shows the item count, or "N selected · size", plus a primary Send
  or Receive button.
- A Transfers panel below both panes lists each job with a direction icon, the
  name, a progress bar, a percentage and the size. Finished bars turn
  `NimbusColors.success`. Clear Finished empties them.

**Done when:** the existing transfer logic in `file_model.dart` is unchanged, the
only change is layout and styling, and both panes and the job list match the
demo.

### 2. Recording timer (`remote_toolbar.dart`, `RecordingModel` in `models/model.dart`)

**In the demo:** start recording from the toolbar.

- A pill appears at the top left of the remote canvas: a blinking red dot,
  "REC", the elapsed time as `HH:MM:SS` (updated every second), and a small Stop
  button.
- The record button's tooltip also shows the elapsed time.
- Stopping posts a notification with the total length.

**Done when:** `RecordingModel` records a start `DateTime` when recording starts,
and clears it when recording stops. A widget reads it with a one-second
`Timer.periodic` that is cancelled in `dispose`. Add a widget test that pumps
through the elapsed time.

### 3. View camera (`view_camera_page.dart`, `view_camera_tab_page.dart`)

**In the demo:** the device "⋯" menu > View camera.

- The window opens with a centered spinner and "Opening the camera on NAME…".
- Once the feed shows, a top left pill reads "Live · camera name", and a
  monospace timestamp sits bottom left.
- A floating glass control bar holds: choose camera (a menu with a check on the
  current one), mic toggle (accent when on, crossed-out icon when muted),
  snapshot (a white flash plus a notification) and a red close button.

**Done when:** the existing camera page uses this chrome. The control bar reuses
the remote toolbar's button style.

### 4. Terminal (`terminal_page.dart`, `terminal_tab_page.dart`)

**In the demo:** the terminal window.

- The prompt user and host are in the accent color, the path is dim, and errors
  are in the danger color.
- Text is monospace at 12.5 px with a 1.6 line height.

`nimbus.dart` has no terminal colors yet. Add these to `NimbusColors`, taken
from the design system tokens:

| Token | Value |
| --- | --- |
| `surfaceTerminal` | `Color(0xDB0C0A1A)` |
| `terminalText` | `Color(0xFFD8F5E0)` |
| `terminalGreen` | `Color(0xFF7EE0A4)` |
| `terminalDim` | `Color(0xFF9B93C9)` |

**Done when:** the terminal view gets a theme built from those tokens. Only the
theme changes; the terminal behavior stays as it is.

### 5. TCP tunneling (`port_forward_page.dart`, `port_forward_tab_page.dart`)

**In the demo:**

- One sentence at the top explains what forwarding does.
- A grouped card holds a table with these columns: Local port, Remote host,
  Remote port, Status, and a remove button. Status is a pill reading
  "Listening".
- The last row holds the inputs and an Add button.
- Invalid ports (outside 1 to 65535) or a duplicate local port show an error.

**Done when:** the existing page uses this layout with the Nimbus input and pill
styles.

### 6. Change ID (`changeIdDialog` in `common/widgets/dialog.dart`)

**In the demo:** the "⋯" next to your ID > Change ID.

- The dialog keeps the existing rules and error strings: "Too short, at least 6
  characters.", "The first character must be a letter.", and the allowed
  characters.
- Errors show inline under the field in the danger color. They don't appear as
  a separate message.
- On success the ID on the home panel updates, and a notification confirms it.

**Done when:** the dialog is restyled to the Nimbus dialog: a near-opaque glass
fill, a radius of `NimbusRadii.xl`, and Cancel and OK buttons on the right.

### 7. Log in (`common/widgets/login.dart`)

**In the demo:** Settings > Account > Log In, or the Log In button in Accessible
devices.

- The header has the app icon tile, "Log In to …", and one line about syncing
  the address book.
- Username or email and Password fields, then a full-width primary Log In
  button that shows a spinner while working.
- An "or continue with" divider, then provider buttons in a two-column grid.
  Each button has a small monogram badge and the provider name.
- Clicking a provider switches the dialog to a "Waiting for PROVIDER" state with
  a spinner, a line saying to finish in the browser, and Cancel.

**Done when:**

- Provider buttons come from the server's real login options, through the
  existing `LoginWidgetOP` and `_oidcProviderBranding`. Do not hard-code the
  six providers from the demo. They are only sample data.
- The waiting state reuses the existing `oidc_auth_status.dart` flow.

### 8. Accessible devices (`common/widgets/my_group.dart`, `peer_tab_page.dart`)

**In the demo:**

- Logged out, the tab shows an empty state with a Log In button.
- Logged in, it shows peer cards. Each card has a second line under the name:
  "Yours", or "Shared by NAME".

**Done when:** the logged-out empty state has the Log In button, which opens the
dialog from item 7. Group peers show their owner from the existing group data.

### 9. Remote session overlays (`remote_page.dart`, `remote_toolbar.dart`)

**In the demo:** the remote toolbar's keyboard and display menus.

- **Quality monitor:** a small glass card at the top right of the canvas showing
  label and value rows for Speed, FPS, Delay, Codec and Resolution. Apply this
  style to the existing `QualityMonitor` widget.
- **Block user input:** while active, an amber pill sits at the bottom center of
  the canvas reading "Remote keyboard and mouse are blocked". The menu item
  shows a check.
- **Insert Lock and Ctrl + Alt + Del:** these already send real input. Only the
  menu styling changes. The demo's fake remote lock screen exists only because
  the demo has no real remote computer.

### 10. System tray menu

The demo's tray icon menu shows a header with "Your ID", the ID in large type,
and a status line, then Open, Copy ID, Stop Service (or Start Service),
Settings and Quit.

The real tray is native and built in Rust (`src/tray.rs`), so Flutter cannot
style it. Only change the menu items and their order to match, and only if
that's cheap.

## Open decisions for Sean

Do not build these until Sean decides.

1. **Name.** The demo calls the app "Tether". Should the real app be renamed, or
   was the name only for the demo? Renaming touches packaging, the app ID and
   translations, so it is not a styling change.
2. **One click to connect.** In the demo, one click on a peer card connects.
   Upstream, one click selects and a double click connects (`peer_card.dart`,
   `gestureDetector`). Changing it affects multi-select. Either keep the
   upstream behavior, or make one click connect and move selection to a
   checkbox.
3. **App menu bar.** The demo puts Connection, Edit, View, Session, Window and Help
   in the top bar. Flutter's `PlatformMenuBar` only exports to the macOS menu
   bar, and the Linux build has no global menu. There are three options:
   - Skip the menu bar on Linux.
   - Draw an in-window menu row.
   - Implement the DBus `com.canonical.dbusmenu` export for an XFCE appmenu
     plugin.

## Out of scope for this repo

These are part of the Nimbus desktop, not the app, so they belong in the
Nimbus OS-XFCE project:

- The rest of the demo's top bar: the logo menu (About, Sleep, Restart, Shut
  Down, Lock Screen, Log Out), Wi-Fi, Bluetooth, Sound, Search, Control Center,
  the clock and notification panel, the lock screen and the startup animation.
- The dock.

## How to check the work

1. `cd flutter && flutter analyze`. The only errors should be the known baseline:
   the missing generated FFI bridge, and `file_manager_page.dart:1511`. Nothing
   new.
2. `flutter test test/` passes, including `nimbus_pressable_test.dart` and any new
   tests.
3. Build and run on Linux with picom running with blur turned on. picom's
   default blur method is `none`, and then correct glass looks plain
   translucent. Only one compositor can run at a time, so first stop any
   compositor that is already running:
   - XFCE's built-in one: `xfconf-query -c xfwm4 -p /general/use_compositing -s false`
   - Another picom: `pkill picom`

   Then start picom with blur. `picom --version` tells you which command fits:
   - picom 10 or newer:
     `picom --backend glx --blur-method dual_kawase --blur-strength 5`
   - picom 8.x or 9.x, where `dual_kawase` needs the experimental backends:
     `picom --experimental-backends --backend glx --blur-method dual_kawase --blur-strength 5`

   When you're done, stop this picom (`pkill picom`) and restore the compositor
   you had before. For XFCE's, run the same `xfconf-query` command with
   `-s true`. Check:
   - Window glass blurs the wallpaper.
   - Every new control can be reached with Tab and shows the focus ring.
   - Text never shows through dialogs.
4. Compare each screen side by side with `docs/nimbus/demo.html` at the same
   window size.
