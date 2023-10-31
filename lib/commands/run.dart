import 'dart:io';

import 'package:ansi/ansi.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:screwdriver/screwdriver.dart';

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

    final items = await manager.get();

    if (items.isEmpty) {
      logger.stdout(grey('☑️ Watchlist is empty. Nothing to run.'));
      return;
    }

    for (final item in items) {
      logger.stdout('-' * 80);

      if (!item.enabled) {
        logger.stdout(grey('☑️ ${item.url} is disabled. Skipping...'));
        continue;
      }

      logger.stdout('Checking ${item.url}...');
      final Map<String, dynamic>? data =
          await getLatestCommitForFile(item.url, logger);

      if (data == null) {
        logger.stderr(red('Unable to load URL.'));
        continue;
      }

      // printLatestCommit(data, logger);

      final date = DateTime.tryParse(data['commit']['author']['date']);
      if (date == null) {
        logger.stderr(red('❌ Unable to process URL response.'));
        continue;
      }

      if (item.lastModified >= date) {
        logger.stdout(blue('✅ Up to date.'));
        continue;
      }

      logger.stdout(green('🔔 New commit found!'));
      await notify(item, data, logger);
    }

    logger.stdout('-' * 80);
    exit(0);
  }

  Future<void> notify(
    WatchFile item,
    Map<String, dynamic> data,
    Logger logger,
  ) async {
    try {
      final manager = NtfyManager();

      final config = await manager.get();

      if (config == null) {
        logger.stderr(red(
            'Ntfy URL is not set. Unable to notify. Run `gitwatcher ntfy set <url>` to set the URL.'));
        return;
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
        logger.stderr(red('❌ Unable to connect to $url.'));
        exit(1);
      }
    } catch (error, stacktrace) {
      logger.stderr(red('Error: $error'));
      logger.stderr(red('Stacktrace: $stacktrace'));
    }
  }
}
