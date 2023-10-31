import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'helpers.dart';

class NtfyManager {
  late final String path;

  late final file = File(path);

  NtfyManager({String path = 'ntfy.json'}) {
    final dir = p.dirname(p.join(getConfigDir().path, path));
    final baseName = p.basenameWithoutExtension(path);
    this.path = p.join(dir, '$baseName.json');
    if (!file.existsSync()) file.createSync(recursive: true);
    // stdout.writeln('Ntfy path: ${file.absolute.path}');
  }

  Future<NtfyConfig?> get() async {
    final content = await file.readAsString();
    if (content.isEmpty) return null;
    final data = jsonDecode(content) as Map<String, dynamic>?;
    if (data == null) return null;
    return NtfyConfig.fromJson(data);
  }

  Future<bool> hasUrl() async {
    final config = await get();
    return config?.topicUrl != null;
  }

  Future<void> set(String topicUrl) async {
    return setConfig(NtfyConfig(topicUrl: topicUrl));
  }

  Future<void> setConfig(NtfyConfig config) async {
    await file.writeAsString(jsonEncode(config.toJson()));
  }

  Future<String> read() async => await file.readAsString();

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
