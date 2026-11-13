#!/usr/bin/env php
<?php

/*
 * Watch the push-to-deploy deployment that a git push starts, on Laravel Forge or Laravel Cloud.
 *
 * Usage: deploy-watch.php [--sha=<sha>] [--branch=<branch>] [--remote=<name>] [--wait=<seconds>]
 *   Run from inside the git repository. Defaults: HEAD, the current branch, origin, 90 seconds.
 *
 * Forge: reads the token and organisation from ~/.laravel-forge/config.json (written by `forge login`).
 * Finds the site whose repository and branch match the pushed remote and branch, waits for the
 * deployment whose commit hash equals the pushed SHA, then prints its status changes and new log lines
 * until it ends. Site lookups are cached in ~/.laravel-forge/deploy-watch-sites.json.
 *
 * Cloud: used when no Forge site matches. Finds the application whose repository matches and the
 * environment that deploys the branch with push-to-deploy on, then runs `cloud deploy:monitor -n` for it.
 * It never runs deploy:monitor without a matched application, because that command offers to ship
 * a new application when it finds none.
 *
 * One line per event, so it suits the Claude Code Monitor tool.
 *
 * Exit codes: 0 finished, 1 deployment failed or cancelled, 2 nothing deploys this repo and branch on
 * push, 3 no deployment for the commit appeared within --wait, 4 configuration or API error.
 */

// FORGE_API_BASE points the script at a fake Forge API in tests (the Forge CLI reads the same variable).
define('API', getenv('FORGE_API_BASE') ?: 'https://forge.laravel.com/api/');
const POLL_SECONDS = 4;
const TERMINAL_FAILED = ['failed', 'failed-build', 'cancelled'];

$opts = getopt('', ['sha:', 'branch:', 'remote:', 'wait:']);

function out(string $line): void
{
    fwrite(STDOUT, $line."\n");
    fflush(STDOUT);
}

function fail(int $code, string $message): never
{
    out($message);
    exit($code);
}

function git(string $args): string
{
    return trim((string) shell_exec('git '.$args.' 2>/dev/null'));
}

/** owner/repo, so SSH host aliases (git@github.com-work:owner/repo) match Forge's https URL. */
function normaliseRepo(string $url): string
{
    $url = preg_replace('#\.git$#', '', rtrim(trim($url), '/'));
    $parts = preg_split('#[/:]#', $url);

    return count($parts) >= 2 ? strtolower(implode('/', array_slice($parts, -2))) : '';
}

function api(string $token, string $path): ?array
{
    $ch = curl_init(API.$path);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 20,
        CURLOPT_HTTPHEADER => ['Authorization: Bearer '.$token, 'Accept: application/json'],
    ]);
    $body = curl_exec($ch);
    $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);

    if ($status === 404) {
        return null;
    }
    if ($status === 429) {
        sleep(15);

        return api($token, $path);
    }
    if ($body === false || $status >= 400) {
        throw new RuntimeException("Forge API {$status} on {$path}");
    }

    return json_decode($body, true);
}

/** Every item of a cursor-paginated listing. */
function apiAll(string $token, string $path): array
{
    $items = [];
    $cursor = null;
    do {
        $sep = str_contains($path, '?') ? '&' : '?';
        $page = api($token, $path.$sep.'page%5Bsize%5D=100'.($cursor ? '&page%5Bcursor%5D='.urlencode($cursor) : '')) ?? [];
        array_push($items, ...($page['data'] ?? []));
        $cursor = $page['meta']['next_cursor'] ?? null;
    } while ($cursor);

    return $items;
}

