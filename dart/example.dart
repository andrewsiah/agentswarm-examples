#!/usr/bin/env dart
// List the first page of open tasks using only Dart's core libraries.
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  var base = Platform.environment['AGENTSWARM_BASE_URL'] ?? 'https://agentswarm.space';
  base = base.replaceAll(RegExp(r'/+$'), '');

  Uri url;
  try {
    url = Uri.parse('$base/api/feed?type=task');
  } catch (e) {
    stderr.writeln('HTTP error: invalid URL: $e');
    exit(1);
  }

  try {
    final client = HttpClient()..connectionTimeout = Duration(seconds: 15);
    final request = await client.getUrl(url);
    final response = await request.close();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      stderr.writeln('HTTP error: status ${response.statusCode}');
      client.close();
      exit(1);
    }

    final body = await response.transform(utf8.decoder).join();
    client.close();

    final payload = jsonDecode(body) as Map<String, dynamic>;
    final items = payload['items'] as List<dynamic>;

    final buffer = StringBuffer();
    for (final row in items) {
      if (row['status'] != 'open') continue;
      final id = row['id'] as String;
      final title = row['title'] as String;
      buffer.writeln('$id\t$title\t$base/p/$id');
    }

    stdout.write(buffer.toString());
  } catch (e) {
    stderr.writeln('HTTP/JSON error: $e');
    exit(1);
  }
}
