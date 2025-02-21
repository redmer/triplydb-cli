FROM ubuntu:24.04

ADD --link --chmod=744 https://static.triply.cc/cli/triplydb-linux /bin/triplydb

ENTRYPOINT ["triplydb"]
