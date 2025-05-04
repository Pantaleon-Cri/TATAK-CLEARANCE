import 'dart:typed_data';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

Future<void> saveFile(Uint8List fileBytes, String fileName) async {
  final directory = await getExternalStorageDirectory() ??
      await getApplicationDocumentsDirectory();
  final path = '${directory.path}/$fileName';

  final file = io.File(path);
  await file.writeAsBytes(fileBytes);

  await OpenFile.open(path);
}
