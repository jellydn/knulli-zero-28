# Buildkite support

Buildkite uses the [GitHub Actions Buildkite plugin][plugin] and
[`buildkite-gha`][buildkite-gha] to run the existing validation workflow on
Buildkite agents. The native image path does not use the GitHub Actions runtime.
It is the preferred path for the large flashable artifact.

This integration is an experimental, pre-1.0 public preview. Check the
[`buildkite-gha` compatibility guide][compatibility] before you update the
plugin, runtime, or imported workflows.

## One-time setup

1. Create a Buildkite pipeline linked to `jellydn/knulli-zero-28`.
2. Set its pipeline upload command to:

   ```sh
   buildkite-agent pipeline upload .buildkite/pipeline.yml
   ```

3. Map GitHub pull request and push events in the pipeline settings. Buildkite,
   not the imported workflow `on` section, creates builds.
4. Provide a `linux-small` Linux x86_64 agent queue. It is the default for both
   validation and image jobs so a single-agent setup does not leave jobs stuck.
   Image builds still need Docker, Git, Make, and at least 180 GiB of free
   storage. Production setups should use a separate `knulli-image` queue and set
   `BUILDKITE_QUEUE_IMAGE=knulli-image`.

Use disposable, isolated validation agents without protected ambient secrets for
pull requests. Imported workflow steps and actions are repository code.

## Build a flashable image

Create a new build in the Buildkite UI and add this environment variable:

```text
BUILD_ZERO28_IMAGE=1
```

After validation passes, the default pipeline uploads
`.buildkite/pipeline.image.yml`. Its native job builds and uploads `.img.gz`,
`.md5`, and `.sha256` files as Buildkite artifacts.

Optional environment variables:

| Variable | Purpose |
| --- | --- |
| `BUILD_ZERO28_IMAGE_VIA_GHA=1` | Also run the existing image workflow through `buildkite-gha`. |
| `CLEAN_OUTPUT=1` | Remove the cached A133 output before the native build. |
| `KNULLI_BUILD_ROOT=/var/cache/knulli` | Select the persistent downloads, ccache, and output root. |
| `BUILDKITE_QUEUE_VALIDATE=name` | Override the `linux-small` validation queue. |
| `BUILDKITE_QUEUE_IMAGE=name` | Override the `linux-small` image queue, for example with `knulli-image`. |

The image jobs share a concurrency group, so only one large Zero 28 build runs
at a time.

## Flash

Download the `.img.gz` artifact and use balenaEtcher, or on macOS:

```sh
gzcat knulli-*.img.gz | sudo dd of=/dev/rdiskN bs=4m
```

Replace `rdiskN` with the correct microSD device. Selecting the wrong device
destroys its data.

[plugin]: https://github.com/buildkite-plugins/github-actions-buildkite-plugin
[buildkite-gha]: https://github.com/buildkite/buildkite-gha
[compatibility]: https://github.com/buildkite/buildkite-gha/blob/main/docs/compatibility.md
