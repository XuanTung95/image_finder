import 'dart:io';
import 'package:clipboard/clipboard.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:image_finder/utils/app_utils.dart';

import '../core/compare_images/compare_images.dart';
import '../models/local/compare_image_callback.dart';
import '../models/local/image_compare_model.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key,}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  var data = ImageCompareData();
  var bgColorController = f.TextEditingController();

  @override
  Widget build(BuildContext context) {
    return f.FluentTheme(
      data: f.ThemeData(),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: f.MainAxisAlignment.start,
                  children: [
                    Text(
                      'Clear input color:',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                Row(
                  children: [
                    buildColorCheckBox(
                        context,
                        'Clear',
                        data.selectColor.clear,
                            (value) => setState(() {
                          data.selectColor.clear = value ?? false;
                          setState(() {});
                        })),
                    SizedBox(
                      width: 200,
                      child: f.TextBox(
                        onChanged: (value) {
                          data.selectColor.clearColor = AppUtils.getColorFromHex(value..trim());
                          print('clear color = ${data.selectColor.clearColor}');
                        },
                        placeholder: '#FFFFFF',
                        decoration: const f.BoxDecoration(),
                      ),
                    ),
                    const f.Spacer()
                  ],
                ),
                const f.SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: f.MainAxisAlignment.start,
                  children: [
                    Text(
                      'Replace PNG background color:',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                Row(
                  children: [
                    buildColorCheckBox(
                        context,
                        'White',
                        data.selectColor.white,
                            (value) => setState(() {
                          data.selectColor.resetReplaceColor();
                          data.selectColor.white = value ?? false;
                          setState(() {});
                        })),
                    buildColorCheckBox(
                        context,
                        'Black',
                        data.selectColor.black,
                            (value) => setState(() {
                          data.selectColor.resetReplaceColor();
                          data.selectColor.black = value ?? false;
                          setState(() {});
                        })),
                    buildColorCheckBox(
                        context,
                        'Custom',
                        data.selectColor.custom,
                            (value) => setState(() {
                          data.selectColor.resetReplaceColor();
                          data.selectColor.custom = value ?? false;
                          setState(() {});
                        })),
                    SizedBox(
                      width: 200,
                      child: f.TextBox(
                        onChanged: (value) {
                          data.selectColor.customColor = AppUtils.getColorFromHex(value);
                        },
                        placeholder: '#FFFFFF',
                        decoration: const f.BoxDecoration(),
                      ),
                    ),
                    const f.Spacer()
                  ],
                ),
                const f.SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    buildButton(
                      context,
                      'Select image to search',
                          () async {
                        FilePickerResult? result =
                        await FilePicker.platform.pickFiles();
                        if (result != null) {
                          data.targetImage = result.files.single.path!;
                          setState(() {});
                        } else {
                          // User canceled the picker
                        }
                      },
                    ),
                    const f.SizedBox(
                      width: 10,
                    ),
                    (data.targetImage != null)
                        ? buildImage(context, data.targetImage!, 60, 60)
                        : const Icon(
                      Icons.error_outline_outlined,
                      color: Colors.red,
                      size: 25,
                    ),
                  ],
                ),
                const f.SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    buildButton(
                      context,
                      'Search folder',
                          () async {
                        String? folder =
                        await FilePicker.platform.getDirectoryPath();
                        if (folder != null) {
                          setState(() {
                            data.searchFolder = folder;
                          });
                        }
                      },
                    ),
                    const f.SizedBox(
                      width: 10,
                    ),
                    (data.searchFolder != null)
                        ? f.Expanded(
                      child: f.TextBox(
                        controller: f.TextEditingController()
                          ..text = data.searchFolder!,
                        decoration: const f.BoxDecoration(),
                        readOnly: true,
                      ),
                    )
                        : const Icon(
                      Icons.error_outline_outlined,
                      color: Colors.red,
                      size: 25,
                    ),
                  ],
                ),
                const f.SizedBox(
                  height: 10,
                ),
                buildButton(
                  context,
                  data.running ? ' STOP ' : 'SEARCH',
                      () async {
                    if (data.targetImage == null || data.searchFolder == null) {
                      return;
                    }
                    if (data.running) {
                      data.running = false;
                      data.imageCompare?.stop();
                      setState(() {});
                      return;
                    }
                    data.resultPerAlgorithm.clear();
                    data.running = true;
                    data.done = false;
                    data.processedCount = 0;
                    data.totalCount = 0;
                    setState(() {});
                    data.imageCompare = ImageCompareExecutor(
                        imagePath: data.targetImage!,
                        folderPath: data.searchFolder!,
                        background: data.selectColor.selectedColor,
                        clearColor: data.selectColor.clearColor);
                    data.imageCompare?.compareInBackground(
                      CompareImageCallback(onAlgorithm: (algorithm) {
                        setState(() {
                          data.resultPerAlgorithm.add(algorithm);
                        });
                      }, onResult:
                          (CompareResult result, int count, int total) {
                        setState(() {
                          data.resultPerAlgorithm.last.results.add(result);
                          data.processedCount = count;
                          data.totalCount = total;
                        });
                      }, onDone: () {
                        data.running = false;
                        data.done = true;
                        setState(() {});
                      }),
                    );
                    return;
                  },
                ),
                Builder(
                  builder: (context) {
                    if (data.resultPerAlgorithm.isNotEmpty) {
                      data.resultPerAlgorithm.last.results.sort((o1, o2) {
                        if (o1.result > o2.result) {
                          return 1;
                        } else if (o1.result < o2.result) {
                          return -1;
                        } else {
                          return 0;
                        }
                      });
                    }
                    return Column(
                      children: data.resultPerAlgorithm.map((item) {
                        var results = item.results;
                        List<CompareResult> items = results;
                        return Column(
                          children: [
                            Container(
                                width: double.infinity,
                                padding:
                                const EdgeInsets.only(top: 20, bottom: 10),
                                child: Text(
                                  item.algorithm.runtimeType.toString(),
                                  style: Theme.of(context).textTheme.headline5,
                                )),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) {
                                  var _item = items[index];
                                  return InkWell(
                                    onTap: () {
                                      showSnackBar(
                                          context, 'Copied: ${_item.path}');
                                      FlutterClipboard.copy(_item.path);
                                    },
                                    child: Column(
                                      children: [
                                        Image.file(
                                          File(_item.path),
                                          width: 100,
                                          height: 100,
                                        ),
                                        Text(
                                            _item.result.toStringAsFixed(2))
                                      ],
                                    ),
                                  );
                                },
                                itemCount: items.length,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
                const f.SizedBox(
                  height: 20,
                ),
                data.done
                    ? Text(
                  'DONE',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
                    : Row(
                  mainAxisAlignment: f.MainAxisAlignment.center,
                  children: [
                    Text(
                      '${data.processedCount}/',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      '${data.totalCount}',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  ],
                ),
              ],
            ),
          ),
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }

  void showSnackBar(f.BuildContext context, String text) {
    var snackBar = SnackBar(
      content: Text(text),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget buildButton(BuildContext context, String text, VoidCallback callback) {
    return f.Button(
      onPressed: callback,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyText1,
        ),
      ),
    );
  }

  Widget buildImage(
      BuildContext context, String path, double? width, double? height) {
    return Image.file(
      File(path),
      width: width,
      height: height,
    );
  }

  Widget buildColorCheckBox(
      BuildContext context,
      String text,
      bool value,
      void Function(dynamic value) callback,
      ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 8),
      child: f.Checkbox(
        content: Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        checked: value,
        onChanged: callback,
      ),
    );
  }
}