import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_slidable_cell/flutter_slideable_cell.dart';

void main() {
  test('controller returns closed status by default', () {
    final controller = SlideableCellController();
    expect(
      controller.statusOf(const ValueKey('unknown')),
      SlideableCellStatus.closed,
    );
  });
}
