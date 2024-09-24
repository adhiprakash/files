import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ExternalStorage {
  static Future<Directory> getExternalStoragePath() async {
    final storagePermission = await Permission.storage.status;
    if(!storagePermission.isGranted) {
      await Permission.storage.request();
    }
    final managePermission = await Permission.manageExternalStorage.status;
    if(!managePermission.isGranted) {
      await Permission.manageExternalStorage.request();
    }

    if(Platform.isAndroid) {
      const path = "/storage/emulated/0";
      return Directory(path);
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  static Future<List<FileSystemEntity>> getFile(String folder) async {
    final basePath = await getExternalStoragePath();
    final path = "${basePath.path}/$folder";
    return Directory(path).listSync();
  }
}