import 'dart:io';

import 'package:path/path.dart' as p;

import 'helpers.dart';

class FileLogger {
  late final String path;

  late final file = File(path);

  FileLogger({String path = 'logs.txt'}) {
    final dir = p.dirname(p.join(getConfigDir().path, path));
    final baseName = p.basenameWithoutExtension(path);
    this.path = p.join(dir, '$baseName.txt');
    if (!file.existsSync()) file.createSync(recursive: true);
    // stdout.writeln('Ntfy path: ${file.absolute.path}');
  }

  Future<String> read() async => await file.readAsString();

  Future<void> log(String message) async {
    final sink = file.openWrite(mode: FileMode.append);
    sink.writeln(message);
    await sink.flush();
    await sink.close();
  }

  Future<void> clear() async {
    await file.writeAsString('');
  }
}

class NtfyConfig {
  final String topicUrl;

  NtfyConfig({
    required this.topicUrl,
  });

  Map<String, dynamic> toJson() => {'topicUrl': topicUrl};

  factory NtfyConfig.fromJson(Map<String, dynamic> json) => NtfyConfig(
        topicUrl: json['topicUrl'] as String,
      );

  NtfyConfig copyWith({String? topicUrl}) {
    return NtfyConfig(topicUrl: topicUrl ?? this.topicUrl);
  }
}
