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

## HTTPS / production

Use any static host (S3, Cloudflare Pages, nginx, etc.). Upload the **contents** of `build/web/`.

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
3. Map tiles visible; HUD shows settlement gold / tick.
4. Select **lumberjackcamp** from build palette; ghost turns green on valid tiles.
5. Left-click — building appears; inventories update after ticks.
6. Place **tree** tiles near lumberjack; wait — **boards** increase in building storage (sim-driven).
7. **Save JSON** / **Load JSON** — state persists in `user://` for this origin.
8. **Download save** — JSON file downloads; **Import save** restores boards/buildings.

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

## Static hosting only

No backend is required to serve the game files. Future multiplayer would add a separate command API; out of scope for the initial web milestone.
