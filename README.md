# `ghcr.io/redmer/triplydb-cli`

[![GitHub Release](https://img.shields.io/github/v/release/redmer/triplydb-cli)](https://github.com/redmer/triplydb-cli/pkgs/container/triplydb-cli)

Packages [the official Triply CLI][docs] inside a Docker container.

Its (default empty) `WORKDIR` is `/data`.

## Example usage

```sh
docker run --rm ghcr.io/redmer/triplydb-cli import-from-file data.nq
```

## Usage of Triply CLI

Refer to the [documentation at Triply][docs] or ask the container:

```sh
docker run --rm ghcr.io/redmer/triplydb-cli --help
# Or for a certain command
docker run --rm ghcr.io/redmer/triplydb-cli import-from-file --help
```

[docs]: https://docs.triply.cc/triply-cli/
