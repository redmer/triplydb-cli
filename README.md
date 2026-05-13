# `ghcr.io/redmer/triplydb-cli`

[![GitHub Release](https://img.shields.io/github/v/release/redmer/triplydb-cli)](https://github.com/redmer/triplydb-cli/pkgs/container/triplydb-cli)

Packages [the official Triply CLI][docs] inside a Docker container and provides three GitHub Actions to interact with TriplyDB within your CI/CD workflows: `import-from-file`, `upload-asset`, and `run-pipeline`.

## Example usage

When using it as a container, its (default empty) `WORKDIR` is `/data`.

```bash
$ docker run --rm ghcr.io/redmer/triplydb-cli import-from-file data.nq
```

Or use it as a GitHub Action:

```yaml
jobs:
  triplydb_tasks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - name: Import files to TriplyDB
        uses: redmer/triplydb-cli/import-from-file@main
        with:
          files: "data.ttl more_data.nt"
          token: ${{ secrets.TRIPLYDB_TOKEN }}
          dataset: "my-dataset"

      - name: Upload an asset
        uses: redmer/triplydb-cli/upload-asset@main
        with:
          files: "my_report.pdf"
          token: ${{ secrets.TRIPLYDB_TOKEN }}
          dataset: "my-dataset"

      - name: Run a pipeline
        uses: redmer/triplydb-cli/run-pipeline@main
        with:
          config-file: "pipeline.json"
          token: ${{ secrets.TRIPLYDB_TOKEN }}
```

## Usage of Triply CLI

Refer to the [documentation at Triply][docs] or ask the container:

```sh
docker run --rm ghcr.io/redmer/triplydb-cli --help
# Or for a certain command
docker run --rm ghcr.io/redmer/triplydb-cli run-pipeline --help
```

[docs]: https://docs.triply.cc/triply-cli/
