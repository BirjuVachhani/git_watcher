import 'dart:convert';
import 'dart:io';

import 'package:ansi/ansi.dart';
import 'package:args/command_runner.dart';
import 'package:barbecue/barbecue.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:intl/intl.dart';

import '../watchlist_manager.dart';

class ListCommand extends Command {
  ListCommand() {
    argParser.addFlag('json', abbr: 'j', help: 'Print the output as JSON.');
  }

  @override
  String get description => 'List all the watchers from the watchlist.';

  @override
  String get name => 'list';

  @override
  List<String> get aliases => const ['status', 'ls'];

  @override
  Future run() async {
    final Logger logger = Logger.standard();

    final manager = WatchlistManager();

    if (argResults!.wasParsed('json') && argResults!['json'] == true) {
      final content = await manager.read();
      logger.stdout(JsonEncoder.withIndent('  ').convert(jsonDecode(content)));
      exit(0);
    }

    final items = await manager.get();
    if (items.isEmpty) {
      logger.stdout(
          blue('Watchlist is empty. Add some watchers using `watch` command.'));
      return;
    }
    printList(items, logger);
  }

  void printList(List<WatchFile> items, Logger logger) {
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
            Cell('Index'),
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
          for (final (index, item) in items.indexed)
            Row(
              cells: [
                Cell('$index'),
                Cell(item.enabled ? green('Enabled') : red('Disabled')),
                Cell(DateFormat('dd MMM yyyy hh:mm a')
                    .format(item.lastModified)),
                Cell(blue(item.url)),
              ],
            ),
        ],
      ),
    );

    print(table.render());
  }
}
