import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import 'commands/disable.dart';
import 'commands/enable.dart';
import 'commands/list.dart';
import 'commands/logs.dart';
import 'commands/ntfy.dart';
import 'commands/remove.dart';
import 'commands/run.dart';
import 'commands/watch.dart';
import 'src/version.dart';

class GitWatcherRunner extends CommandRunner {
  GitWatcherRunner()
      : super('gitwatcher',
            'A CLI tool to watch files on git repositories and notify with NTFY.') {
    // argParser.addFlag(
    //     'verbose', abbr: 'v', negatable: false, help: 'Increase logging.');
    // argParser.addOption('path', abbr: 'p',
    //     help: 'Path of the config file if it is not in the root directory of the project.');

    addCommand(WatchCommand());
    addCommand(RunCommand());
    addCommand(ListCommand());
    addCommand(RemoveCommand());
    addCommand(EnableCommand());
    addCommand(DisableCommand());
    addCommand(NTFYCommand());
    addCommand(LogsCommand());
    addCommand(VersionCommand());

    argParser.addFlag('version',
        abbr: 'v', negatable: false, help: 'Print the version of the tool.');
  }

  @override
  Future runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      stdout.writeln(packageVersion);
      exit(0);
    }
    return super.runCommand(topLevelResults);
  }
}

class VersionCommand extends Command {
  @override
  String get description => 'Print the version of the tool.';

  @override
  String get name => 'version';

  @override
  void run() {
    stdout.writeln(packageVersion);
    exit(0);
  }
}
