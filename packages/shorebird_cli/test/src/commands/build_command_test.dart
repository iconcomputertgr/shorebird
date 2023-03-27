import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:args/args.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shorebird_cli/src/auth/auth.dart';
import 'package:shorebird_cli/src/auth/session.dart';
import 'package:shorebird_cli/src/commands/build_command.dart';
import 'package:shorebird_cli/src/config/config.dart';
import 'package:shorebird_code_push_client/shorebird_code_push_client.dart';
import 'package:test/test.dart';

class _MockArgResults extends Mock implements ArgResults {}

class _MockAuth extends Mock implements Auth {}

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _MockProcessResult extends Mock implements ProcessResult {}

class _MockCodePushClient extends Mock implements CodePushClient {}

void main() {
  group('build', () {
    const session = Session(apiKey: 'test-api-key');

    late ArgResults argResults;
    late Directory applicationConfigHome;
    late Auth auth;
    late CodePushClient codePushClient;
    late Logger logger;
    late ProcessResult processResult;
    late BuildCommand buildCommand;

    setUp(() {
      applicationConfigHome = Directory.systemTemp.createTempSync();
      argResults = _MockArgResults();
      auth = _MockAuth();
      codePushClient = _MockCodePushClient();
      logger = _MockLogger();
      processResult = _MockProcessResult();
      buildCommand = BuildCommand(
        auth: auth,
        buildCodePushClient: ({required String apiKey, Uri? hostedUri}) {
          return codePushClient;
        },
        logger: logger,
        runProcess: (executable, arguments, {bool runInShell = false}) async {
          return processResult;
        },
      )..testArgResults = argResults;
      testApplicationConfigHome = (_) => applicationConfigHome.path;

      when(() => argResults.rest).thenReturn([]);
      when(
        () => codePushClient.downloadEngine(revision: any(named: 'revision')),
      ).thenAnswer((_) async => Uint8List.fromList([]));
      when(() => logger.progress(any())).thenReturn(_MockProgress());
    });

    test('exits with no user when not logged in', () async {
      when(() => auth.currentSession).thenReturn(null);

      final result = await buildCommand.run();
      expect(result, equals(ExitCode.noUser.code));

      verify(() => logger.err('You must be logged in to build.')).called(1);
      verify(
        () => logger.err("Run 'shorebird login' to log in and try again."),
      ).called(1);
    });

    test('exits with code 70 when pulling engine fails', () async {
      when(
        () => codePushClient.downloadEngine(revision: any(named: 'revision')),
      ).thenThrow(Exception('oops'));
      when(() => auth.currentSession).thenReturn(session);

      final result = await buildCommand.run();

      expect(result, equals(ExitCode.software.code));
    });

    test('exits with code 70 when building fails', () async {
      when(() => processResult.exitCode).thenReturn(1);
      when(() => processResult.stderr).thenReturn('oops');
      final tempDir = Directory.systemTemp.createTempSync();
      when(() => auth.currentSession).thenReturn(session);
      when(
        () => codePushClient.downloadEngine(revision: any(named: 'revision')),
      ).thenAnswer(
        (_) async => Uint8List.fromList(ZipEncoder().encode(Archive())!),
      );

      final result = await IOOverrides.runZoned(
        () async => buildCommand.run(),
        getCurrentDirectory: () => tempDir,
      );

      expect(result, equals(ExitCode.software.code));
    });

    test('exits with code 0 when building succeeds', () async {
      when(() => processResult.exitCode).thenReturn(ExitCode.success.code);
      final tempDir = Directory.systemTemp.createTempSync();
      when(
        () => codePushClient.downloadEngine(revision: any(named: 'revision')),
      ).thenAnswer(
        (_) async => Uint8List.fromList(ZipEncoder().encode(Archive())!),
      );
      when(() => auth.currentSession).thenReturn(session);

      final result = await IOOverrides.runZoned(
        () async => buildCommand.run(),
        getCurrentDirectory: () => tempDir,
      );

      expect(result, equals(ExitCode.success.code));
    });
  });
}
