import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyperbolic/printer.dart';
import 'package:hyperbolic/slider.dart';

void main() {
  setUp(() {
    DebugPrint.padZzz = 0;
  });

  tearDown(() {
    DebugPrint.padZzz = 7;
  });

  group('Printer utility functions', () {
    test('trunc collapses whitespace and truncates at cutoff', () {
      expect(trunc('hello  world'), 'hello world');
      expect(trunc('line 1\n  line 2\n\nline 3'), 'line 1 line 2 line 3');
      expect(trunc('short', cutoff: 10), 'short');
      expect(trunc('abcdefghij extra', cutoff: 10), 'abcdefghij...');
    });

    test('zzz and zzz2 format various primitives', () {
      expect(zzz2(double.nan), 'NaN');
      expect(zzz2(double.infinity), 'inf');
      expect(zzz2(123.456), '123');
      expect(zzz2(-75.2), '-75');
      expect(zzz2(3.14159), '3.14');

      expect(zzz2(const Offset(1.0, 2.0)), 'o(1.00, 2.00)');

      final slider = MySlider('speed', -1.0, 1.0, 0.5);
      expect(zzz2(slider), 's(0.500)');

      expect(zzz2([1.0, 2.0]), '[1.00, 2.00]');

      DebugPrint.padZzz = 10;
      expect(zzz(1.0).length >= 10, true);
    });

    test('Log enum values have descriptions', () {
      for (final log in Log.values) {
        expect(log.description.isNotEmpty, true);
      }
      expect(Log.errors.description, contains('errors'));
    });
  });
}
