import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('route-scoped form provider files do not use raw NotifierProvider', () {
    final List<File> providerFiles = Directory('lib/src')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) {
          final String normalizedPath = file.path.replaceAll('\\', '/');
          return normalizedPath.endsWith('_form_providers.dart') ||
              normalizedPath.endsWith('/form_providers_template.dart');
        })
        .toList()
      ..sort((File a, File b) => a.path.compareTo(b.path));

    expect(providerFiles, isNotEmpty);

    final List<String> offenders = <String>[];
    final RegExp rawNotifierProviderPattern = RegExp(
      r'\b(?:Async)?NotifierProvider<',
    );

    for (final File file in providerFiles) {
      final String content = file.readAsStringSync();
      if (rawNotifierProviderPattern.hasMatch(content)) {
        offenders.add(file.path.replaceAll('\\', '/'));
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Use autoDispose for route-scoped form providers. Offending files: '
          '${offenders.join(', ')}',
    );
  });
}