/** Watch a Laravel Cloud push-to-deploy deployment; returns null when Cloud does not deploy this repo and branch. */
function cloudWatch(string $repo, string $branch): ?int
{
    if (trim((string) shell_exec('command -v cloud')) === '') {
        return null;
    }
    $apps = json_decode((string) shell_exec('cloud app:list --json -n 2>/dev/null'), true);
    $apps = $apps['data'] ?? $apps ?? [];
    $app = null;
    foreach ((array) $apps as $a) {
        if (strtolower($a['repositoryFullName'] ?? '') === $repo) {
            $app = $a;
            break;
        }
    }
    if (! $app) {
        return null;
    }

    $envs = json_decode((string) shell_exec('cloud environment:list '.escapeshellarg($app['id']).' --json -n 2>/dev/null'), true);
    $envs = $envs['data'] ?? $envs ?? [];
    $matches = array_values(array_filter((array) $envs, fn ($e) => ($e['branch'] ?? '') === $branch));
    if (! $matches) {
        return null;
    }
    $env = $matches[0];
    if (count($matches) > 1) {
        out("cloud: more than one environment of {$app['name']} deploys {$branch}; watching {$env['name']}");
    }
    if (! ($env['usesPushToDeploy'] ?? false)) {
        out("cloud: {$app['name']} {$env['name']} has push-to-deploy off, so the push did not start a deployment");

        return 2;
    }

    out("cloud: waiting for {$app['name']} {$env['name']} to deploy");
    $cmd = 'cloud deploy:monitor '.escapeshellarg($app['id']).' '.escapeshellarg($env['id']).' -n 2>&1';
    $proc = popen($cmd, 'r');
    $last = null;
    while (($line = fgets($proc)) !== false) {
        $event = json_decode(trim($line), true);
        if (is_array($event) && isset($event['status'])) {
            $last = $event['status'];
            out("cloud: deployment {$event['deployment_id']} {$event['status']} ({$event['message']})");
        } elseif (trim($line) !== '') {
            out('  '.rtrim(preg_replace('/\e\[[0-9;]*[A-Za-z]/', '', $line)));
        }
    }
    $code = pclose($proc);

    if ($last === null) {
        out("cloud: no deployment of {$app['name']} {$env['name']} started");

        return 3;
    }
    if (in_array($last, ['build.failed', 'deployment.failed', 'failed', 'cancelled'], true) || $code !== 0) {
        out("cloud: FAILED {$app['name']} {$env['name']} ({$last})");

        return 1;
    }
    out("cloud: deployed {$app['name']} {$env['name']}");

    return 0;
}

$remote = $opts['remote'] ?? 'origin';
$branch = $opts['branch'] ?? git('rev-parse --abbrev-ref HEAD');
$sha = $opts['sha'] ?? git('rev-parse HEAD');
$repo = normaliseRepo(git("remote get-url {$remote}"));
$wait = (int) ($opts['wait'] ?? 90);
if ($repo === '' || $sha === '' || $branch === '') {
    fail(4, 'deploy-watch: run from inside a git repository with a remote');
}

/** Hand over to Laravel Cloud, or report that nothing deploys this repo and branch. */
function noForgeSite(string $repo, string $branch): never
{
    $code = cloudWatch($repo, $branch);
    if ($code === null) {
        fail(2, "deploy-watch: neither Forge nor Cloud deploys {$repo} ({$branch}) on push");
    }
    exit($code);
}

$home = getenv('HOME');
$config = json_decode((string) @file_get_contents("{$home}/.laravel-forge/config.json"), true) ?: [];
$token = $config['token'] ?? null;
$org = $config['organization'] ?? null;
if (! $token || ! $org) {
    noForgeSite($repo, $branch);
}

$cacheFile = "{$home}/.laravel-forge/deploy-watch-sites.json";
$cache = json_decode((string) @file_get_contents($cacheFile), true) ?: [];
$key = "{$org} {$repo} {$branch}";

