import 'dart:io';
import 'dart:convert';

void main() {
  final dir = Directory('lib');
  if (!dir.existsSync()) return;

  dir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final bytes = entity.readAsBytesSync();
      try {
        // Try normal decode first
        utf8.decode(bytes);
      } catch (e) {
        print('Fixing encoding for ${entity.path}');
        final content = utf8.decode(bytes, allowMalformed: true);
        entity.writeAsStringSync(content, encoding: utf8);
      }
    }
  });
}
