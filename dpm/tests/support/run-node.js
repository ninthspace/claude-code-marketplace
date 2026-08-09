import { spawn } from 'node:child_process';

/**
 * Spawn a Node process and collect everything it wrote.
 *
 * Three earlier suites each carry a private copy of this function — `server.test.js`,
 * `spine-integration.test.js` and `naming.test.js`. They are identical and they belong to closed
 * epics, so they are not swept here; this is the fourth caller declining to become the fourth
 * copy. Consolidating the other three is noted on Epic 47-04's Story 6.
 *
 * The whole stream is buffered rather than sampled. Retro 35's lesson is that a verdict taken from
 * the first or last few lines of a process's output is a verdict about the sample.
 *
 * @param {string[]} args
 * @param {string} [input] Written to stdin, which is then closed.
 * @param {Record<string, string>} [env] Merged over the parent's environment.
 * @returns {Promise<{code: number, stdout: string, stderr: string}>}
 */
export function runNode(args, input = '', env = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(process.execPath, args, {
      stdio: ['pipe', 'pipe', 'pipe'],
      env: { ...process.env, ...env },
    });

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (chunk) => {
      stdout += chunk;
    });
    child.stderr.on('data', (chunk) => {
      stderr += chunk;
    });

    child.on('error', reject);
    child.on('close', (code) => resolve({ code, stdout, stderr }));

    child.stdin.end(input);
  });
}
