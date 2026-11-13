//! Display sizes on X11, read and changed with RandR requests.
//!
//! A client can ask for any size, not only the modes a monitor lists: the live X screen becomes
//! that size and every running app stays open and re-lays out, the way an RDP session to a
//! logged-in desktop does. The monitor keeps its native mode and shows the screen scaled to fit
//! (stretched when the aspect ratios differ), other monitors are switched off for the session,
//! and asking for the original size again puts the original layout and window positions back.
//!
//! Only the "current" RandR queries are used. GetScreenResources, and the xrandr tool, force a
//! re-detection of every output, which on NVIDIA stalls the X server and the compositor.

use base::message_proto::Resolution;
use hbb_common::{anyhow::anyhow, bail, log, ResultType};
use std::{sync::Mutex, thread, time::Duration};
use x11rb::{
    connection::Connection,
    protocol::{
        randr::{self, ConnectionExt as _},
        render,
        xproto::{self, ConnectionExt as _},
    },
    rust_connection::RustConnection,
    CURRENT_TIME, NONE,
};

/// One unit in RandR's 16.16 fixed-point numbers.
const FIXED_ONE: f64 = 65536.0;

/// Filter the monitor uses to scale the screen while a size is fitted.
const SCALE_FILTER: &[u8] = b"bilinear";

/// How long the window manager gets to re-lay out windows after the original layout is back,
/// before their saved positions are applied over its own clamping.
const WINDOW_RESTORE_DELAY: Duration = Duration::from_millis(1000);

const NET_CLIENT_LIST: &[u8] = b"_NET_CLIENT_LIST";
const NET_MOVERESIZE_WINDOW: &[u8] = b"_NET_MOVERESIZE_WINDOW";
const NET_WM_STATE: &[u8] = b"_NET_WM_STATE";

/// _NET_WM_STATE values whose geometry the window manager owns; their saved size is not reapplied.
const WM_MANAGED_STATES: [&[u8]; 3] = [
    b"_NET_WM_STATE_FULLSCREEN",
    b"_NET_WM_STATE_MAXIMIZED_VERT",
    b"_NET_WM_STATE_MAXIMIZED_HORZ",
];

/// _NET_MOVERESIZE_WINDOW flags: StaticGravity (the client window's own position), x, y, width
/// and height all present, sent by a pager-like tool (EWMH source indication 2).
const STATIC_GRAVITY: u32 = 10;
const MOVERESIZE_ALL_FIELDS: u32 = 0b1111 << 8;
const SOURCE_PAGER: u32 = 2 << 12;
const MOVERESIZE_FLAGS: u32 = STATIC_GRAVITY | MOVERESIZE_ALL_FIELDS | SOURCE_PAGER;

/// A CRTC exactly as it was before the session changed anything.
#[derive(Clone, Debug)]
struct CrtcState {
    crtc: randr::Crtc,
    x: i16,
    y: i16,
    mode: randr::Mode,
    rotation: randr::Rotation,
    outputs: Vec<randr::Output>,
    transform: render::Transform,
    filter_name: Vec<u8>,
    filter_params: Vec<render::Fixed>,
}

/// The screen size and every CRTC, enough to put the display back exactly.
#[derive(Clone, Debug)]
struct ScreenLayout {
    width: u16,
    height: u16,
    mm_width: u32,
    mm_height: u32,
    config_timestamp: xproto::Timestamp,
    crtcs: Vec<CrtcState>,
}

/// Where a top-level client window was, in root coordinates of the client window itself.
#[derive(Clone, Debug)]
struct WindowPlacement {
    window: xproto::Window,
    x: i16,
    y: i16,
    width: u16,
    height: u16,
}

/// What a running fit replaced: the monitor it fits, that monitor's size, the layout and the
/// window positions from before the first change.
struct FitSession {
    monitor: String,
    original: (u16, u16),
    layout: ScreenLayout,
    windows: Vec<WindowPlacement>,
}

