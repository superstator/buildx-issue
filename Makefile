builder:
	docker buildx create --name foobuilder --driver docker-container || echo "Builder already created"

clean:
	docker buildx rm foobuilder
	docker image rm -f foo bar

build: builder
	docker buildx build --builder=foobuilder -f Dockerfile.foo -t foo .
	docker buildx build --builder=foobuilder -f Dockerfile.bar -t bar --build-context foo=docker-image://foo .