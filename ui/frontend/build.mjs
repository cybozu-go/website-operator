// Builds dist/ without a bundler.
//
// This deliberately drives PostCSS through its Node API instead of using
// postcss-cli: postcss-cli depends on chokidar@3, whose optional fsevents
// dependency has a "node-gyp rebuild" install script. fsevents is os-gated to
// darwin, so it is skipped on Linux CI but reappears in pnpm's ignored-builds
// list on macOS. Avoiding it keeps this package free of install scripts on
// every platform, which is the reason Parcel was removed in the first place.
import { copyFile, mkdir, readFile, rm, writeFile } from 'node:fs/promises'
import { createRequire } from 'node:module'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

import tailwindcss from '@tailwindcss/postcss'
import postcss from 'postcss'

const root = fileURLToPath(new URL('.', import.meta.url))
const srcDir = path.join(root, 'src')
const distDir = path.join(root, 'dist')

// alpinejs declares no "exports" map, so subpath resolution is allowed.
const alpineCdn = createRequire(import.meta.url).resolve('alpinejs/dist/cdn.min.js')

await rm(distDir, { recursive: true, force: true })
await mkdir(distDir, { recursive: true })

const from = path.join(srcDir, 'app.css')
const to = path.join(distDir, 'app.css')
const result = await postcss([tailwindcss({ base: srcDir, optimize: true })])
  .process(await readFile(from, 'utf8'), { from, to, map: false })
for (const warning of result.warnings()) console.warn(String(warning))
await writeFile(to, result.css)

// Keep this list in sync when adding files under src/: Tailwind scans all of
// src/ for class names, but only the files named here are copied into dist/.
await copyFile(path.join(srcDir, 'index.html'), path.join(distDir, 'index.html'))
await copyFile(path.join(srcDir, 'app.js'), path.join(distDir, 'app.js'))
await copyFile(alpineCdn, path.join(distDir, 'alpine.min.js'))
