import 'package:ansi/ansi.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../helpers.dart';
import '../watchlist_manager.dart';

class RemoveCommand extends Command {
  RemoveCommand() {
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
  String get name => 'remove';

  @override
  Future run() async {
    final Logger logger = Logger.standard();

    if (!argResults!.wasParsed('index') && !argResults!.wasParsed('url')) {
      logger.stderr(red(
          'Please specify an index using -i flag or a URL to remove using -u flag.'));
      return;
    }

    final int? index = int.tryParse(argResults!['index'].toString());
    final url = argResults!['url'];

    if (index != null && url != null) {
      logger.stderr(red('Please specify either an index or URL to remove.'));
      return;
    }

    final manager = WatchlistManager();

    if (index != null) {
      final (item, error) = await manager.removeAt(index);
      if (item != null) {
        printWatchFile(item, index, logger, status: red('Removed'));
        logger.stdout(green('✅ Removed watcher at index $index.'));
      } else {
        logger.stderr(red(error!));
      }
    } else {
      final (isSuccess, error) = await manager.remove(url);
      if (isSuccess) {
        logger.stdout(green('✅ Removed watcher with URL $url.'));
      } else {
        logger.stderr(red(error!));
      }
    }
  }
}
