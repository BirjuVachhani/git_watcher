import 'dart:convert';
import 'dart:io';

import 'package:ansi/ansi.dart';
import 'package:barbecue/barbecue.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'extensions.dart';
import 'watchlist_manager.dart';

/// Represents components of a Github file URL.
typedef GithubFileURL = ({
  String owner,
  String repo,
  String branch,
  String path
});

/// Retrieves the latest commit for the given Github file URL.
Future<Map<String, dynamic>?> getLatestCommitForFile(
    String url, Logger logger) async {
  try {
    final info = parseGithubFileURL(url);

    final String urlTemplate =
        'https://api.github.com/repos/{owner}/{repo}/commits?path={path_to_file}&sha={branch}';
    final apiUrl = urlTemplate
        .replaceAll('{owner}', info.owner)
        .replaceAll('{repo}', info.repo)
        .replaceAll('{branch}', info.branch)
        .replaceAll('{path_to_file}', info.path);

    logger.stdout(green('[GET] $apiUrl'));

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode != 200) {
      logger.stderr(
          red('Error: [${response.statusCode}]: ${response.reasonPhrase}'));
      return null;
    }

    return (jsonDecode(response.body) as List).first;
  } catch (error, stacktrace) {
    logger.stderr(red('Error: $error'));
    logger.stderr(red('Stacktrace: $stacktrace'));
    return null;
  }
}

/// Breaks down the Github file URL into its components.
GithubFileURL parseGithubFileURL(String url) {
  final Uri uri = Uri.parse(url);
  final [owner, repo, ...pathSegments] = uri.pathSegments;
  pathSegments.remove('blob');
  final branch = pathSegments.removeAt(0);
  final path = pathSegments.join('/');
  return (owner: owner, repo: repo, branch: branch, path: path);
}

/// Prints the watch item in a table format.
void printWatchFile(WatchFile item, int? index, Logger logger,
    {String? status}) {
  final table = Table(
    tableStyle: TableStyle(border: true, borderStyle: BorderStyle.Solid),
    header: TableSection(
      cellStyle: CellStyle(
        paddingRight: 4,
        paddingLeft: 1,
        borderRight: true,
        borderBottom: true,
      ),
      rows: [
        Row(cells: [
          if (index != null) Cell('Index'),
          Cell('Status'),
          Cell('Last Updated'),
          Cell('URL'),
        ])
      ],
    ),
    body: TableSection(
      cellStyle: CellStyle(
        paddingRight: 4,
        paddingLeft: 1,
        borderRight: true,
        borderBottom: true,
      ),
      rows: [
        Row(
          cells: [
            if (index != null) Cell('$index'),
            Cell(status ?? (item.enabled ? 'Enabled' : 'Disabled')),
            Cell(
                DateFormat('dd MMM yyyy hh:mm:ss a').format(item.lastModified)),
            Cell(blue(item.url)),
          ],
        )
      ],
    ),
  );

  print(table.render());
}

/// Returns the home directory for the current user.
Directory getHomeDir() {
  String? home;
  Map<String, String> envVars = Platform.environment;
  if (Platform.isMacOS) {
    home = envVars['HOME'];
  } else if (Platform.isLinux) {
    home = envVars['HOME'];
  } else if (Platform.isWindows) {
    home = envVars['UserProfile'];
  } else {
    throw Exception('Unsupported platform.');
  }
  if (home == null) {
    throw Exception('Could not find home directory.');
  }
  return Directory(home);
}

/// Returns the config directory for the current user.
/// Creates the directory if it does not exist.
/// The config directory is located at `~/.git_watcher`.
Directory getConfigDir() {
  final homeDir = getHomeDir();
  final configDir = Directory('${homeDir.path}/.git_watcher');
  if (!configDir.existsSync()) {
    configDir.createSync();
  }
  return configDir;
}

void printGithubURLInfo(GithubFileURL info) {
  final table = Table(
    tableStyle: TableStyle(border: true, borderStyle: BorderStyle.Solid),
    body: TableSection(
      cellStyle: CellStyle(
          paddingRight: 4,
          paddingLeft: 1,
          borderRight: true,
          borderBottom: true),
      rows: [
        Row(cells: [Cell('Owner'), Cell(green(info.owner))]),
        Row(cells: [Cell('Repository'), Cell(green(info.repo))]),
        Row(cells: [Cell('Branch'), Cell(green(info.branch))]),
        Row(cells: [Cell('File'), Cell(green(info.path))]),
      ],
    ),
  );

  print(table.render());
}

void printLatestCommit(Map<String, dynamic> data, Logger logger) {
  logger.stdout(blue('Latest Commit'));
  final date = DateTime.tryParse(data['commit']['author']['date'])?.toLocal();
  final duration = date != null ? DateTime.now().difference(date) : null;
  final String timeAgo = duration != null ? '${duration.prettify()} ago' : '';
  final table = Table(
    tableStyle: TableStyle(border: true, borderStyle: BorderStyle.Solid),
    body: TableSection(
      cellStyle: CellStyle(
          paddingRight: 4,
          paddingLeft: 1,
          borderRight: true,
          borderBottom: true),
      rows: [
        Row(cells: [Cell('SHA'), Cell(blue(data['sha']))]),
        Row(cells: [
          Cell('Author'),
          Cell(blue(data['commit']['author']['name']))
        ]),
        Row(cells: [
          Cell('Date'),
          Cell(blue('${data['commit']['author']['date']} ($timeAgo)'))
        ]),
        Row(cells: [Cell('Message'), Cell(blue(data['commit']['message']))]),
        Row(cells: [Cell('URL'), Cell(blue(data['html_url']))]),
      ],
    ),
  );

  print(table.render());
}
