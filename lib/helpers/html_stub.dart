// Stub file for dart:html when not running on web platform
// This allows the code to compile on mobile/desktop platforms

class Blob {
  Blob(List<dynamic> parts);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}

class AnchorElement {
  String href = '';
  String download = '';
  CSSStyleDeclaration style = CSSStyleDeclaration();
  void click() {}
}

class CSSStyleDeclaration {
  String display = '';
}

class Document {
  Body? body;
  dynamic createElement(String tag) => AnchorElement();
}

class Body {
  Children children = Children();
}

class Children {
  void add(dynamic element) {}
  void remove(dynamic element) {}
}

final document = Document();

class FileUploadInputElement {
  String accept = '';
  List<File>? files;
  Stream<dynamic> get onChange => Stream.empty();
  void click() {}
}

class File {
  String name = '';
}

class FileReader {
  String? result;
  Stream<dynamic> get onLoadEnd => Stream.empty();
  void readAsText(File file) {}
}
