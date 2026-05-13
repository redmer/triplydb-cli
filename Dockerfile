FROM debian:stable-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libstdc++6 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ADD --chmod=744 https://static.triply.cc/cli/triplydb-linux /bin/triplydb

WORKDIR /data
ENTRYPOINT ["triplydb"]
