import 'dart:io';

import 'package:ansi/ansi.dart';
import 'package:args/command_runner.dart';

import '../file_logger.dart';

class LogsCommand extends Command {
  @override
  String get description => 'Prints the logs.';

  @override
  String get name => 'logs';

  @override
  Future run() async {
    try {
      final FileLogger fileLogger = FileLogger();
      final String logs = await fileLogger.read();

      if (logs.isEmpty) {
        stderr.writeln(blue('No logs found.'));
        return;
      }
      stdout.writeln(logs);
    } catch (e) {
      stderr.writeln(red('Unable to read logs.'));
      stderr.writeln(red('$e'));
    }
  }
}
