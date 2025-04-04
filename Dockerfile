FROM ubuntu:24.04

ADD --chmod=744 https://static.triply.cc/cli/triplydb-linux /bin/triplydb

WORKDIR /data
ENTRYPOINT ["triplydb"]
