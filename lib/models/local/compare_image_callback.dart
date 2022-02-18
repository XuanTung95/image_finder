import 'dart:ui';

import 'image_compare_model.dart';

class CompareImageCallback {
  final void Function(ResultWithAlgorithm) onAlgorithm;
  final void Function(CompareResult, int, int) onResult;
  final VoidCallback onDone;

  CompareImageCallback({required this.onAlgorithm, required this.onResult, required this.onDone});
}