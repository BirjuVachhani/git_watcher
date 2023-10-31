import 'package:args/command_runner.dart';

import 'commands/disable.dart';
import 'commands/enable.dart';
import 'commands/list.dart';
import 'commands/ntfy.dart';
import 'commands/remove.dart';
import 'commands/run.dart';
import 'commands/watch.dart';

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
  }
}
