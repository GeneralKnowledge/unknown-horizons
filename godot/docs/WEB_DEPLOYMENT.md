# Web deployment (Godot 4.3)

Browser build of the PoC settlement slice (`scenes/poc_main.tscn`).

## Prerequisites

- **Godot 4.3** on `PATH` (same major.minor as export templates).
- **Web export templates** for 4.3 stable:
  - Editor: *Editor → Manage Export Templates → Download and Install*
  - Or download [Godot_v4.3-stable_export_templates.tpz](https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_export_templates.tpz) and unzip into  
    `~/.local/share/godot/export_templates/4.3.stable/`  
    (must contain `web_nothreads_release.zip` or `web_release.zip`).
- Python 3 + PyYAML (content export, same as CI).

## Build

From repository root:

```bash
chmod +x godot/export_web.sh
./godot/export_web.sh
```

Output: `godot/build/web/` (`index.html`, `.wasm`, `.pck`, etc.).

The script **fails** if Godot, templates, or the Web preset is missing — it does not emit a partial build silently.

## Serve locally (HTTP)

Browsers block `file://` for WASM. Serve the folder over HTTP:

```bash
cd godot/build/web
python3 -m http.server 8080
```

Open `http://127.0.0.1:8080/`.

## GitHub Pages (optional)

Workflow [`.github/workflows/godot-pages.yml`](../../.github/workflows/godot-pages.yml) exports the web build and deploys `godot/build/web/` to **GitHub Pages** on pushes to `master` (when `godot/**` changes).

1. In the repo **Settings → Pages**, set source to **GitHub Actions**.
2. After a successful workflow run, open the deployment URL from the Actions summary.

Post-export checks: `./development/godot/web_export_smoke.sh` (also run in CI after `export_web.sh`).

## HTTPS / production

Use any static host (S3, Cloudflare Pages, nginx, etc.). Upload the **contents** of `build/web/`.

### GitHub Pages (optional)

1. Enable Pages on the repo (Settings → Pages → deploy from **GitHub Actions** or upload `build/web` from a workflow artifact).
2. After `./godot/export_web.sh`, publish `godot/build/web/` as the site root (no Jekyll: add an empty `.nojekyll` if needed).
3. WASM must be served over **HTTPS** with correct `application/wasm` MIME type (Pages does this by default).

### Headers

This export uses **single-threaded** WASM (`variant/threads_enabled=false`) and does **not** require SharedArrayBuffer. You do **not** need:

- `Cross-Origin-Opener-Policy: same-origin`
- `Cross-Origin-Embedder-Policy: require-corp`

If you later enable threads or SharedArrayBuffer, add those headers and document COOP/COEP on your CDN.

### MIME types

Ensure `.wasm` is served as `application/wasm`. Most static hosts do this by default.

## Verify deployment

### Automated (CI)

GitHub Actions runs a headless `--export-release Web` when templates are installed (see `.github/workflows/godot-tests.yml`).

### Manual browser smoke checklist

1. Load page — no blank canvas; Godot splash or game canvas visible.
2. Open devtools console — no critical errors (red).
3. **Start menu** — New game loads the **development** map; Continue disabled until a save exists.
4. Map tiles visible; HUD shows settlement gold / tick; status line can show load/save messages.
5. **Pan/zoom** — middle-drag and mouse wheel change the view without moving the ghost when over the map.
6. Open a **build palette tab** (tier1+); select **lumberjackcamp**; ghost turns green on valid tiles.
7. Left-click — building appears; inventories update after ticks.
8. Place **tree** tiles near lumberjack; wait — **boards** increase in building storage (sim-driven).
9. **Save JSON** / **Load JSON** — state persists in `user://` for this origin.
10. **Download save** — JSON file downloads; **Import save** restores boards/buildings.
11. **Invalid JSON import** — HUD shows an error; building count unchanged (no silent wipe).
12. **Settlement demo** — **Start settlement demo**; objective panel + clay marker on step 2.
13. **Save JSON** → menu **Continue JSON save** enabled (same as desktop).
14. **Legacy on web** — only **`.extract.json`** imports (not raw `.sqlite`); settlement demo should use JSON.

See also [BROWSER_DEMO.md](BROWSER_DEMO.md) and [PLAYABLE_DEMO.md](PLAYABLE_DEMO.md).

### Environment note (2026-10-17)

Export was verified in the Cloud Agent environment with Godot **4.3.stable** and official export templates (`./godot/export_web.sh` → ~3.9 MB `index.pck`, ~35 MB `index.wasm`). Serve over HTTP and load `index.html` in a desktop browser; automated browser CI is not run in the default workflow beyond export success.

If your local export fails, compare `godot --version` with the template folder name under `export_templates/`.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Missing web export templates` | Install 4.3 templates (see above). |
| Blank page over `file://` | Use HTTP server. |
| Stuck loading | Check network tab for 404 on `.wasm` / `.pck`; check MIME type. |
| SQLite load fails in browser | Expected — legacy SQLite import is desktop-only; use JSON saves. |
| Audio silent until click | Browser autoplay policy — interact with canvas first. |

## Custom maps (`user://maps`)

Bundled maps are listed in `res://resources/maps/maps_manifest.json`. In the browser (and desktop), you can drop additional entries by placing a manifest at:

`user://maps/maps_manifest.json`

For a static site origin, `user://` is scoped to that host (same as JSON saves). Each entry should match the bundled shape:

```json
{
  "maps": [
    { "id": "my_island", "name": "My island", "loader": "stub_test_island" }
  ]
}
```

Loaders are still **stubs** until real ground import lands; unknown ids fall back to the default test island ground. The PoC **Map** dropdown merges bundled + user manifests.

## Static hosting only

No backend is required to serve the game files. Future multiplayer would add a separate command API; out of scope for the initial web milestone.
