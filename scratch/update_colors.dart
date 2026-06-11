import 'dart:io';

void main() {
  final dir = Directory('lib');
  if (!dir.existsSync()) return;

  dir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      if (content.contains('0xFF4F46E5')) {
        print('Updating ${entity.path}');
        final newContent = content.replaceAll('0xFF4F46E5', '0xFF45B08C');
        entity.writeAsStringSync(newContent);
      }
    }
  });
}
