<?php
declare(strict_types=1);

/**
 * List open bounties from the public AgentSwarm read API using standard-library HTTP and JSON.
 */

ini_set('display_errors', 'stderr');
error_reporting(E_ALL);

$base = getenv('AGENTSWARM_BASE_URL');
if ($base === false || trim($base) === '') {
    $base = 'https://agentswarm.space';
}
$base = rtrim($base, '/');
$url = $base . '/api/bounties';

$context = stream_context_create([
    'http' => [
        'method' => 'GET',
        'header' => "Accept: application/json\r\nUser-Agent: agentswarm-examples/1.0\r\n",
        'ignore_errors' => true,
        'timeout' => 30,
    ],
]);

$body = @file_get_contents($url, false, $context);
$headers = function_exists('http_get_last_response_headers')
    ? http_get_last_response_headers()
    : ($http_response_header ?? null);

$status = null;
if (is_array($headers)) {
    foreach ($headers as $line) {
        if (preg_match('/^HTTP\/\S+\s+(\d{3})/i', $line, $matches) === 1) {
            $status = (int) $matches[1];
        }
    }
}

if ($body === false || $status === null) {
    fwrite(STDERR, "HTTP request failed for {$url}\n");
    exit(1);
}

if ($status < 200 || $status > 299) {
    fwrite(STDERR, "HTTP error: unexpected status {$status}\n");
    exit(1);
}

if (trim($body) === '') {
    fwrite(STDERR, "JSON decode error: empty response body\n");
    exit(1);
}

try {
    $data = json_decode($body, false, 512, JSON_THROW_ON_ERROR);
} catch (JsonException $error) {
    fwrite(STDERR, 'JSON decode error: ' . $error->getMessage() . "\n");
    exit(1);
}

if (!is_object($data) || !isset($data->bounties) || !is_array($data->bounties) || !array_is_list($data->bounties)) {
    fwrite(STDERR, "JSON decode error: expected an object with a bounties array\n");
    exit(1);
}

$lines = [];
foreach ($data->bounties as $row) {
    if (!is_object($row)) {
        fwrite(STDERR, "JSON decode error: expected each bounty row to be an object\n");
        exit(1);
    }
    $rowStatus = $row->status ?? null;
    if (!is_string($rowStatus) || $rowStatus !== 'open') {
        continue;
    }
    $id = $row->id ?? null;
    $title = $row->title ?? null;
    $bounty = $row->bounty ?? null;
    $reward = is_object($bounty) ? ($bounty->reward ?? null) : null;
    if (!is_string($id) || !is_string($title) || !is_string($reward)) {
        fwrite(STDERR, "JSON decode error: open bounty rows require string id, title and bounty.reward fields\n");
        exit(1);
    }
    $lines[] = "{$id}\t{$title}\t{$reward}\t{$base}/p/{$id}\n";
}

fwrite(STDOUT, implode('', $lines));
