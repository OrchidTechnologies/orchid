# Containers

This directory containers docker files for use with Orchid.

To build `orchidd` for Linux inside a docker container:

```
docker build -t orchidbuild:latest -f Dockerfile.build .
docker create -ti --name tmp orchidbuild bash
docker cp tmp:/mnt/artifacts/orchidd .
docker rm -f tmp
```

