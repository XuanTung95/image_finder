import 'package:image/image.dart' as i;

extension ImageEx on i.Image {

  void clearBackground(int color) {
    // loop all pixels
    for (var i = 0; i < length; i++) {
      // value 0 means null pixel
      if (data[i] == color) {
        // set the pixel to the given color
        data[i] = 0;
      }
    }
  }
}