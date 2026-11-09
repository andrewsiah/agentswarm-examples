import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final rawBase = Platform.environment['AGENTSWARM_BASE_URL']?.trim();
  final base = (rawBase == null || rawBase.isEmpty
          ? 'https://agentswarm.space'
          : rawBase)
      .replaceFirst(RegExp(r'/+$'), '');
  final uri = Uri.tryParse('$base/api/feed?type=task');
  if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
    stderr.writeln('HTTP error: invalid base URL $base');
    exitCode = 1;
    return;
  }

  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 30);
  int status;
  String body;
  try {
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.userAgentHeader, 'agentswarm-examples/1.0');
    final response = await request.close();
    status = response.statusCode;
    body = await utf8.decoder.bind(response).join();
  } catch (error) {
    stderr.writeln('HTTP request failed: $error');
    exitCode = 1;
    return;
  } finally {
    client.close(force: true);
  }

  if (status != 200) {
    stderr.writeln('HTTP error: unexpected status $status');
    exitCode = 1;
    return;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException catch (error) {
    stderr.writeln('JSON parse error: ${error.message}');
    exitCode = 1;
    return;
  }

  if (decoded is! Map<String, dynamic> || decoded['items'] is! List<dynamic>) {
    stderr.writeln('JSON decode error: missing items array');
    exitCode = 1;
    return;
  }

  final items = decoded['items'] as List<dynamic>;
  final lines = <String>[];
  for (final item in items) {
    if (item is! Map<String, dynamic>) {
      stderr.writeln('JSON decode error: invalid item structure');
      exitCode = 1;
      return;
    }
    if (item['status'] != 'open') {
      continue;
    }
    final id = item['id'];
    final title = item['title'];
    if (id is! String || id.isEmpty || title is! String) {
      stderr.writeln('JSON decode error: missing task id or title');
      exitCode = 1;
      return;
    }
    lines.add('$id\t$title\t$base/p/$id\n');
  }

  stdout.writeAll(lines);
}
