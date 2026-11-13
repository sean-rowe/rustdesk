import 'dart:async';

import 'package:flutter/widgets.dart';

import '../consts.dart';
import 'model.dart';
import 'platform_model.dart';

/// Per-session option: the remote display follows the size of this window, like an RDP session.
const String kOptionFitRemoteToWindow = "fit-remote-to-window";

/// How long the view must keep a size before the remote display is resized to it, so a drag of
/// the window edge resizes the remote once, when the drag ends.
const Duration kFitRemoteDebounce = Duration(milliseconds: 500);

/// Smallest side, in physical pixels, worth resizing the remote display to; a minimized or
/// collapsing window reports less and is ignored.
const int kFitRemoteMinSide = 320;

/// The remote display size, in physical pixels, that shows a view of [logical] size 1:1.
///
/// Returns null when the view is too small to be a real target.
({int width, int height})? fitTargetSize(Size logical, double devicePixelRatio) {
  final width = (logical.width * devicePixelRatio).floor();
  final height = (logical.height * devicePixelRatio).floor();

  if (width < kFitRemoteMinSide || height < kFitRemoteMinSide) {
    return null;
  }

  return (width: width, height: height);
}

/// Keeps the remote display the size of this session's view while
/// [kOptionFitRemoteToWindow] is on, and puts the original size back when it is turned off.
class FitRemoteModel {
  final WeakReference<FFI> parent;
  Timer? _debounce;
  Size? _viewSize;
  double _devicePixelRatio = 1.0;
  ({int width, int height})? _lastRequested;

  FitRemoteModel(this.parent);

  /// Whether the option is on for this session.
  bool get isEnabled {
    final ffi = parent.target;

    if (ffi == null) {
      return false;
    }

    return bind.sessionGetToggleOptionSync(
        sessionId: ffi.sessionId, arg: kOptionFitRemoteToWindow);
  }

  /// Records the view's new [logical] size and resizes the remote once it settles.
  void onViewSizeChanged(Size logical, double devicePixelRatio) {
    _viewSize = logical;
    _devicePixelRatio = devicePixelRatio;
    _scheduleFit();
  }

  /// Re-checks the fit after the remote display changed, e.g. when it first becomes known.
  void onRemoteDisplayChanged() => _scheduleFit();

  /// Turns the option on (fitting now) or off (restoring the remote's original size).
  Future<void> setEnabled(bool enabled) async {
    final ffi = parent.target;

    if (ffi == null) {
      return;
    }

    if (enabled != isEnabled) {
      await bind.sessionToggleOption(
          sessionId: ffi.sessionId, value: kOptionFitRemoteToWindow);
    }

    _debounce?.cancel();
    _lastRequested = null;

    if (enabled) {
      _fitNow();
    } else {
      _restoreOriginal();
    }
  }

  /// Stops any pending resize.
  void dispose() => _debounce?.cancel();

  void _scheduleFit() {
    if (!isEnabled) {
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(kFitRemoteDebounce, _fitNow);
  }

  /// The display this session shows, or null when it shows all displays or none is known yet.
  Display? _currentDisplay() {
    final pi = parent.target?.ffiModel.pi;

    if (pi == null || pi.currentDisplay == kAllDisplayValue) {
      return null;
    }

    if (pi.currentDisplay < 0 || pi.currentDisplay >= pi.displays.length) {
      return null;
    }

    return pi.displays[pi.currentDisplay];
  }

  void _fitNow() {
    final ffi = parent.target;
    final view = _viewSize;
    final display = _currentDisplay();

    if (ffi == null || view == null || display == null) {
      return;
    }

    final target = fitTargetSize(view, _devicePixelRatio);

    if (target == null || target == _lastRequested) {
      return;
    }

    if (display.width == target.width && display.height == target.height) {
      return;
    }

    _lastRequested = target;
    bind.sessionChangeResolution(
        sessionId: ffi.sessionId,
        display: ffi.ffiModel.pi.currentDisplay,
        width: target.width,
        height: target.height);
  }

  void _restoreOriginal() {
    final ffi = parent.target;
    final display = _currentDisplay();

    if (ffi == null || display == null) {
      return;
    }

    if (display.originalWidth == kInvalidResolutionValue ||
        display.originalHeight == kInvalidResolutionValue) {
      return;
    }

    if (display.width == display.originalWidth &&
        display.height == display.originalHeight) {
      return;
    }

    bind.sessionChangeResolution(
        sessionId: ffi.sessionId,
        display: ffi.ffiModel.pi.currentDisplay,
        width: display.originalWidth,
        height: display.originalHeight);
  }
}