static FIT_SESSION: Mutex<Option<FitSession>> = Mutex::new(None);

/// Converts a number to RandR's 16.16 fixed point.
fn to_fixed(value: f64) -> render::Fixed {
    (value * FIXED_ONE).round() as render::Fixed
}

/// The CRTC transform that shows a `target`-sized area of the screen on a monitor whose mode is
/// `native`, scaling each axis on its own so the area fills the monitor.
fn scale_transform(native: (u16, u16), target: (u16, u16)) -> render::Transform {
    let scale_x = f64::from(target.0) / f64::from(native.0);
    let scale_y = f64::from(target.1) / f64::from(native.1);

    render::Transform {
        matrix11: to_fixed(scale_x),
        matrix12: 0,
        matrix13: 0,
        matrix21: 0,
        matrix22: to_fixed(scale_y),
        matrix23: 0,
        matrix31: 0,
        matrix32: 0,
        matrix33: to_fixed(1.0),
    }
}

/// The physical size for `pixels`, keeping the density of `ref_pixels` over `ref_mm`, so apps
/// keep the same DPI while the screen is resized.
fn scaled_millimeters(pixels: u16, ref_pixels: u16, ref_mm: u32) -> u32 {
    if ref_pixels == 0 {
        return 0;
    }

    ((f64::from(pixels) * f64::from(ref_mm)) / f64::from(ref_pixels)).round() as u32
}

/// The smallest size that contains both `a` and `b`; the screen must hold every CRTC at every
/// step of a change.
fn covering_size(a: (u16, u16), b: (u16, u16)) -> (u16, u16) {
    (a.0.max(b.0), a.1.max(b.1))
}

/// Converts a requested dimension, refusing sizes X cannot describe.
fn to_dimension(value: usize) -> ResultType<u16> {
    match u16::try_from(value) {
        Ok(0) | Err(_) => bail!("Display dimension {} is out of range", value),
        Ok(dimension) => Ok(dimension),
    }
}

/// Opens a connection to the display in `DISPLAY` and returns it with its root window.
fn connect() -> ResultType<(RustConnection, xproto::Window, usize)> {
    let (conn, screen_num) = RustConnection::connect(None)?;
    let root = conn.setup().roots[screen_num].root;

    Ok((conn, root, screen_num))
}

/// Finds the RandR monitor named `name` (the name RustDesk shows for a display).
fn find_monitor(
    conn: &RustConnection,
    root: xproto::Window,
    name: &str,
) -> ResultType<randr::MonitorInfo> {
    let monitors = conn.randr_get_monitors(root, true)?.reply()?.monitors;

    for monitor in monitors {
        let monitor_name = conn.get_atom_name(monitor.name)?.reply()?.name;

        if monitor_name == name.as_bytes() {
            return Ok(monitor);
        }
    }

    bail!("No X11 monitor named '{}'", name)
}

/// Reads a CRTC's placement and transform.
fn read_crtc(
    conn: &RustConnection,
    crtc: randr::Crtc,
    config_timestamp: xproto::Timestamp,
) -> ResultType<CrtcState> {
    let info = conn.randr_get_crtc_info(crtc, config_timestamp)?.reply()?;
    let transform = conn.randr_get_crtc_transform(crtc)?.reply()?;

    Ok(CrtcState {
        crtc,
        x: info.x,
        y: info.y,
        mode: info.mode,
        rotation: info.rotation,
        outputs: info.outputs,
        transform: transform.current_transform,
        filter_name: transform.current_filter_name,
        filter_params: transform.current_params,
    })
}

