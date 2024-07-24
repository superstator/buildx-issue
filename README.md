# Buildx issue

## Original result

Buildx cannot reference local image from builder using `docker-container` driver. Even when using an explicit `--build-context` the builder always tried to fetch it from `docker.io` rather than local cache.

```
$ make build
docker buildx create --name foobuilder --driver docker-container || echo "Builder already created"
foobuilder
docker buildx build --builder=foobuilder -f Dockerfile.foo -t foo --load .
[+] Building 3.1s (9/9) FINISHED                                                                                                                                  docker-container:foobuilder
 => [internal] booting buildkit                                                                                                                                                          1.2s
 => => pulling image moby/buildkit:buildx-stable-1                                                                                                                                       1.0s
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
 => => extracting sha256:690e87867337b8441990047e169b892933e9006bdbcbed52ab7a356945477a4d                                                                                                0.1s
 => [2/2] RUN touch foo                                                                                                                                                                  0.0s
 => exporting to docker image format                                                                                                                                                     0.1s
 => => exporting layers                                                                                                                                                                  0.0s
 => => exporting manifest sha256:2f3d31a4c5c7a7a47d9a611088fa619c89d59a04b5104da53600e20f7db3f9b9                                                                                        0.0s
 => => exporting config sha256:7bdb7213b1b2932dc04c7f4689e577a475a2aa89e3304a5659c816c4f1af47d0                                                                                          0.0s
 => => sending tarball                                                                                                                                                                   0.0s
 => importing to docker                                                                                                                                                                  0.0s
 => => loading layer 7384adaef14a 93B / 93B                                                                                                                                              0.0s
docker image ls
REPOSITORY      TAG               IMAGE ID       CREATED                  SIZE
foo             latest            7bdb7213b1b2   Less than a second ago   8.83MB
moby/buildkit   buildx-stable-1   9bcf6c7cd2ce   12 days ago              206MB
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

This appears to stem from the fact `buildx` is concerned with building cross platform images (hence the `x`), and thus expects to only use cross platform bases. Local docker cache is always platform specific and does not include cross platform info - it must be fetched from a registry. That said, `buildx` builder cache *is* durable and should contain the results of previous builds, but there is no apparent sane way to reference those cached results in a later build.

## Bake

`bake` to the rescue. `bake` does introduce yet another tool and syntax, so now you not only need Dockerfiles but a Bakefile as well, but it does solve the above problem neatly and possibly saves some fiddling with `docker build` or `docker buildx` commands even when these interdependency issues aren't in play.

```
$ make bake
docker buildx bake --builder foobuilder --load
[+] Building 0.9s (13/13) FINISHED                                                                                                                                docker-container:foobuilder
 => [internal] load local bake definitions                                                                                                                                               0.0s
 => => reading docker-bake.hcl 278B / 278B                                                                                                                                               0.0s
 => [foo internal] load build definition from Dockerfile.foo                                                                                                                             0.0s
 => => transferring dockerfile: 68B                                                                                                                                                      0.0s
 => [foo internal] load metadata for docker.io/library/alpine:latest                                                                                                                     0.4s
 => [foo internal] load .dockerignore                                                                                                                                                    0.0s
 => => transferring context: 2B                                                                                                                                                          0.0s
 => [bar internal] load build definition from Dockerfile.bar                                                                                                                             0.0s
 => => transferring dockerfile: 64B                                                                                                                                                      0.0s
 => [bar internal] load .dockerignore                                                                                                                                                    0.0s
 => => transferring context: 2B                                                                                                                                                          0.0s
 => [foo 1/2] FROM docker.io/library/alpine:latest@sha256:0a4eaa0eecf5f8c050e5bba433f58c052be7587ee8af3e8b3910ef9ab5fbe9f5                                                               0.0s
 => => resolve docker.io/library/alpine:latest@sha256:0a4eaa0eecf5f8c050e5bba433f58c052be7587ee8af3e8b3910ef9ab5fbe9f5                                                                   0.0s
 => CACHED [foo 2/2] RUN touch foo                                                                                                                                                       0.0s
 => CACHED [bar 1/2] RUN touch bar                                                                                                                                                       0.0s
 => [bar] exporting to docker image format                                                                                                                                               0.1s
 => => exporting layers                                                                                                                                                                  0.0s
 => => exporting manifest sha256:1b5c0968539e9c25c55eba8aa43be432bce3b8b95765a06e9e10709d456948bf                                                                                        0.0s
 => => exporting config sha256:68d0ffe5c154d01c329178db5509b2647dbd8af33b485d5336598adbcd980e4a                                                                                          0.0s
 => => sending tarball                                                                                                                                                                   0.1s
 => [foo] exporting to docker image format                                                                                                                                               0.1s
 => => exporting layers                                                                                                                                                                  0.0s
 => => exporting manifest sha256:2f3d31a4c5c7a7a47d9a611088fa619c89d59a04b5104da53600e20f7db3f9b9                                                                                        0.0s
 => => exporting config sha256:7bdb7213b1b2932dc04c7f4689e577a475a2aa89e3304a5659c816c4f1af47d0                                                                                          0.0s
 => => sending tarball                                                                                                                                                                   0.1s
 => importing to docker                                                                                                                                                                  0.0s
 => importing to docker                                        
```
