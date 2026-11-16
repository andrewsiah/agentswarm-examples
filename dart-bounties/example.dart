import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final rawBase = Platform.environment['AGENTSWARM_BASE_URL']?.trim();
  final base = (rawBase == null || rawBase.isEmpty
          ? 'https://agentswarm.space'
          : rawBase)
      .replaceFirst(RegExp(r'/+$'), '');

  final uri = Uri.tryParse('$base/api/bounties');
  if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
    stderr.writeln('HTTP error: invalid base URL $base');
    exit(1);
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
    stderr.writeln('HTTP request error: $error');
    exit(1);
  } finally {
    client.close(force: true);
  }

  if (status != 200) {
    stderr.writeln('HTTP error: status $status');
    exit(1);
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException catch (error) {
    stderr.writeln('JSON parse decode syntax error: ${error.message}');
    exit(1);
  } catch (error) {
    stderr.writeln('JSON decode error: $error');
    exit(1);
  }

  if (decoded is! Map<String, dynamic> || decoded['bounties'] is! List<dynamic>) {
    stderr.writeln('JSON decode error: missing or invalid bounties array');
    exit(1);
  }

  final bounties = decoded['bounties'] as List<dynamic>;
  final buffer = StringBuffer();
  for (final item in bounties) {
    if (item is! Map<String, dynamic>) {
      stderr.writeln('JSON decode error: invalid bounty row structure');
      exit(1);
    }
    if (item['status'] != 'open') {
      continue;
    }
    final id = item['id'];
    final title = item['title'];
    final bounty = item['bounty'];
    if (id is! String || id.isEmpty || title is! String || bounty is! Map<String, dynamic>) {
      stderr.writeln('JSON decode error: missing id, title or bounty object');
      exit(1);
    }
    final reward = bounty['reward'];
    if (reward is! String) {
      stderr.writeln('JSON decode error: missing reward string');
      exit(1);
    }
    buffer.write('$id\t$title\t$reward\t$base/p/$id\n');
  }

  stdout.write(buffer.toString());
  exit(0);
}
