<?php

/*
 * Router for `php -S` that answers the Forge API requests deploy-watch.php makes.
 * Mirrors the real API's behaviour that broke the cached-site path: a GET of one site under a
 * server (orgs/{org}/servers/{server}/sites/{site}) returns 405; only orgs/{org}/sites/{site} answers.
 * Every request path is appended to $FAKE_FORGE_LOG so tests can assert which endpoints were used.
 */

$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
file_put_contents(getenv('FAKE_FORGE_LOG'), $path."\n", FILE_APPEND);
header('Content-Type: application/json');

$org = 'test-org';
$server = 111;
$site = 222;
$sha = getenv('FAKE_FORGE_SHA');
$siteAttributes = [
    'name' => 'example.test',
    'quick_deploy' => true,
    'repository' => ['url' => 'https://github.com/acme/widget', 'branch' => 'production'],
];
$deployment = [
    'id' => '333',
    'type' => 'deployments',
    'attributes' => [
        'commit' => ['hash' => $sha, 'branch' => 'production'],
        'status' => 'finished',
        'started_at' => '2026-11-13T10:00:00.000000Z',
        'ended_at' => '2026-11-13T10:00:12.000000Z',
    ],
];
$page = fn (array $data) => ['data' => $data, 'links' => [], 'meta' => ['next_cursor' => null]];

$routes = [
    "/api/orgs/{$org}/servers" => fn () => $page([['id' => (string) $server, 'type' => 'servers', 'attributes' => ['name' => 'web']]]),
    "/api/orgs/{$org}/servers/{$server}/sites" => fn () => $page([['id' => (string) $site, 'type' => 'sites', 'attributes' => $siteAttributes]]),
    "/api/orgs/{$org}/sites/{$site}" => fn () => ['data' => ['id' => (string) $site, 'type' => 'sites', 'attributes' => $siteAttributes]],
    "/api/orgs/{$org}/servers/{$server}/sites/{$site}/deployments" => fn () => $page([$deployment]),
    "/api/orgs/{$org}/servers/{$server}/sites/{$site}/deployments/333" => fn () => ['data' => $deployment],
    "/api/orgs/{$org}/servers/{$server}/sites/{$site}/deployments/333/log" => fn () => ['data' => ['attributes' => ['output' => "Fetching\nDeployment complete"]]],
];

if ($path === "/api/orgs/{$org}/servers/{$server}/sites/{$site}") {
    http_response_code(405);
    echo json_encode(['message' => 'The GET method is not supported for this route.']);

    return true;
}

if (! isset($routes[$path])) {
    http_response_code(404);
    echo json_encode(['message' => 'Not found']);

    return true;
}

echo json_encode($routes[$path]());

return true;