/// Reads the screen size and every CRTC of screen `screen_num`.
fn read_layout(
    conn: &RustConnection,
    root: xproto::Window,
    screen_num: usize,
) -> ResultType<(ScreenLayout, randr::GetScreenResourcesCurrentReply)> {
    let resources = conn.randr_get_screen_resources_current(root)?.reply()?;
    let screen = &conn.setup().roots[screen_num];
    let geometry = conn.get_geometry(root)?.reply()?;
    let mut crtcs = Vec::with_capacity(resources.crtcs.len());

    for crtc in &resources.crtcs {
        crtcs.push(read_crtc(conn, *crtc, resources.config_timestamp)?);
    }

    let layout = ScreenLayout {
        width: geometry.width,
        height: geometry.height,
        mm_width: screen.width_in_millimeters.into(),
        mm_height: screen.height_in_millimeters.into(),
        config_timestamp: resources.config_timestamp,
        crtcs,
    };

    Ok((layout, resources))
}

/// Size of RandR mode `mode`, from the screen's mode list.
fn mode_size(resources: &randr::GetScreenResourcesCurrentReply, mode: randr::Mode) -> Option<(u16, u16)> {
    resources
        .modes
        .iter()
        .find(|info| info.id == mode)
        .map(|info| (info.width, info.height))
}

/// Interns `name` and returns the atom.
fn atom(conn: &RustConnection, name: &[u8]) -> ResultType<xproto::Atom> {
    Ok(conn.intern_atom(false, name)?.reply()?.atom)
}

/// Reads a list of 32-bit values (atoms or windows) from `window`'s `property`.
fn read_u32_list(
    conn: &RustConnection,
    window: xproto::Window,
    property: xproto::Atom,
    kind: xproto::AtomEnum,
) -> ResultType<Vec<u32>> {
    let reply = conn
        .get_property(false, window, property, kind, 0, u32::MAX)?
        .reply()?;

    Ok(reply.value32().map(|values| values.collect()).unwrap_or_default())
}

/// Where one client window is now, or None when it has gone away.
fn read_placement(
    conn: &RustConnection,
    root: xproto::Window,
    window: xproto::Window,
) -> Option<WindowPlacement> {
    let geometry = conn.get_geometry(window).ok()?.reply().ok()?;
    let position = conn.translate_coordinates(window, root, 0, 0).ok()?.reply().ok()?;

    Some(WindowPlacement {
        window,
        x: position.dst_x,
        y: position.dst_y,
        width: geometry.width,
        height: geometry.height,
    })
}

/// Records where every window the window manager lists in _NET_CLIENT_LIST is.
fn snapshot_windows(conn: &RustConnection, root: xproto::Window) -> ResultType<Vec<WindowPlacement>> {
    let client_list = atom(conn, NET_CLIENT_LIST)?;
    let windows = read_u32_list(conn, root, client_list, xproto::AtomEnum::WINDOW)?;

    Ok(windows
        .into_iter()
        .filter_map(|window| read_placement(conn, root, window))
        .collect())
}

/// Starts a fit of monitor `name`: records the layout and windows that the session will restore.
fn begin_session(
    conn: &RustConnection,
    root: xproto::Window,
    screen_num: usize,
    name: &str,
) -> ResultType<FitSession> {
    let monitor = find_monitor(conn, root, name)?;
    let (layout, _) = read_layout(conn, root, screen_num)?;
    let windows = snapshot_windows(conn, root)?;

    log::info!(
        "Fitting display '{}' ({}x{}); saved {} CRTCs and {} windows",
        name,
        monitor.width,
        monitor.height,
        layout.crtcs.len(),
        windows.len()
    );

    Ok(FitSession {
        monitor: name.to_owned(),
        original: (monitor.width, monitor.height),
        layout,
        windows,
    })
}

/// Sets one CRTC and fails unless the server accepted it.
fn set_crtc(conn: &RustConnection, config_timestamp: xproto::Timestamp, state: &CrtcState) -> ResultType<()> {
    let reply = conn
        .randr_set_crtc_config(
            state.crtc,
            CURRENT_TIME,
            config_timestamp,
            state.x,
            state.y,
            state.mode,
            state.rotation,
            &state.outputs,
        )?
        .reply()?;

    if reply.status != randr::SetConfig::SUCCESS {
        bail!("Setting CRTC {} failed: {:?}", state.crtc, reply.status);
    }

    Ok(())
}

