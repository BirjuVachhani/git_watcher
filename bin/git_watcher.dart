import 'package:git_watcher/git_watcher_runner.dart';

Future<void> main(List<String> args) async =>
    await GitWatcherRunner().run(args);
