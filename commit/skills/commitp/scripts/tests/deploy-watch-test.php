<?php

/*
 * Tests for deploy-watch.php against a fake Forge API (fake-forge.php).
 * Run: php commit/skills/commitp/scripts/tests/deploy-watch-test.php (from the marketplace repository root)
 * Exits 0 when every test passes, 1 otherwise.
 */

$script = dirname(__DIR__).'/deploy-watch.php';
$router = __DIR__.'/fake-forge.php';
$failures = 0;

function check(bool $ok, string $what, string $detail = ''): void
{
    global $failures;
    echo ($ok ? 'PASS ' : 'FAIL ').$what.($ok || $detail === '' ? '' : "\n".$detail)."\n";
    $failures += $ok ? 0 : 1;
}

function run(string $cmd, string $cwd, array $env): array
{
    $proc = proc_open($cmd, [1 => ['pipe', 'w'], 2 => ['pipe', 'w']], $pipes, $cwd, $env);
    $out = stream_get_contents($pipes[1]).stream_get_contents($pipes[2]);
    $code = proc_close($proc);

    return [$code, $out];
}

// A throwaway HOME with a Forge login, and a git repo whose origin is the repository the fake site deploys.
$tmp = sys_get_temp_dir().'/deploy-watch-test-'.getmypid();
$home = "{$tmp}/home";
$repo = "{$tmp}/repo";
mkdir("{$home}/.laravel-forge", 0777, true);
mkdir($repo, 0777, true);
file_put_contents("{$home}/.laravel-forge/config.json", json_encode(['token' => 'test-token', 'organization' => 'test-org']));
$git = fn (string $args) => trim((string) shell_exec('cd '.escapeshellarg($repo).' && git '.$args.' 2>&1'));
$git('init -q -b production');
$git('-c user.name=t -c user.email=t@example.test commit -q --allow-empty -m init');
$git('remote add origin git@github.com-alias:acme/widget.git');
$sha = $git('rev-parse HEAD');

// Start the fake Forge API on a free port.
$sock = stream_socket_server('tcp://127.0.0.1:0');
$port = (int) substr(strrchr(stream_socket_get_name($sock, false), ':'), 1);
fclose($sock);
$log = "{$tmp}/requests.log";
$serverEnv = ['FAKE_FORGE_LOG' => $log, 'FAKE_FORGE_SHA' => $sha, 'PATH' => getenv('PATH')];
$server = proc_open([PHP_BINARY, '-S', "127.0.0.1:{$port}", $router], [1 => ['file', '/dev/null', 'w'], 2 => ['file', '/dev/null', 'w']], $pipes, null, $serverEnv);
for ($i = 0; $i < 50 && ! @fsockopen('127.0.0.1', $port); $i++) {
    usleep(100000);
}

$env = ['HOME' => $home, 'PATH' => getenv('PATH'), 'FORGE_API_BASE' => "http://127.0.0.1:{$port}/api/"];
$cmd = escapeshellarg(PHP_BINARY).' '.escapeshellarg($script)." --sha={$sha} --branch=production --wait=5";
$cacheFile = "{$home}/.laravel-forge/deploy-watch-sites.json";
$siteCheck = '/api/orgs/test-org/sites/222';

try {
    // 1. No cached site: the watcher scans servers, saves the site, and watches the deployment.
    @unlink($log);
    [$code, $out] = run($cmd, $repo, $env);
    check($code === 0, 'uncached: exits 0', $out);
    check(str_contains($out, 'forge: deployed example.test'), 'uncached: reports the deployment', $out);
    $cache = json_decode((string) @file_get_contents($cacheFile), true) ?: [];
    check(($cache['test-org acme/widget production']['site'] ?? null) === 222, 'uncached: saves the site lookup', json_encode($cache));

    // 2. Cached site: the watcher checks the saved site with the organisation-scoped GET, not the
    //    server-scoped one that Forge answers with 405, and does not rescan the servers.
    @unlink($log);
    [$code, $out] = run($cmd, $repo, $env);
    $requests = file($log, FILE_IGNORE_NEW_LINES) ?: [];
    check($code === 0, 'cached: exits 0', $out);
    check(str_contains($out, 'forge: deployed example.test'), 'cached: reports the deployment', $out);
    check(in_array($siteCheck, $requests, true), 'cached: checks the site with orgs/{org}/sites/{site}', implode("\n", $requests));
    check(! in_array('/api/orgs/test-org/servers', $requests, true), 'cached: does not rescan the servers', implode("\n", $requests));
} finally {
    proc_terminate($server);
    proc_close($server);
    shell_exec('rm -rf '.escapeshellarg($tmp));
}

exit($failures === 0 ? 0 : 1);