/// Sets the screen size in pixels, keeping the DPI of `reference`.
fn set_screen_size(
    conn: &RustConnection,
    root: xproto::Window,
    size: (u16, u16),
    reference: &ScreenLayout,
) -> ResultType<()> {
    let mm_width = scaled_millimeters(size.0, reference.width, reference.mm_width);
    let mm_height = scaled_millimeters(size.1, reference.height, reference.mm_height);

    conn.randr_set_screen_size(root, size.0, size.1, mm_width, mm_height)?
        .check()?;

    Ok(())
}

/// The CRTC that drives the first output of `monitor`, as it was in `layout`.
fn monitor_crtc<'a>(monitor_outputs: &[randr::Output], layout: &'a ScreenLayout) -> ResultType<&'a CrtcState> {
    layout
        .crtcs
        .iter()
        .find(|state| state.mode != NONE && state.outputs.iter().any(|o| monitor_outputs.contains(o)))
        .ok_or_else(|| anyhow!("The monitor has no active CRTC"))
}

/// Makes the screen `target` pixels, shown on the session's monitor at its original mode, with
/// every other monitor switched off. Runs under a server grab so clients see one change.
fn apply_fit(
    conn: &RustConnection,
    root: xproto::Window,
    screen_num: usize,
    session: &FitSession,
    target: (u16, u16),
) -> ResultType<()> {
    let outputs = find_monitor(conn, root, &session.monitor)?.outputs;
    let fitted = monitor_crtc(&outputs, &session.layout)?;
    let (current, resources) = read_layout(conn, root, screen_num)?;
    let native = mode_size(&resources, fitted.mode)
        .ok_or_else(|| anyhow!("Mode {} of the fitted monitor is unknown", fitted.mode))?;

    if fitted.rotation != randr::Rotation::ROTATE0 {
        bail!("Fitting a rotated monitor is not supported");
    }

    conn.grab_server()?;
    let result = fit_under_grab(conn, root, &current, fitted, native, target);
    conn.ungrab_server()?;
    conn.flush()?;

    result
}

/// The steps of [apply_fit] that must happen while the server is grabbed.
fn fit_under_grab(
    conn: &RustConnection,
    root: xproto::Window,
    current: &ScreenLayout,
    fitted: &CrtcState,
    native: (u16, u16),
    target: (u16, u16),
) -> ResultType<()> {
    for other in current.crtcs.iter().filter(|c| c.crtc != fitted.crtc && c.mode != NONE) {
        let off = CrtcState { x: 0, y: 0, mode: NONE, rotation: randr::Rotation::ROTATE0, outputs: vec![], ..other.clone() };

        set_crtc(conn, current.config_timestamp, &off)?;
    }

    set_screen_size(conn, root, covering_size((current.width, current.height), target), current)?;
    conn.randr_set_crtc_transform(fitted.crtc, scale_transform(native, target), SCALE_FILTER, &[])?
        .check()?;

    let placed = CrtcState { x: 0, y: 0, ..fitted.clone() };

    set_crtc(conn, current.config_timestamp, &placed)?;
    set_screen_size(conn, root, target, current)
}

/// Puts back the screen size, every CRTC and every transform recorded in `saved`.
fn restore_layout(conn: &RustConnection, root: xproto::Window, screen_num: usize, saved: &ScreenLayout) -> ResultType<()> {
    let (current, _) = read_layout(conn, root, screen_num)?;

    conn.grab_server()?;
    let result = restore_under_grab(conn, root, &current, saved);
    conn.ungrab_server()?;
    conn.flush()?;

    result
}

