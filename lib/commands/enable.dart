import 'package:ansi/ansi.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../helpers.dart';
import '../watchlist_manager.dart';

class EnableCommand extends Command {
  EnableCommand() {
    argParser
      ..addOption(
        'index',
        abbr: 'i',
        help: 'Index of the watcher to remove.',
      )
      ..addOption(
        'url',
        abbr: 'u',
        help: 'URL of the watcher to remove.',
      );
  }

  @override
  String get description => 'Remove a watcher from the watchlist.';

  @override
  String get name => 'enable';

  @override
  Future run() async {
    final Logger logger = Logger.standard();

    if (!argResults!.wasParsed('index') && !argResults!.wasParsed('url')) {
      logger.stderr(red(
          'Please specify an index using -i flag or a URL to enable using -u flag.'));
      return;
    }

    final int? index = int.tryParse(argResults!['index'].toString());
    final url = argResults!['url'];

    if (index != null && url != null) {
      logger.stderr(red('Please specify either an index or URL to enable.'));
      return;
    }

    final manager = WatchlistManager();

    final (WatchFile? item, String? error) result;
    if (index != null) {
      result = await manager.enableAt(index);
    } else {
      result = await manager.enable(url);
    }
    final (item, error) = result;

    if (item != null) {
      printWatchFile(item, index, logger, status: green('Enabled'));
      if (error != null) {
        logger.stdout(grey(error));
      }
    } else {
      logger.stderr(red(error!));
    }
  }
}
