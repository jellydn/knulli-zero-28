# Ideas Backlog — MagicX Zero 28 image

## Stage 2 (only after artifact_ok == 1 is stable)
- Reduce CI build duration: enable persistent ccache hit verification (already
  wired via KNULLI_BUILD_ROOT; measure warm-cache build time).
- `BR2_CCACHE=y` / `BR2_PER_PACKAGE_DIRECTORIES` interplay with the persistent
  ccache dir — confirm the runner mount is actually reused between dispatches.
- Parallelize `PARALLEL_BUILD=1` is already set; verify `MAKE_JLEVEL` uses all
  runner cores (nproc on the x64 box).
- Consider building only the single device image to skip sibling device
  genimage steps (already done via EXTRA_OPTS single target).

## Device-port hardening (research notes, not yet acted)
- Zero 28 DTS: no `cap_touch` node (correct — non-touch panel), `motor_para`
  vibrator present, `adc_joy_*` calibration values for dual analog.
- Known upstream test-build issues (from community): first-boot freezes,
  PS1 micro-stutter, reversed analog in some games, nonworking ADB, irrelevant
  BT settings. Investigate only if a real artifact exists to test.
