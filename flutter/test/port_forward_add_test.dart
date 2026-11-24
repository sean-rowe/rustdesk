import 'package:flutter_hbb/desktop/pages/port_forward_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a rule with valid, unused ports can be added', () {
    expect(portForwardAddError('8080', '80', []), isNull);
    expect(portForwardAddError(' 1 ', '65535', [3389]), isNull);
  });

  test('ports outside 1 to 65535 are invalid', () {
    for (final ports in [
      ['0', '80'],
      ['8080', '0'],
      ['65536', '80'],
      ['', '80'],
      ['8080', ''],
      ['abc', '80'],
    ]) {
      expect(portForwardAddError(ports[0], ports[1], []), 'Invalid port',
          reason: '$ports');
    }
  });

  test('a local port can be forwarded only once', () {
    expect(portForwardAddError('8080', '443', [3389, 8080]),
        'This local port is already forwarded');
    expect(portForwardAddError('9090', '8080', [8080]), isNull,
        reason: 'only the local port must be unique');
  });

  test('an invalid port is reported before a duplicate', () {
    expect(portForwardAddError('8080', '0', [8080]), 'Invalid port');
  });
}
