import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The layers of `lib`, each allowed to import only what lies further in.
/// See "Architecture" in the README.
void main() {
  test('the domain imports nothing but itself', () {
    expect(
      importsOf(
        'lib/domain',
        allowed: (import, from) {
          // `meta` is annotations only (@immutable).
          if (import == 'package:meta/meta.dart') return true;
          return isRelative(import) &&
              layerOf(resolve(import, from)) == 'domain';
        },
      ),
      isEmpty,
    );
  });

  test('the data layer imports the domain and nothing else of the app', () {
    expect(
      importsOf(
        'lib/data',
        allowed: (import, from) {
          if (!isRelative(import)) return !import.startsWith('package:flutter');
          return const {
            'data',
            'domain',
          }.contains(layerOf(resolve(import, from)));
        },
      ),
      isEmpty,
    );
  });

  test('the UI reaches data through the domain, and is handed its use '
      'cases', () {
    expect(
      importsOf(
        'lib/ui',
        allowed: (import, from) {
          if (!isRelative(import)) return true;
          return const {
            'ui',
            'domain',
            'l10n',
          }.contains(layerOf(resolve(import, from)));
        },
      ),
      isEmpty,
    );
  });

  test('widgets draw UI models; the domain stops at the view models', () {
    bool allowed(String import, File from) =>
        !isRelative(import) || layerOf(resolve(import, from)) != 'domain';

    expect([
      ...importsOf('lib/ui/home/widgets', allowed: allowed),
      ...importsOf('lib/ui/home/home_screen.dart', allowed: allowed),
    ], isEmpty);
  });

  test('the check itself sees a wrong import', () {
    final probe = File('lib/domain/models/place.dart');
    expect(
      importsIn(probe, "import '../../ui/core/l10n.dart';\n", (_, _) => false),
      ['lib/domain/models/place.dart imports ../../ui/core/l10n.dart'],
    );
  });
}

final _import = RegExp(
  r'''^(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

bool isRelative(String import) => !import.contains(':');

/// The path under `lib` that a relative [import] in [from] points at.
String resolve(String import, File from) =>
    from.absolute.parent.uri.resolve(import).path.split('/lib/').last;

/// The first folder of a path under `lib`: "domain", "data", "ui", ...
String layerOf(String pathUnderLib) => pathUnderLib.split('/').first;

/// Every import under [path] that [allowed] turns down, as
/// "file imports target".
List<String> importsOf(
  String path, {
  required bool Function(String import, File from) allowed,
}) {
  final files = FileSystemEntity.isDirectorySync(path)
      ? Directory(path)
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
      : [File(path)];
  expect(files, isNotEmpty, reason: 'nothing to check under $path');
  return [
    for (final file in files)
      ...importsIn(file, file.readAsStringSync(), allowed),
  ];
}

List<String> importsIn(
  File file,
  String source,
  bool Function(String import, File from) allowed,
) => [
  for (final match in _import.allMatches(source))
    if (!allowed(match[1]!, file)) '${file.path} imports ${match[1]}',
];
