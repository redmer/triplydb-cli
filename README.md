# `ghcr.io/redmer/triplydb-cli`

Packages [the official Triply CLI][docs] inside a Docker container.

Its (default empty) `WORKDIR` is `/data`.

[docs]: https://docs.triply.cc/triply-cli/

## Example usage

```sh
docker run --rm ghcr.io/redmer/triplydb-cli import-from-file data.nq
```
