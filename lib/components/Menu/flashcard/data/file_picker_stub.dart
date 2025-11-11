

enum FileType { any, custom }

class PlatformFile {
  final String? path;
  PlatformFile({this.path});
}

class FilePickerResult {
  final List<PlatformFile> files;
  FilePickerResult(this.files);
}

class FilePickerPlatform {
  Future<FilePickerResult?> pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    return null;
  }
}

class FilePicker {
  static final platform = FilePickerPlatform();
}

