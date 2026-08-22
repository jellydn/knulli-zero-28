# Autoresearch: MagicX Zero 28 Knulli image

## Objective
Produce a valid, bootable Knulli firmware image for the MagicX **Mini Zero 28**
(Allwinner A133P / A133 Plus, PowerVR GE8300, 2.8" IPS 640x480 4:3, dual analog).
"Current one is strong" — we must not regress it. Stage 1 = get a working
artifact; Stage 2 (only after artifact is green) = reduce CI build duration.

## Metrics
- **Primary**: `validation_ok` (unitless, HIGHER is better) — 1 if the
  GitHub-hosted `validate-magicx-zero-28` workflow passes (DTS compiles,
  boot scripts parse, partition references resolve, no missing files);
  0 otherwise.
- **Secondary**: `build_minutes` (lower better), `dts_errors`,
  `genimage_errors`, `missing_files`, `script_errors`.

## How to Run
`./.auto/measure.sh` — dispatches the `validate-magicx-zero-28` workflow on a
GitHub-hosted runner, waits for completion, and emits `METRIC validation_ok=...`.

Requires `gh` CLI authed as `jellydn` (already true in this env).

## Build infra
- **Full image build** (180 GiB) needs the `[self-hosted, Linux, X64]` runner
  — user has stated this is NOT available (no machine with that space).
- **Port validation** (this loop) runs on GitHub-hosted `ubuntu-latest`
  (14 GB is plenty for DTS compile + script/file checks). This is the honest
  proxy for "the current image is strong / do not regress it": it catches port
  defects without needing the full build.
- Do not fabricate a benchmark or an artifact result.

## Files in Scope
- `board/allwinner/a133/magicx-zero-28/**` — device port: `genimage.cfg`,
  `boot/*`, `patches/*`, `partitions/*`, `create-boot-script.sh`.
- `package/boot/uboot-a133/magicx-zero-28/**` — u-boot DTS + boot package.
- `.github/workflows/build-magicx-zero-28.yml` — CI pipeline.
- `configs/knulli-a133.board` — A133 defconfig fragment.
- `Makefile`, `Dockerfile` — build plumbing (rarely).

## Off Limits
- Other devices' board dirs (`magicx-zero-40`, `trimui-*`, `powkiddy-*`, …).
- `buildroot/` and `batocera/` submodules (empty here; populated on runner).
- Do not change the panel identity: Zero 28 must keep `h028b23` 640x480 LCD
  config in its DTS (do NOT copy the Zero 40 `RTP40WV101B` 480x800 touch panel).

## Constraints
- Image must be genuinely bootable Zero 28: correct DTB
  (`sun50i-h616-x96-mate.dtb` via boot script), correct boot package
  (`magicx-zero-28_boot_package.fex`), correct partitions.
- No benchmark gaming / overfitting. Success is a real artifact + verified
  checksums, nothing synthetic.

## What's Been Tried
- Reviewed commit d36f5e5 (CI workflow): structurally sound; no blocking code
  defect. Checksum files (`.md5`/`.sha256`) ARE produced by
  `board/scripts/post-image-script.sh` (lines 156–166).
- Confirmed board tree is a real, device-specific port (diffed Zero 28 vs
  Zero 40 DTS: distinct panel, touch, joystick, GPIO, vibrator nodes).
- Investigated `partitions/genimage.cfg` with `titions/boot0.img` typo: it is a
  DEAD file, identical in every A133/A527/H700 board, never used. The real
  `genimage.cfg` is correct. NOT a Zero 28 defect.
- Confirmed Zero 28 `create-boot-script.sh` + `../partitions/` convention is
  self-consistent (matches `xu20-v32` reference).
- KEY: A133 boards boot via Android-style `boot.img` (zImage + ramdisk.gz +
  baked cmdline), NOT `boot.scr`/`extlinux.conf` (Rockchip-only). So the
  committed `boot.scr` (built from `h616-boot.txt`, not `boot.cmd`) is cosmetic
  and never reaches the image.
- Zero 28 boot contract MATCHES xu20-v32 reference: `root=/dev/mmcblk0p4`,
  `console=ttyS0`, `rdinit=/init`, env `mmc_root=p7`.
- genimage knulli.img layout (offsets/sizes/gpt-location) byte-identical to
  xu20-v32 reference.
- Local validation (dtc + mkimage + file checks): total_errors=0, validation_ok=1.
- Added GH-hosted `validate-magicx-zero-28.yml` (runs on PR/push/manual) with
  boot-contract + panel-identity guards. Green.
- Full image build blocked: no 180 GiB host and no self-hosted runner.
