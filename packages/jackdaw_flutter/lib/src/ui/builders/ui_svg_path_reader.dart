import 'dart:ui';

import 'package:jackdaw_flutter/src/ui/builders/ui_svg_scanner.dart';

/// Reads SVG path data into a [Path]: every SVG 1.1 command, absolute and
/// relative, which are M, L, H, V, C, S, Q, T, A and Z.
final class UiSvgPathReader {
  /// Creates a reader of the path data [data].
  factory(String data) = UiSvgPathReader._;

  new _(String data) : _scan = UiSvgScanner(data);

  final UiSvgScanner _scan;
  final Path _path = Path();
  String _command = '';
  Offset _current = Offset.zero;
  Offset _start = Offset.zero;
  Offset _control = Offset.zero;

  /// The path, or `null` when the data is malformed.
  Path? read() {
    try {
      while (!_scan.done) {
        _step();
      }
      return _path;
    } on FormatException {
      return null;
    }
  }

  void _step() {
    _command = _scan.letter() ?? _command;
    final relative = _command == _command.toLowerCase();
    final kind = _command.toUpperCase();
    Offset point() {
      final at = Offset(_scan.number(), _scan.number());
      return relative ? _current + at : at;
    }

    switch (kind) {
      case 'M':
        _current = _start = point();
        _path.moveTo(_current.dx, _current.dy);
        _command = relative ? 'l' : 'L';
      case 'L' || 'H' || 'V':
        final to = kind == 'L' ? point() : _axis(kind, relative);
        _current = to;
        _path.lineTo(to.dx, to.dy);
      case 'C' || 'S':
        final first = kind == 'C' ? point() : _current * 2 - _control;
        _control = point();
        _current = point();
        _path.cubicTo(
          first.dx,
          first.dy,
          _control.dx,
          _control.dy,
          _current.dx,
          _current.dy,
        );
      case 'Q' || 'T':
        _control = kind == 'Q' ? point() : _current * 2 - _control;
        _current = point();
        _path.quadraticBezierTo(
          _control.dx,
          _control.dy,
          _current.dx,
          _current.dy,
        );
      case 'A':
        final radius = Radius.elliptical(_scan.number(), _scan.number());
        final rotation = _scan.number();
        final large = _scan.flag();
        final clockwise = _scan.flag();
        _current = point();
        _path.arcToPoint(
          _current,
          radius: radius,
          rotation: rotation,
          largeArc: large,
          clockwise: clockwise,
        );
      case 'Z':
        _path.close();
        _current = _start;
      default:
        throw const FormatException('unknown command');
    }
    if (!'CSQT'.contains(kind)) _control = _current;
  }

  Offset _axis(String kind, bool relative) {
    final v = _scan.number();
    final base = relative ? _current : Offset.zero;
    return kind == 'H'
        ? Offset(base.dx + v, _current.dy)
        : Offset(_current.dx, base.dy + v);
  }
}
