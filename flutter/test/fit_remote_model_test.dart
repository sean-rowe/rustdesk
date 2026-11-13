import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/models/fit_remote_model.dart';

void main() {
  test('a view maps to the same number of physical pixels', () {
    expect(fitTargetSize(const Size(1300, 740), 1.0), (width: 1300, height: 740));
  });

  test('a HiDPI view asks for its physical pixels, rounding down', () {
    expect(fitTargetSize(const Size(1440.5, 900.25), 2.0),
        (width: 2881, height: 1800));
  });

  test('a view smaller than the minimum side is not a target', () {
    const side = kFitRemoteMinSide - 1;

    expect(fitTargetSize(const Size(side + 0.0, 900), 1.0), isNull);
    expect(fitTargetSize(const Size(1440, side + 0.0), 1.0), isNull);
    expect(fitTargetSize(Size.zero, 1.0), isNull);
  });

  test('the minimum side itself is a target', () {
    const side = kFitRemoteMinSide;

    expect(fitTargetSize(const Size(side + 0.0, side + 0.0), 1.0),
        (width: side, height: side));
  });
}