try {
    $target = $cache[$key] ?? null;

    // A repo with no Forge site is remembered for a day, so pushes from it do not rescan every server.
    if (($target['none_until'] ?? 0) > time()) {
        noForgeSite($repo, $branch);
    }
    if (isset($target['none_until'])) {
        $target = null;
    }

    // Drop a cached site that no longer exists or no longer deploys this repo and branch.
    if ($target) {
        // The server-scoped GET of a single site returns 405; only the organisation-scoped one exists.
        $site = api($token, "orgs/{$org}/sites/{$target['site']}");
        $a = $site['data']['attributes'] ?? [];
        if (! $site || normaliseRepo($a['repository']['url'] ?? '') !== $repo || ($a['repository']['branch'] ?? '') !== $branch) {
            $target = null;
        } else {
            $target['quick_deploy'] = (bool) ($a['quick_deploy'] ?? false);
        }
    }

    if (! $target) {
        foreach (apiAll($token, "orgs/{$org}/servers") as $server) {
            foreach (apiAll($token, "orgs/{$org}/servers/{$server['id']}/sites") as $site) {
                $a = $site['attributes'];
                if (normaliseRepo($a['repository']['url'] ?? '') === $repo && ($a['repository']['branch'] ?? '') === $branch) {
                    $target = ['server' => (int) $server['id'], 'site' => (int) $site['id'], 'name' => $a['name'], 'quick_deploy' => (bool) $a['quick_deploy']];
                    break 2;
                }
            }
        }
        $cache[$key] = $target ?? ['none_until' => time() + 86400];
        @file_put_contents($cacheFile, json_encode($cache, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
        if (! $target) {
            noForgeSite($repo, $branch);
        }
    }

    if (! $target['quick_deploy']) {
        fail(2, "forge: {$target['name']} has push-to-deploy off, so the push did not start a deployment");
    }

    $base = "orgs/{$org}/servers/{$target['server']}/sites/{$target['site']}";
    $short = substr($sha, 0, 7);
    out("forge: waiting for {$target['name']} to deploy {$short}");

    // Wait for the deployment of this commit to appear.
    $deployment = null;
    $deadline = time() + $wait;
    while (! $deployment && time() <= $deadline) {
        foreach ((api($token, "{$base}/deployments?sort=-created_at&page%5Bsize%5D=5") ?? [])['data'] ?? [] as $d) {
            if (($d['attributes']['commit']['hash'] ?? '') === $sha) {
                $deployment = $d;
                break;
            }
        }
        if (! $deployment) {
            sleep(POLL_SECONDS);
        }
    }
    if (! $deployment) {
        fail(3, "forge: no deployment of {$short} appeared on {$target['name']} within {$wait}s");
    }

    $id = $deployment['id'];
    $lastStatus = null;
    $printedLines = 0;
    while (true) {
        $status = $deployment['attributes']['status'];
        if ($status !== $lastStatus) {
            out("forge: deployment {$id} {$status}");
            $lastStatus = $status;
        }

        $done = ! in_array($status, ['pending', 'queued', 'deploying'], true);

        if ($status === 'deploying' || $done) {
            $log = api($token, "{$base}/deployments/{$id}/log")['data']['attributes']['output'] ?? '';
            $lines = preg_split('/\r?\n/', rtrim($log));
            $lines = $lines === [''] ? [] : $lines;
            foreach (array_slice($lines, $printedLines) as $line) {
                $line = rtrim(preg_replace('/\e\[[0-9;]*[A-Za-z]/', '', $line));
                $line = preg_replace('/\s*\.{4,}\s*/', ' … ', $line);
                if ($line !== '') {
                    out('  '.$line);
                }
            }
            $printedLines = max($printedLines, count($lines));
        }

        if ($done) {
            $a = $deployment['attributes'];
            $secs = ($a['started_at'] && $a['ended_at']) ? strtotime($a['ended_at']) - strtotime($a['started_at']) : null;
            if (in_array($status, TERMINAL_FAILED, true)) {
                fail(1, "forge: FAILED {$target['name']} {$short} ({$status})");
            }
            out("forge: deployed {$target['name']} {$short}".($secs !== null ? " in {$secs}s" : ''));
            exit(0);
        }

        sleep(POLL_SECONDS);
        $deployment = api($token, "{$base}/deployments/{$id}")['data'] ?? $deployment;
    }
} catch (Throwable $e) {
    fail(4, 'forge: '.$e->getMessage());
}