/// The steps of [restore_layout] that must happen while the server is grabbed.
fn restore_under_grab(
    conn: &RustConnection,
    root: xproto::Window,
    current: &ScreenLayout,
    saved: &ScreenLayout,
) -> ResultType<()> {
    let original = (saved.width, saved.height);

    set_screen_size(conn, root, covering_size((current.width, current.height), original), saved)?;

    for state in &saved.crtcs {
        conn.randr_set_crtc_transform(state.crtc, state.transform, &state.filter_name, &state.filter_params)?
            .check()?;
        set_crtc(conn, current.config_timestamp, state)?;
    }

    set_screen_size(conn, root, original, saved)
}

/// Whether the window manager owns `window`'s size right now (maximized or fullscreen).
fn is_wm_managed(conn: &RustConnection, window: xproto::Window, managed: &[xproto::Atom]) -> bool {
    let Ok(state) = atom(conn, NET_WM_STATE) else {
        return false;
    };

    read_u32_list(conn, window, state, xproto::AtomEnum::ATOM)
        .map(|states| states.iter().any(|s| managed.contains(s)))
        .unwrap_or(false)
}

/// Asks the window manager to put `placement`'s window back where it was.
fn send_moveresize(
    conn: &RustConnection,
    root: xproto::Window,
    moveresize: xproto::Atom,
    placement: &WindowPlacement,
) -> ResultType<()> {
    let data = [
        MOVERESIZE_FLAGS,
        placement.x as i32 as u32,
        placement.y as i32 as u32,
        placement.width.into(),
        placement.height.into(),
    ];
    let event = xproto::ClientMessageEvent::new(32, placement.window, moveresize, data);
    let mask = xproto::EventMask::SUBSTRUCTURE_REDIRECT | xproto::EventMask::SUBSTRUCTURE_NOTIFY;

    conn.send_event(false, root, mask, event)?;

    Ok(())
}

/// Moves every saved window that still exists back to its saved place, except windows the
/// window manager is sizing itself.
fn restore_windows(windows: &[WindowPlacement]) -> ResultType<()> {
    let (conn, root, _) = connect()?;
    let moveresize = atom(&conn, NET_MOVERESIZE_WINDOW)?;
    let mut managed = Vec::with_capacity(WM_MANAGED_STATES.len());

    for name in WM_MANAGED_STATES {
        managed.push(atom(&conn, name)?);
    }

    for placement in windows {
        if read_placement(&conn, root, placement.window).is_none() || is_wm_managed(&conn, placement.window, &managed) {
            continue;
        }

        send_moveresize(&conn, root, moveresize, placement)?;
    }

    conn.flush()?;

    Ok(())
}

/// Restores `windows` once the window manager has finished reacting to the layout change.
fn schedule_window_restore(windows: Vec<WindowPlacement>) {
    thread::spawn(move || {
        thread::sleep(WINDOW_RESTORE_DELAY);

        if let Err(e) = restore_windows(&windows) {
            log::error!("Failed to restore window positions: {}", e);
        }
    });
}

/// Size of the X11 monitor named `name`, as the screen currently shows it.
pub fn current_resolution(name: &str) -> ResultType<Resolution> {
    let (conn, root, _) = connect()?;
    let monitor = find_monitor(&conn, root, name)?;

    Ok(Resolution {
        width: monitor.width.into(),
        height: monitor.height.into(),
        ..Default::default()
    })
}

/// The modes the X11 monitor named `name` lists, each size once, in the order the server gives.
pub fn resolutions(name: &str) -> Vec<Resolution> {
    match list_resolutions(name) {
        Ok(sizes) => sizes,
        Err(e) => {
            log::error!("Failed to list resolutions of '{}': {}", name, e);
            vec![]
        }
    }
}

