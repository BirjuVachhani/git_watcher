import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'helpers.dart';

class WatchlistManager {
  late final String path;

  late final file = File(path);

  WatchlistManager({String path = 'watchlist.json'}) {
    final dir = p.dirname(p.join(getConfigDir().path, path));
    final baseName = p.basenameWithoutExtension(path);
    this.path = p.join(dir, '$baseName.json');
    if (!file.existsSync()) file.createSync(recursive: true);
    // stdout.writeln('Watchlist path: ${file.absolute.path}');
  }

  Future<List<WatchFile>> get() async {
    final content = await file.readAsString();
    if (content.isEmpty) return [];
    final items = jsonDecode(content) as List;
    return items
        .map((item) => WatchFile.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<bool> hasUrl(String url) async {
    final items = await get();
    return items.any((item) => item.url == url);
  }

  Future<(bool, String?)> add(String url, DateTime lastModified) async {
    return addItem(WatchFile(url: url, lastModified: lastModified));
  }

  Future<(bool, String?)> addItem(WatchFile item) async {
    final items = await get();
    final exists = items.any((element) => element.url == item.url);
    if (exists) return (false, 'URL already exists in watchlist.');
    items.add(item);
    await file.writeAsString(jsonEncode(items));
    return (true, null);
  }

  Future<(bool, String?)> remove(String url) async {
    final items = await get();
    final length = items.length;
    items.removeWhere((item) => item.url == url);
    final bool removed = items.length != length;
    await file.writeAsString(jsonEncode(items));
    return (removed, removed ? null : 'URL not found in watchlist.');
  }

  Future<(WatchFile?, String?)> removeAt(int index) async {
    final items = await get();
    final length = items.length;
    if (index < 0 || index >= length) return (null, 'Invalid index.');
    final removed = items.removeAt(index);
    await file.writeAsString(jsonEncode(items));
    return (removed, null);
  }

  Future<(WatchFile?, String?)> enable(String url) async {
    final items = await get();
    final index = items.indexWhere((item) => item.url == url);
    if (index == -1) return (null, 'URL not found in watchlist.');

    if (items[index].enabled) return (items[index], 'Already enabled.');

    items[index] = items[index].copyWith(enabled: true);
    await file.writeAsString(jsonEncode(items));
    return (items[index], null);
  }

  Future<(WatchFile?, String?)> enableAt(int index) async {
    final items = await get();
    if (index < 0 || index >= items.length) {
      return (null, 'Invalid index.');
    }

    if (items[index].enabled) return (items[index], 'Already enabled.');

    items[index] = items[index].copyWith(enabled: true);
    await file.writeAsString(jsonEncode(items));
    return (items[index], null);
  }

  Future<(WatchFile?, String?)> disable(String url) async {
    final items = await get();
    final index = items.indexWhere((item) => item.url == url);
    if (index == -1) return (null, 'URL not found in watchlist.');

    if (!items[index].enabled) return (items[index], 'Already disabled.');

    items[index] = items[index].copyWith(enabled: false);
    await file.writeAsString(jsonEncode(items));
    return (items[index], null);
  }

  Future<(WatchFile?, String?)> disableAt(int index) async {
    final items = await get();
    if (index < 0 || index >= items.length) {
      return (null, 'Invalid index.');
    }

    if (!items[index].enabled) return (items[index], 'Already disabled.');

    items[index] = items[index].copyWith(enabled: false);
    await file.writeAsString(jsonEncode(items));
    return (items[index], null);
  }

  Future<String> read() async => await file.readAsString();

  Future<void> clear() async {
    await file.writeAsString(jsonEncode([]));
  }
}

class WatchFile {
  final String url;
  final DateTime lastModified;
  final bool enabled;

  WatchFile({
    required this.url,
    required this.lastModified,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'lastModified': lastModified.millisecondsSinceEpoch,
        'enabled': enabled,
      };

  factory WatchFile.fromJson(Map<String, dynamic> json) => WatchFile(
        url: json['url'] as String,
        lastModified:
            DateTime.fromMillisecondsSinceEpoch(json['lastModified'] as int),
        enabled: json['enabled'] as bool? ?? true,
      );

  WatchFile copyWith({
    String? url,
    DateTime? lastModified,
    bool? enabled,
  }) {
    return WatchFile(
      url: url ?? this.url,
      lastModified: lastModified ?? this.lastModified,
      enabled: enabled ?? this.enabled,
    );
  }
}
