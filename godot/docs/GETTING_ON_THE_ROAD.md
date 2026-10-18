# Getting on the road

Fast paths to **play**, **host**, and **hack** the Godot settlement demo — no legacy FIFE install required.

## Play locally (desktop)

**One-time:** Godot **4.3+**, Python 3 + PyYAML.

```bash
# From repo root — export content (same as CI), launch settlement demo
chmod +x development/godot/play_demo.sh
./development/godot/play_demo.sh
```

On the title screen choose **Start settlement demo**. Controls and objectives: [`PLAYABLE_DEMO.md`](PLAYABLE_DEMO.md).

**Full verify (maintainers):**

```bash
./development/godot/sync.sh    # export + validate + full GUT
```

## Play in the browser

```bash
./godot/export_web.sh
cd godot/build/web && python3 -m http.server 8080
# Open http://127.0.0.1:8080/
```

Smoke checklist: [`WEB_DEPLOYMENT.md`](WEB_DEPLOYMENT.md) · feature list: [`BROWSER_DEMO.md`](BROWSER_DEMO.md).

### GitHub Pages (public demo)

Workflow [`.github/workflows/godot-pages.yml`](../../.github/workflows/godot-pages.yml) deploys `godot/build/web/` on pushes to `master` when `godot/**` changes.

1. Repo **Settings → Pages → Build and deployment → GitHub Actions**.
2. Push to `master` (or run the workflow manually).
3. Open the deployment URL from the Actions summary.

Saves in the browser use **JSON** (Save / Download / Import) — see [`SAVE_FORMAT.md`](SAVE_FORMAT.md).

## What “done” means today

| You can… | Notes |
|----------|--------|
| Run the **two-step settlement demo** (boards → bricks) | JSON save/load + Continue on menu |
| Export and host **WASM** | Single-threaded preset; no backend |
| Trust **sim rules** via GUT + **14** parity goldens | `./development/godot/parity/run_all.sh` |
| Edit balance in **`legacy/content/`** | Re-export with `development/godot/export_all.sh` |

Not in scope yet: full campaign, ships, multiplayer, legacy `.sqlite` parity ([`LEGACY_IMPORT_FROZEN.md`](LEGACY_IMPORT_FROZEN.md)).

## Next implementation hooks

- **View:** Tier A/B imports — [`EXTERNAL_GODOT_PORT.md`](EXTERNAL_GODOT_PORT.md) (build palette now uses exported gfx icons where available).
- **Parity:** Stage 3 chains — [`development/godot/parity/README.md`](../../development/godot/parity/README.md).
- **Roadmap:** [`PROJECT_ROADMAP.md`](PROJECT_ROADMAP.md) M8 backlog.
