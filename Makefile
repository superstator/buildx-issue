builder:
	docker buildx create --name foobuilder --driver docker-container || echo "Builder already created"
	touch builder

clean:
	docker buildx rm foobuilder
	docker image rm -f foo bar
	rm builder

buildx: builder
	docker buildx build --builder=foobuilder -f Dockerfile.foo -t foo --load .
	docker image ls
	docker buildx build --builder=foobuilder -f Dockerfile.bar -t bar --build-context foo=docker-image://sha256:7bdb7213b1b2932dc04c7f4689e577a475a2aa89e3304a5659c816c4f1af47d0 .

bake: builder
	docker buildx bake --builder foobuilder --load