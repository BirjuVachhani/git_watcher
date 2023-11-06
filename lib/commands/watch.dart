import 'dart:io';

import 'package:ansi/ansi.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:http/http.dart' as http;

import '../helpers.dart';
import '../watchlist_manager.dart';

class WatchCommand extends Command {
  WatchCommand() {
    argParser
      ..addFlag(
        'verbose',
        abbr: 'v',
        negatable: false,
        help: 'Increase logging.',
        defaultsTo: false,
      )
      ..addOption(
        'file',
        abbr: 'f',
        help: 'URL of the file to watch for changes.',
      );
  }

  @override
  String get description =>
      'Watch files on git repositories and notify with NTFY.';

  @override
  String get name => 'watch';

  @override
  Future run() async {
    final verbose = argResults!.wasParsed('verbose');
    final logger = verbose ? Logger.verbose() : Logger.standard();

    if (!argResults!.wasParsed('file')) {
      logger.stderr(red('Please specify a file to watch.'));
      exit(1);
    }
    final String? fileUrl = argResults!['file'];

    final progress = logger.progress('Validating Github file URL...');

    final (isValid, reason) = await validateGithubFileURL(fileUrl!);
    if (!isValid) {
      progress.cancel();
      logger.stderr(red(reason!));
      exit(1);
    }

    progress.finish(message: '✅done.');

    final manager = WatchlistManager();

    if (await manager.hasUrl(fileUrl)) {
      logger.stderr(red('URL is already in watchlist.'));
      exit(1);
    }

    final info = parseGithubFileURL(fileUrl);

    printGithubURLInfo(info);

    logger.stdout('Getting latest commit...');

    final Map<String, dynamic>? data =
        await getLatestCommitForFile(fileUrl, logger);

    if (data == null) {
      logger.stderr(red('Could not get latest commit for file.'));
      exit(1);
    }

    printLatestCommit(data, logger);

    final date = DateTime.tryParse(data['commit']['author']['date'])?.toLocal();

    if (date == null) {
      logger.stderr(red('Could not parse date.'));
      exit(1);
    }

    final item = WatchFile(url: fileUrl, lastModified: date);

    final (added, error) = await manager.addItem(item);

    if (!added) {
      logger.stderr(red(error!));
      exit(1);
    }

    logger.stdout(green('✅ Added to watchlist: $fileUrl'));
  }

  Future<(bool, String?)> validateGithubFileURL(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return (false, 'Invalid URL.');
    if (uri.host != 'github.com') return (false, 'Not a Github URL.');
    if (uri.pathSegments.length < 3) return (false, 'Not a Github file URL.');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return (
        false,
        'Incorrect URL: [${response.statusCode}]: ${response.reasonPhrase}'
      );
    }

    return (true, null);
  }
}
