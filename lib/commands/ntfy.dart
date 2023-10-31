import 'dart:io';

import 'package:ansi/ansi.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:http/http.dart' as http;

import '../ntfy_manager.dart';

class NTFYCommand extends Command {
  NTFYCommand() {
    addSubcommand(UrlCommand());
    addSubcommand(ResetCommand());
    addSubcommand(TestCommand());
  }

  @override
  String get description => 'Configure NTFY.';

  @override
  String get name => 'ntfy';

  @override
  Future run() async {
    if (!argResults!.wasParsed('delete')) {
      super.run();
    }

    final Logger logger = Logger.standard();
    final NtfyManager manager = NtfyManager();
    await manager.clear();

    logger.stdout(green('✅ NTFY configuration deleted.'));
  }
}

class UrlCommand extends Command {
  @override
  String get description => 'Set the NTFY topic URL.';

  @override
  String get name => 'url';

  @override
  Future run() async {
    final Logger logger = Logger.standard();
    final NtfyManager manager = NtfyManager();

    if (argResults!.rest.isEmpty) {
      // print url
      final config = await manager.get();
      if (config == null) {
        exit(0);
      }
      logger.stdout(blue(config.topicUrl));
      exit(0);
    }

    final String url = argResults!.rest.first;

    await manager.set(url);
    logger.stdout(green('✅ NTFY topic URL set to $url.'));
    exit(0);
  }
}

class ResetCommand extends Command {
  @override
  String get description => 'Reset the NTFY configuration.';

  @override
  String get name => 'reset';

  @override
  Future run() async {
    final Logger logger = Logger.standard();
    final NtfyManager manager = NtfyManager();
    await manager.clear();

    logger.stdout(green('✅ NTFY configuration deleted.'));
  }
}

class TestCommand extends Command {
  @override
  String get description => 'Test NTFY URL.';

  @override
  String get name => 'test';

  @override
  Future run() async {
    final Logger logger = Logger.standard();
    final NtfyManager manager = NtfyManager();

    final config = await manager.get();
    if (config == null) {
      logger.stderr(red('❌ NTFY topic URL not set.'));
      exit(1);
    }

    final url = config.topicUrl;
    logger.stdout('Testing NTFY URL $url...');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Title': 'Test from Git Watcher',
          'Actions': 'view, View, https://github.com, clear=true;',
        },
        body: 'Test Notification from Git Watcher.',
      );

      if (response.statusCode != 200) {
        logger.stderr(red(
            '❌ Unable send notification. ${response.statusCode}: ${response.reasonPhrase}'));
        exit(1);
      }

      logger.stdout(green('✅ Test notification sent.'));
    } catch (error, stacktrace) {
      logger.stderr(red('❌ Unable to connect to $url.'));
      logger.stderr(red('Error: $error'));
      logger.stderr(red('Stacktrace: $stacktrace'));
      exit(1);
    }
  }
}
