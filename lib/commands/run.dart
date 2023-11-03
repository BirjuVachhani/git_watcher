import 'dart:io';

import 'package:ansi/ansi.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:screwdriver/screwdriver.dart';

import '../file_logger.dart';
import '../helpers.dart';
import '../ntfy_manager.dart';
import '../watchlist_manager.dart';

class RunCommand extends Command {
  @override
  String get description => 'Run all the watchers and notify with NTFY.';

  @override
  String get name => 'run';

  @override
  Future run() async {
    final Logger logger = Logger.standard();
    final WatchlistManager manager = WatchlistManager();
    final FileLogger fileLogger = FileLogger();

    await fileLogger.log('-' * 80);
    await fileLogger.log('Running at ${DateTime.now()}');
    await fileLogger.log('-' * 80);

    final items = await manager.get();

    if (items.isEmpty) {
      logger.stdout(grey('☑️ Watchlist is empty. Nothing to run.'));
      await fileLogger.log('Watchlist is empty. Nothing to run.');
      await fileLogger.log('-' * 80);
      return;
    }

    for (final item in items) {
      logger.stdout('-' * 80);
      await fileLogger.log('Processing ${item.url}...');

      if (!item.enabled) {
        logger.stdout(grey('☑️ ${item.url} is disabled. Skipping...'));
        await fileLogger.log('${item.url} is disabled. Skipping...');
        continue;
      }

      logger.stdout('Checking ${item.url}...');
      final Map<String, dynamic>? data =
          await getLatestCommitForFile(item.url, logger);

      if (data == null) {
        logger.stderr(red('Unable to load URL.'));
        await fileLogger.log('Unable to load URL.');
        continue;
      }

      // printLatestCommit(data, logger);

      final date = DateTime.tryParse(data['commit']['author']['date']);
      if (date == null) {
        logger.stderr(red('❌ Unable to process URL response.'));
        await fileLogger.log('Unable to process URL response.');
        continue;
      }

      if (item.lastModified >= date) {
        logger.stdout(blue('✅ Up to date.'));
        await fileLogger.log('Up to date.');
        continue;
      }

      logger.stdout(green('🔔 New commit found!'));
      await fileLogger.log('New commit found! Notifying...');
      final (success, reason) = await notify(item, data, logger);
      await fileLogger.log(reason);

      if (!success) {
        logger.stderr(red('❌ Unable to notify: $reason'));
        continue;
      } else {
        logger.stdout(green('✅ Successfully notified.'));
      }

      // update item in storage
      final updated = item.copyWith(lastModified: date);
      await manager.setItem(updated);
      logger.stdout(green('✅ Updated last modified date.'));
      await fileLogger.log('Updated last modified date.');
    }

    logger.stdout('-' * 80);
    await fileLogger.log('-' * 80);
    exit(0);
  }

  Future<(bool, String)> notify(
    WatchFile item,
    Map<String, dynamic> data,
    Logger logger,
  ) async {
    try {
      final manager = NtfyManager();

      final config = await manager.get();

      if (config == null) {
        return (
          false,
          'Ntfy URL is not set. Unable to notify. Run `gitwatcher ntfy set <url>` to set the URL.'
        );
      }

      final url = config.topicUrl;

      final info = parseGithubFileURL(item.url);

      final fileName = p.basename(info.path);

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Title': '${info.owner}/${info.repo}',
          'Actions':
              'view, View Commit, ${data['html_url']}, clear=true; view, View File, ${item.url}',
        },
        body: '$fileName has a new changes.',
      );

      if (response.statusCode != 200) {
        return (
          false,
          'Unable to notify to $url: ${response.statusCode}: ${response.reasonPhrase}'
        );
      }

      return (true, 'Successfully notified to $url.');
    } catch (error, stacktrace) {
      logger.stderr(red('Error: $error'));
      logger.stderr(red('Stacktrace: $stacktrace'));
      return (false, 'Exception while notifying: $error');
    }
  }
}
