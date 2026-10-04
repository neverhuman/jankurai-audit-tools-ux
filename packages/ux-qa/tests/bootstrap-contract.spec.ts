import { expect, test } from "@playwright/test";
import { execFile } from "node:child_process";
import { copyFile, mkdir, readFile, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";

const repoRoot = fileURLToPath(new URL("../../..", import.meta.url));
const checkScript = `${repoRoot}ops/ci/check-bootstrap.sh`;
const hint = "run ops/ci/bootstrap.sh";

// Run ops/ci/check-bootstrap.sh against an arbitrary REPO_ROOT so the offline
// verification the required lane relies on can be exercised without network.
async function check(
  env: Record<string, string>,
): Promise<{ code: number; stderr: string }> {
  try {
    await promisify(execFile)("bash", [checkScript], {
      env: { ...process.env, ...env },
    });
    return { code: 0, stderr: "" };
  } catch (error) {
    const failure = error as { code?: number; stderr?: string };
    return { code: failure.code ?? 1, stderr: failure.stderr ?? "" };
  }
}

// A scratch checkout that borrows this repo's node_modules (so playwright-core
// resolves) but owns its lockfile and bootstrap stamp.
async function scratchCheckout(
  root: string,
  stamp: string | undefined,
): Promise<void> {
  await mkdir(`${root}/node_modules`, { recursive: true });
  await copyFile(`${repoRoot}package-lock.json`, `${root}/package-lock.json`);
  await mkdir(`${root}/node_modules/playwright-core`, { recursive: true });
  await copyFile(
    `${repoRoot}node_modules/playwright-core/browsers.json`,
    `${root}/node_modules/playwright-core/browsers.json`,
  );
  if (stamp !== undefined) {
    await writeFile(`${root}/node_modules/.jankurai-bootstrap`, `${stamp}\n`);
  }
}

test("the bootstrapped checkout the lanes run in passes verification", async () => {
  expect(await check({ REPO_ROOT: repoRoot })).toMatchObject({ code: 0 });
});

test("a checkout without node_modules fails fast with the bootstrap hint", async ({}, testInfo) => {
  const root = testInfo.outputPath("missing-node-modules");
  await mkdir(root, { recursive: true });
  await copyFile(`${repoRoot}package-lock.json`, `${root}/package-lock.json`);
  const result = await check({ REPO_ROOT: root });
  expect(result.code).toBe(1);
  expect(result.stderr).toContain(hint);
  expect(result.stderr.trim().split("\n")).toHaveLength(1);
});

test("node_modules installed from another lockfile fails with the bootstrap hint", async ({}, testInfo) => {
  const root = testInfo.outputPath("stale-lockfile");
  await scratchCheckout(root, "0".repeat(64));
  const result = await check({ REPO_ROOT: root });
  expect(result.code).toBe(1);
  expect(result.stderr).toContain("different package-lock.json");
  expect(result.stderr).toContain(hint);
});

test("a missing pinned browser fails with the bootstrap hint and the revision", async ({}, testInfo) => {
  const root = testInfo.outputPath("missing-browser");
  const lockDigest = (
    await promisify(execFile)("sha256sum", [`${repoRoot}package-lock.json`])
  ).stdout.split(" ")[0];
  await scratchCheckout(root, lockDigest);
  const revision = JSON.parse(
    await readFile(
      `${repoRoot}node_modules/playwright-core/browsers.json`,
      "utf8",
    ),
  ).browsers.find(
    (browser: { name: string }) => browser.name === "chromium-headless-shell",
  ).revision;
  const emptyBrowsers = testInfo.outputPath("empty-browsers");
  await mkdir(emptyBrowsers, { recursive: true });
  const result = await check({
    REPO_ROOT: root,
    PLAYWRIGHT_BROWSERS_PATH: emptyBrowsers,
  });
  expect(result.code).toBe(1);
  expect(result.stderr).toContain(
    `chromium headless shell ${revision} is not installed`,
  );
  expect(result.stderr).toContain(hint);
});
