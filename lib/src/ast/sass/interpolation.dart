// Copyright 2016 Google Inc. Use of this source code is governed by an
// MIT-style license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';

import '../../interpolation_buffer.dart';
import 'expression.dart';
import 'node.dart';

/// Plain text interpolated with Sass expressions.
///
/// {@category AST}
final class Interpolation implements SassNode {
  /// The contents of this interpolation.
  ///
  /// This contains [String]s and [Expression]s. It never contains two adjacent
  /// [String]s.
  final List<Object /* String | Expression */ > contents;

  final FileSpan span;

  /// If this contains no interpolated expressions, returns its text contents.
  ///
  /// Otherwise, returns `null`.
  String? get asPlain =>
      switch (contents) { [] => '', [String first] => first, _ => null };

  /// Returns the plain text before the interpolation, or the empty string.
  ///
  /// @nodoc
  @internal
  String get initialPlain =>
      switch (contents) { [String first, ...] => first, _ => '' };

  /// Creates a new [Interpolation] by concatenating a sequence of [String]s,
  /// [Expression]s, or nested [Interpolation]s.
  static Interpolation concat(
      Iterable<Object /* String | Expression | Interpolation */ > contents,
      FileSpan span) {
    var buffer = InterpolationBuffer();
    for (var element in contents) {
      switch (element) {
        case String():
          buffer.write(element);
        case Expression():
          buffer.add(element);
        case Interpolation():
          buffer.addInterpolation(element);
        case _:
          throw ArgumentError.value(contents, "contents",
              "May only contains Strings, Expressions, or Interpolations.");
      }
    }

    return buffer.interpolation(span);
  }

  Interpolation(Iterable<Object /* String | Expression */ > contents, this.span)
      : contents = List.unmodifiable(contents) {
    for (var i = 0; i < this.contents.length; i++) {
      if (this.contents[i] is! String && this.contents[i] is! Expression) {
        throw ArgumentError.value(this.contents, "contents",
            "May only contains Strings or Expressions.");
      }

      if (i != 0 &&
          this.contents[i - 1] is String &&
          this.contents[i] is String) {
        throw ArgumentError.value(
            this.contents, "contents", "May not contain adjacent Strings.");
      }
    }
  }

  String toString() =>
      contents.map((value) => value is String ? value : "#{$value}").join();
}
