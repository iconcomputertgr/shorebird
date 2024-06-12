// ignore_for_file: public_member_api_docs

import 'package:scoped_deps/scoped_deps.dart';

/// A reference to an [EngineConfig] instance.
final engineConfigRef = create(() => const EngineConfig.empty());

/// The [EngineConfig] instance available in the current zone.
EngineConfig get engineConfig => read(engineConfigRef);

class EngineConfig {
  const EngineConfig({
    required this.localEngineSrcPath,
    required this.localEngine,
    required this.localEngineHost,
  });

  const EngineConfig.empty()
      : localEngineSrcPath = null,
        localEngine = null,
        localEngineHost = null;

  final String? localEngineSrcPath;
  final String? localEngine;
  final String? localEngineHost;

  @override
  String toString() {
    return '''EngineConfig(localEngineSrcPath: $localEngineSrcPath, localEngine: $localEngine, localEngineHost: $localEngineHost)''';
  }
}
