


import 'package:flutter/material.dart';
import 'package:image_compare/image_compare.dart';

import '../../core/compare_images/compare_images.dart';

class ImageCompareData {
  String? targetImage;
  String? searchFolder;
  int processedCount = 0;
  int totalCount = 0;
  bool done = false;
  bool running = false;

  ImageCompareExecutor? imageCompare;

  var selectColor = SelectInputColor();

  List<ResultWithAlgorithm> resultPerAlgorithm = [];

  String result = '';
}

class SelectInputColor {
  int? _clearColor;
  bool clear = false;

  int? _customColor;
  bool custom = false;
  bool white = false;
  bool black = false;

  set clearColor(int? value) {
    _clearColor = value;
  }

  int? get selectedColor {
    if (white) {
      return Colors.white.value;
    }
    if (black) {
      return Colors.black.value;
    }
    if (custom) {
      return _customColor;
    }
    return null;
  }

  int? get clearColor {
    if (clear) {
      return _clearColor;
    }
    return null;
  }

  void resetReplaceColor() {
    custom = false;
    white = false;
    black = false;
  }

  set customColor(int? value) {
    _customColor = value;
  }
}

class CompareResult {
  final String path;
  double result = 1;

  CompareResult(this.path, {this.result = 1});

  @override
  String toString() {
    return 'CompareResult{path: $path, result: $result}';
  }
}

class ResultWithAlgorithm {
  final Algorithm algorithm;
  List<CompareResult> results = [];
  bool sorted = false;
  bool done = false;

  ResultWithAlgorithm(this.algorithm);
}


class ResultInfoCallback {
  final int count;
  final int total;
  final CompareResult result;

  ResultInfoCallback(
      {required this.count, required this.total, required this.result});
}