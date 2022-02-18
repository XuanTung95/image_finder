import 'dart:io';

import 'package:from_css_color/from_css_color.dart';
import 'package:image/image.dart' as i;
import 'extensions/image_extension.dart';

class AppUtils {
  static int? getColorFromHex(String code) {
    try {
      return fromCssColor(code).value;
    } catch (e) {
      print(e);
    }
    return null;
  }

  static Future<i.Image> getImageFromDynamic(var src, {int? background, int? clearColor}) async {
    // Error message if image format can't be identified
    var err = 'A valid image could not be identified from ';
    var bytes = <int>[];

    if (src is File) {
      bytes = src.readAsBytesSync();

      err += '${src.path}. Provide image file.';
    } else if (src is List<int>) {
      bytes = src;

      var list = (src.length <= 10) ? src : src.sublist(0, 10);

      err += '$list<...>';
    } else {
      throw UnsupportedError(
          "The source, ${src.runtimeType}, passed in is unsupported");
    }

    i.Image image = _getValidImage(bytes, err);
    if (background != null) {
      image.fillBackground(background);
    }
    if (clearColor != null) {
      image.clearBackground(clearColor);
    }
    return image;
  }


  /// Helper function to validate [List]
  /// of bytes format and return [Image].
  /// Throws exception if format is invalid.
  static i.Image _getValidImage(List<int> bytes, String err) {
    var image;
    try {
      image = i.decodeImage(bytes);
    } catch (Exception) {
      throw const FormatException("Insufficient data provided to identify image.");
    }

    if (image == null) {
      throw FormatException(err);
    }

    return image;
  }
}