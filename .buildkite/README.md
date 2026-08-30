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
4. Provide Buildkite hosted Linux queues. Validation and pipeline upload use
   `linux-small`. Image builds use `linux-large` by default and need Docker, Git,
   and Make.

| Queue | Disk | Use |
| --- | ---: | --- |
| `linux-small` | ~47 GB | Validate only |
| `linux-medium` | ~95 GB | Still tight for an image build |
| `linux-large` | ~158 GB | Default image build (trial/Pro) |
| XL+ | 284 GB+ | Enterprise |

The free plan provides only Small after the trial. Use the all-access trial or
Pro to run image builds on Large.

Use disposable, isolated validation agents without protected ambient secrets for
pull requests. Imported workflow steps and actions are repository code.

## Build a flashable image

Create a new build in the Buildkite UI and add these environment variables:

```text
BUILD_ZERO28_IMAGE=1
BUILDKITE_QUEUE_IMAGE=linux-large
```

`BUILDKITE_QUEUE_IMAGE` is optional because `linux-large` is the default.

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
| `BUILDKITE_QUEUE_IMAGE=name` | Override the default `linux-large` image queue. |
| `KNULLI_MIN_FREE_GIB=100` | Override the 180 GiB script safety default; the image pipeline sets 100 GiB for hosted Large. |

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
