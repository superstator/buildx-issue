# Buildx issue

Cannot reference local image from builder using `docker-container` driver. Even when using an explicit `--build-context` the builder always tried to fetch it from `docker.io` rather than local cache.

```
$ make build
docker buildx create --name foobuilder --driver docker-container || echo "Builder already created"
foobuilder
docker buildx build --builder=foobuilder -f Dockerfile.foo -t foo .
[+] Building 3.5s (7/7) FINISHED                                                                                                                                  docker-container:foobuilder
 => [internal] booting buildkit                                                                                                                                                          1.6s
 => => pulling image moby/buildkit:buildx-stable-1                                                                                                                                       1.4s
 => => creating container buildx_buildkit_foobuilder0                                                                                                                                    0.2s
 => [internal] load build definition from Dockerfile.foo                                                                                                                                 0.0s
 => => transferring dockerfile: 68B                                                                                                                                                      0.0s
 => [internal] load metadata for docker.io/library/alpine:latest                                                                                                                         1.3s
 => [auth] library/alpine:pull token for registry-1.docker.io                                                                                                                            0.0s
 => [internal] load .dockerignore                                                                                                                                                        0.0s
 => => transferring context: 2B                                                                                                                                                          0.0s
 => [1/2] FROM docker.io/library/alpine:latest@sha256:0a4eaa0eecf5f8c050e5bba433f58c052be7587ee8af3e8b3910ef9ab5fbe9f5                                                                   0.3s
 => => resolve docker.io/library/alpine:latest@sha256:0a4eaa0eecf5f8c050e5bba433f58c052be7587ee8af3e8b3910ef9ab5fbe9f5                                                                   0.0s
 => => sha256:690e87867337b8441990047e169b892933e9006bdbcbed52ab7a356945477a4d 4.09MB / 4.09MB                                                                                           0.2s
 => => extracting sha256:690e87867337b8441990047e169b892933e9006bdbcbed52ab7a356945477a4d                                                                                                0.0s
 => [2/2] RUN touch foo                                                                                                                                                                  0.1s
WARNING: No output specified with docker-container driver. Build result will only remain in the build cache. To push result image into registry use --push or to load image into docker use --load
docker buildx build --builder=foobuilder -f Dockerfile.bar -t bar --build-context foo=docker-image://foo .
[+] Building 0.5s (3/3) FINISHED                                                                                                                                  docker-container:foobuilder
 => [internal] load build definition from Dockerfile.bar                                                                                                                                 0.0s
 => => transferring dockerfile: 64B                                                                                                                                                      0.0s
 => ERROR [context foo] load metadata for foo                                                                                                                                            0.5s
 => [auth] library/foo:pull token for registry-1.docker.io                                                                                                                               0.0s
------
 > [context foo] load metadata for foo:
------
WARNING: No output specified with docker-container driver. Build result will only remain in the build cache. To push result image into registry use --push or to load image into docker use --load
Dockerfile.bar:1
--------------------
   1 | >>> FROM foo
   2 |     
   3 |     RUN touch bar
--------------------
ERROR: failed to solve: failed to resolve source metadata for docker.io/library/foo:latest: pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed
make: *** [build] Error 1
```