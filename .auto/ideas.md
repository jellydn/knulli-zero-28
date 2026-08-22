# Ideas Backlog — MagicX Zero 28 image

## Active loop (GH-hosted validation — no 180 GiB host available)
Primary metric = validation_ok (1 = validate workflow green). Current state: GREEN.

### DONE
- [x] GH-hosted `validate-magicx-zero-28.yml` (PR/push/manual) with DTS compile,
      script parse, partition/file existence, genimage refs, boot.img magic,
      panel-identity guards.
- [x] Confirmed port soundness vs xu20-v32 reference (boot contract + genimage
      layout identical).
- [x] Boot-package integrity check (fex blobs byte-match committed source + DTS).
- [x] Verified all guards have teeth via negative tests (panel loss, Zero-40
      panel leak, fex corruption all fire).
- [x] FIXED dispatch-ref bug: measure.sh must use `REF=knulli-main` (stale
      feature-branch ref silently re-ran the original workflow).

### Candidate strengthening (pick most valuable next)
- [ ] Verify `env.img` parse: confirm `boot_partition=boot`,
      `root_partition=rootfs`, `mmc_root=/dev/mmcblk0p7` match the GPT layout
      (boot=mmcblk0p?, rootfs=mmcblk0p4). Env says p7 for root, but boot.img
      cmdline says p4 — document the actual GPT partition numbering.
- [ ] Add `boot_package.fex` regeneration check on the runner (dragonsecboot
      pack) — requires host-allwinner-utils, may be heavy for 14 GB runner.
- [ ] Add a diff-against-reference guard: zero-28 genimage offsets/sizes must
      equal xu20-v32 (currently only eyeballed, not enforced in CI).
- [ ] Parse `partitions/genimage.cfg` vs `genimage.cfg` size mismatch (4G vs 5G
      boot.vfat) — confirm which is authoritative and that the dead file's
      divergence is harmless.

## Full-image build (requires 180 GiB x64 host + self-hosted runner)
- Not available per user. If infra appears later:
  - Reduce CI build duration: verify persistent ccache reuse between dispatches.
  - `BR2_CCACHE`/`BR2_PER_PACKAGE_DIRECTORIES` interplay with persistent ccache.
  - Confirm `MAKE_JLEVEL` uses all runner cores.

## Device-port hardening (research notes)
- Zero 28 DTS: no `cap_touch` node (correct — non-touch), `motor_para` vibrator,
  `adc_joy_*` dual-analog calibration.
- Known upstream test-build issues (community): first-boot freezes, PS1
  micro-stutter, reversed analog in some games, nonworking ADB, irrelevant BT
  settings. Investigate only with a real artifact to test.