/// [resolutions], with failures reported.
fn list_resolutions(name: &str) -> ResultType<Vec<Resolution>> {
    let (conn, root, _) = connect()?;
    let monitor = find_monitor(&conn, root, name)?;
    let resources = conn.randr_get_screen_resources_current(root)?.reply()?;
    let mut sizes: Vec<Resolution> = vec![];

    for output in &monitor.outputs {
        let info = conn.randr_get_output_info(*output, resources.config_timestamp)?.reply()?;

        for (width, height) in info.modes.iter().filter_map(|mode| mode_size(&resources, *mode)) {
            let size = Resolution { width: width.into(), height: height.into(), ..Default::default() };

            if !sizes.contains(&size) {
                sizes.push(size);
            }
        }
    }

    Ok(sizes)
}

/// Makes the X11 monitor named `name` show a `width` x `height` screen.
///
/// The first call of a session saves the layout and window positions; asking for the monitor's
/// size from before that call restores them and ends the session.
pub fn change_resolution(name: &str, width: usize, height: usize) -> ResultType<()> {
    let target = (to_dimension(width)?, to_dimension(height)?);
    let (conn, root, screen_num) = connect()?;
    let mut session = FIT_SESSION.lock().unwrap();

    if let Some(active) = session.as_ref().filter(|s| s.monitor == name && s.original == target) {
        restore_layout(&conn, root, screen_num, &active.layout)?;

        let ended = session.take().map(|s| s.windows).unwrap_or_default();

        schedule_window_restore(ended);

        return Ok(());
    }

    if session.is_none() {
        *session = Some(begin_session(&conn, root, screen_num, name)?);
    }

    let active = session.as_ref().ok_or_else(|| anyhow!("No fit session"))?;

    apply_fit(&conn, root, screen_num, active, target)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fixed_point_matches_randr() {
        assert_eq!(to_fixed(1.0), 65536);
        assert_eq!(to_fixed(0.5), 32768);
    }

    #[test]
    fn scale_transform_maps_the_native_mode_onto_the_target() {
        let native = (5120, 1440);
        let target = (1920, 1200);
        let t = scale_transform(native, target);

        assert_eq!(t.matrix11, to_fixed(1920.0 / 5120.0));
        assert_eq!(t.matrix22, to_fixed(1200.0 / 1440.0));
        assert_eq!(t.matrix33, to_fixed(1.0));
        assert_eq!((t.matrix12, t.matrix13, t.matrix21, t.matrix23, t.matrix31, t.matrix32), (0, 0, 0, 0, 0, 0));
    }

    #[test]
    fn same_size_is_the_identity() {
        let t = scale_transform((1920, 1080), (1920, 1080));

        assert_eq!((t.matrix11, t.matrix22, t.matrix33), (to_fixed(1.0), to_fixed(1.0), to_fixed(1.0)));
    }

    #[test]
    fn millimeters_keep_the_reference_density() {
        assert_eq!(scaled_millimeters(1920, 5120, 1355), 508);
        assert_eq!(scaled_millimeters(5120, 5120, 1355), 1355);
        assert_eq!(scaled_millimeters(100, 0, 1355), 0);
    }

    #[test]
    fn covering_size_holds_both_sizes() {
        assert_eq!(covering_size((5120, 1440), (1920, 1600)), (5120, 1600));
        assert_eq!(covering_size((1920, 1200), (5120, 1440)), (5120, 1440));
    }

    #[test]
    fn dimensions_out_of_range_are_refused() {
        assert!(to_dimension(0).is_err());
        assert!(to_dimension(usize::from(u16::MAX) + 1).is_err());
        assert_eq!(to_dimension(1920).unwrap(), 1920);
    }

    #[test]
    fn moveresize_flags_use_static_gravity_all_fields_and_pager_source() {
        assert_eq!(MOVERESIZE_FLAGS & 0xff, STATIC_GRAVITY);
        assert_eq!((MOVERESIZE_FLAGS >> 8) & 0xf, 0xf);
        assert_eq!(MOVERESIZE_FLAGS >> 12, 2);
    }
}
