import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

Future<Uint8List?> pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    return await pickedFile.readAsBytes();
  }
  return null;
}

Future<List<Uint8List>?> pickImages() async {
  final picker = ImagePicker();
  final pickedFiles = await picker.pickMultiImage();
  if (pickedFiles.isNotEmpty) {
    return Future.wait(pickedFiles.map((file) => file.readAsBytes()));
  }
  return null;
} 