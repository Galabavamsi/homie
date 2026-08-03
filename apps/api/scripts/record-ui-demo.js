import { spawnSync } from 'node:child_process';
import { access, mkdir, rm } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { chromium } from 'playwright';

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const outputDirectory = path.resolve(scriptDirectory, '../../../docs/demo');
const recordingDirectory = path.join(outputDirectory, '.recording');
const videoPath = path.join(outputDirectory, 'homie-builders-club-demo.mp4');
const coverPath = path.join(outputDirectory, 'homie-builders-club-demo-cover.png');
const demoUrl = (process.env.HOMIE_DEMO_URL ?? 'http://127.0.0.1:5100').replace(/\/$/, '');
let activeBrowser;

const pause = (page, milliseconds) => page.waitForTimeout(milliseconds);
const stage = (message) => console.log(`[demo] ${message}`);

async function findChrome() {
  if (process.env.CHROME_PATH) return process.env.CHROME_PATH;

  const candidates = process.platform === 'win32'
    ? [
        path.join(process.env.PROGRAMFILES ?? '', 'Google/Chrome/Application/chrome.exe'),
        path.join(process.env['PROGRAMFILES(X86)'] ?? '', 'Google/Chrome/Application/chrome.exe'),
        path.join(process.env.LOCALAPPDATA ?? '', 'Google/Chrome/Application/chrome.exe'),
      ]
    : process.platform === 'darwin'
      ? ['/Applications/Google Chrome.app/Contents/MacOS/Google Chrome']
      : ['/usr/bin/google-chrome', '/usr/bin/chromium', '/usr/bin/chromium-browser'];

  for (const candidate of candidates) {
    if (!candidate) continue;
    try {
      await access(candidate);
      return candidate;
    } catch {
      // Try the next known installation path.
    }
  }

  throw new Error('Chrome was not found. Set CHROME_PATH to a Chrome or Chromium executable.');
}

async function installRecordingOverlay(page) {
  await page.evaluate(() => {
    const cursor = document.createElement('div');
    cursor.id = 'homie-demo-cursor';
    Object.assign(cursor.style, {
      position: 'fixed',
      left: '0',
      top: '0',
      width: '22px',
      height: '22px',
      border: '3px solid #ff6d21',
      borderRadius: '50%',
      background: 'rgba(255,255,255,.88)',
      boxShadow: '0 3px 14px rgba(0,0,0,.35)',
      pointerEvents: 'none',
      transform: 'translate(-50%, -50%)',
      transition: 'width 90ms ease, height 90ms ease',
      zIndex: '2147483647',
    });

    const caption = document.createElement('div');
    caption.id = 'homie-demo-caption';
    Object.assign(caption.style, {
      position: 'fixed',
      top: '14px',
      left: '50%',
      maxWidth: '720px',
      padding: '10px 16px',
      border: '1px solid rgba(255,255,255,.24)',
      borderRadius: '8px',
      color: 'white',
      background: 'rgba(18,15,13,.9)',
      boxShadow: '0 8px 28px rgba(0,0,0,.28)',
      font: '700 16px/1.25 Arial, sans-serif',
      textAlign: 'center',
      opacity: '0',
      pointerEvents: 'none',
      transform: 'translateX(-50%) translateY(-8px)',
      transition: 'opacity 180ms ease, transform 180ms ease',
      zIndex: '2147483646',
    });

    document.body.append(cursor, caption);
    document.addEventListener('mousemove', (event) => {
      cursor.style.left = `${event.clientX}px`;
      cursor.style.top = `${event.clientY}px`;
    });
    document.addEventListener('mousedown', () => {
      cursor.style.width = '34px';
      cursor.style.height = '34px';
      window.setTimeout(() => {
        cursor.style.width = '22px';
        cursor.style.height = '22px';
      }, 160);
    });
  });
}

async function enableFlutterSemantics(page) {
  const placeholder = page.locator('flt-semantics-placeholder');
  if (await placeholder.count() === 1) {
    await placeholder.evaluate((element) => element.click());
    await pause(page, 150);
  }
}

async function showCaption(page, text) {
  await page.evaluate((nextText) => {
    const caption = document.querySelector('#homie-demo-caption');
    if (!caption) return;
    caption.textContent = nextText;
    caption.style.opacity = '1';
    caption.style.transform = 'translateX(-50%) translateY(0)';
  }, text);
}

async function clickAt(page, x, y, waitAfter = 650) {
  await page.mouse.move(x, y, { steps: 14 });
  await pause(page, 300);
  await page.mouse.click(x, y);
  await pause(page, waitAfter);
}

async function smoothScroll(page, distance, steps = 10) {
  await page.mouse.move(1100, 650, { steps: 10 });
  for (let index = 0; index < steps; index += 1) {
    await page.mouse.wheel(0, distance / steps);
    await pause(page, 70);
  }
  await pause(page, 300);
}

async function scrollUntilVisible(page, locator, maxAttempts = 20) {
  for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
    if (await locator.count() === 1 && await locator.isVisible()) return;
    await page.mouse.wheel(0, 180);
    await pause(page, 180);
  }
  throw new Error('The expected control did not become visible while scrolling.');
}

