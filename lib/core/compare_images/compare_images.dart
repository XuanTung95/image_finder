import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:image_compare/image_compare.dart';
import 'package:image_finder/utils/app_utils.dart';
import 'package:stream_channel/isolate_channel.dart';

import '../../models/local/compare_image_callback.dart';
import '../../models/local/image_compare_model.dart';


const CMD = 'cmd';
const CMD_START = 'start';
const CMD_END = 'end';

class ImageCompareExecutor {
  final String imagePath;
  final String folderPath;
  final int? background;
  final int? clearColor;
  bool _isStopped = false;
  bool _isRunning = false;
  IsolateChannel? channel;
  Isolate? isolate;

  ImageCompareExecutor(
      {required this.imagePath, required this.folderPath, this.background, this.clearColor, });

  void stop() {
    print('stop, $channel $isolate');
    _isStopped = true;
    isolate?.kill(priority: Isolate.immediate);
    channel = null;
  }

  Future compareInBackground(
    CompareImageCallback callback,
  ) async {
    if (_isRunning) {
      return;
    }
    print('Run Search ${toString()}');
    _isRunning = true;
    ReceivePort rPort = ReceivePort();
    channel = IsolateChannel.connectReceive(rPort);
    channel!.stream.listen((data) {
      // print('data $data');
      if (_isStopped) return;
      if (data is Map) {
        var cmd = data[CMD];
        if (cmd == CMD_START) {
          channel?.sink.add({
            CMD: CMD_START,
            'image': imagePath,
            'folder': folderPath,
            'background': background,
            'clearColor': clearColor,
          });
        }
      } else if (data == null) {
        callback.onDone();
      } else if (data is ResultWithAlgorithm) {
        callback.onAlgorithm(data);
      } else if (data is ResultInfoCallback) {
        callback.onResult(data.result, data.count, data.total);
      } else {
        print('Invalid command');
      }
    });
    isolate = await Isolate.spawn(_compareImages, rPort.sendPort);
  }

  @override
  String toString() {
    return 'CompareImage{imagePath: $imagePath, folderPath: $folderPath, background: $background, clearColor: $clearColor, _isStopped: $_isStopped, _isRuning: $_isRunning, channel: $channel, isolate: $isolate}';
  }
}

void _compareImages(SendPort sPort) {
  String? imagePath;
  String? folderPath;
  int? background;
  int? clearColor;
  IsolateChannel channel = IsolateChannel.connectSend(sPort);
  channel.stream.listen((message) async {
    print("Isolate received '$message'");
    var cmd = message[CMD];
    if (cmd == CMD_END) {
      Isolate.exit(sPort);
    } else if (cmd == CMD_START) {
      imagePath = message['image'];
      folderPath = message['folder'];
      background = message['background'];
      clearColor = message['clearColor'];
      var dir = Directory(folderPath!);
      var allItems = await dir.list(recursive: true).toList();
      List<CompareResult> compareResult = [];
      for (FileSystemEntity item in allItems) {
        if (item.path.endsWith('.png')) {
          compareResult.add(CompareResult(item.path));
        }
      }
      var image1 = await AppUtils.getImageFromDynamic(File(imagePath!), clearColor: clearColor);

      int count = 0;
      int total = compareResult.length;

      List<ResultWithAlgorithm> algorithms = [
        ResultWithAlgorithm(EuclideanColorDistance()),
        ResultWithAlgorithm(IMED()),
        ResultWithAlgorithm(PerceptualHash()),
        ResultWithAlgorithm(AverageHash()),
        ResultWithAlgorithm(PixelMatching(ignoreAlpha: true)),
        ResultWithAlgorithm(ChiSquareDistanceHistogram(ignoreAlpha: true)),
        ResultWithAlgorithm(IntersectionHistogram(ignoreAlpha: true)),
        ResultWithAlgorithm(MedianHash()),
      ];
      await Future.forEach<ResultWithAlgorithm>(algorithms, (algorithm) async {
        count = 0;
        channel.sink.add(algorithm);
        await Future.forEach<CompareResult>(compareResult, (compare) async {
          try {
            var image2 = await AppUtils.getImageFromDynamic(File(compare.path),
                background: background);
            var result = await compareImages(
                src1: image1, src2: image2, algorithm: algorithm.algorithm);
            count++;
            channel.sink.add(ResultInfoCallback(
                result: CompareResult(compare.path, result: result),
                count: count,
                total: total));
          } catch (e) {
            print('$e : ${compare.path}');
          }
        });
      });
      Isolate.exit(sPort);
    }
  });
  channel.sink.add({CMD: CMD_START});
}