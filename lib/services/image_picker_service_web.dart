import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;

Future<Uint8List?> pickImage() async {
  final completer = Completer<Uint8List?>();
  final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
  uploadInput.click();
  uploadInput.onChange.listen((event) {
    final file = uploadInput.files?.first;
    if (file == null) {
      completer.complete(null);
      return;
    }
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoadEnd.listen((event) {
      completer.complete(reader.result as Uint8List);
    });
  });
  return completer.future;
}

Future<List<Uint8List>?> pickImages() async {
  final completer = Completer<List<Uint8List>?>();
  final uploadInput = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = true;
  uploadInput.click();
  uploadInput.onChange.listen((event) async {
    final files = uploadInput.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final results = <Uint8List>[];
    int loaded = 0;
    for (final file in files) {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((event) {
        results.add(reader.result as Uint8List);
        loaded++;
        if (loaded == files.length) {
          completer.complete(results);
        }
      });
    }
  });
  return completer.future;
} 