async function waitForHash(page, expectedHash) {
  await page.waitForFunction(
    (hash) => window.location.hash === hash,
    expectedHash,
    { timeout: 10000 },
  );
}

async function recordDemo() {
  await mkdir(outputDirectory, { recursive: true });
  await rm(recordingDirectory, { recursive: true, force: true });
  await rm(videoPath, { force: true });
  await rm(coverPath, { force: true });

  const chromePath = await findChrome();
  const browser = await chromium.launch({
    executablePath: chromePath,
    headless: true,
    args: ['--autoplay-policy=no-user-gesture-required'],
  });
  activeBrowser = browser;
  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 },
    colorScheme: 'dark',
    recordVideo: { dir: recordingDirectory, size: { width: 1280, height: 720 } },
  });
  const page = await context.newPage();
  page.setDefaultTimeout(10000);
  page.setDefaultNavigationTimeout(15000);
  const consoleErrors = [];
  page.on('console', (message) => {
    if (message.type() === 'error') consoleErrors.push(message.text());
  });

  stage('Opening the release app');
  await page.goto(`${demoUrl}/#/`, { waitUntil: 'domcontentloaded' });
  await enableFlutterSemantics(page);
  await installRecordingOverlay(page);
  await pause(page, 1500);

  stage('Login');
  await showCaption(page, 'Homie: collaborative group ordering on Swiggy MCP');
  await pause(page, 2300);
  await clickAt(page, 640, 656);
  await waitForHash(page, '#/home');

  stage('Home');
  await showCaption(page, 'Create one room for friends, family, flatmates, or teams');
  await pause(page, 2400);
  await clickAt(page, 640, 211);
  await waitForHash(page, '#/create-room');

  stage('Create room');
  await showCaption(page, 'Set the room, location, budget, and food preferences');
  await pause(page, 2800);
  await clickAt(page, 640, 419);
  await waitForHash(page, '#/invite');

  stage('Invite');
  await showCaption(page, 'Invite everyone with a QR code, link, or room code');
  await pause(page, 3200);
  await clickAt(page, 640, 475);
  await waitForHash(page, '#/room');
  await enableFlutterSemantics(page);

  stage('Live room');
  await showCaption(page, 'Five participants are present in the live ordering room');
  await pause(page, 3000);
  await smoothScroll(page, 520);

  stage('Voting');
  await showCaption(page, 'Discover on Swiggy, then vote together in real time');
  await pause(page, 2200);
  await clickAt(page, 1225, 389);
  await smoothScroll(page, 500);

  stage('Menu');
  await showCaption(page, 'Each participant can add their own menu items');
  await pause(page, 2300);
  const addButtons = page.getByRole('button', { name: 'Add', exact: true });
  const addButtonCount = await addButtons.count();
  if (addButtonCount < 3) {
    throw new Error(`Expected at least three menu Add controls, found ${addButtonCount}.`);
  }
  await addButtons.nth(2).click();
  await pause(page, 650);
  const checkoutButton = page.getByRole('button', { name: 'Checkout', exact: true });
  await scrollUntilVisible(page, checkoutButton);

  stage('Shared cart');
  await showCaption(page, 'The live owner split lands at INR 998, inside the beta cap');
  await pause(page, 3800);
  await checkoutButton.click();
  await pause(page, 650);
  await waitForHash(page, '#/checkout');
  await enableFlutterSemantics(page);

  stage('Checkout');
  await showCaption(page, 'Swiggy remains the checkout, payment, and delivery layer');
  await pause(page, 3500);
  await clickAt(page, 640, 620, 800);
  await waitForHash(page, '#/tracking');

  stage('Tracking');
  await showCaption(page, 'The whole room follows one shared delivery timeline');
  await pause(page, 4200);
  await showCaption(page, 'Homie owns collaboration. Swiggy remains the commerce platform.');
  await pause(page, 4200);

  const video = page.video();
  stage('Finalizing browser capture');
  await context.close();
  const rawVideoPath = await video.path();
  await browser.close();
  activeBrowser = undefined;

  if (consoleErrors.length > 0) {
    throw new Error(`The demo produced console errors:\n${consoleErrors.join('\n')}`);
  }

  stage('Encoding MP4');
  const ffmpeg = spawnSync(
    'ffmpeg',
    [
      '-y',
      '-i', rawVideoPath,
      '-c:v', 'libx264',
      '-preset', 'medium',
      '-crf', '20',
      '-pix_fmt', 'yuv420p',
      '-movflags', '+faststart',
      '-an',
      videoPath,
    ],
    { stdio: 'inherit' },
  );
  if (ffmpeg.status !== 0) throw new Error('ffmpeg failed to create the MP4 demo.');

  const cover = spawnSync(
    'ffmpeg',
    ['-y', '-ss', '00:00:34', '-i', videoPath, '-frames:v', '1', coverPath],
    { stdio: 'inherit' },
  );
  if (cover.status !== 0) throw new Error('ffmpeg failed to create the demo cover image.');

  await rm(recordingDirectory, { recursive: true, force: true });
  console.log(`Demo video: ${videoPath}`);
  console.log(`Cover image: ${coverPath}`);
}

recordDemo().catch(async (error) => {
  console.error(error);
  await activeBrowser?.close().catch(() => {});
  process.exitCode = 1;
});
