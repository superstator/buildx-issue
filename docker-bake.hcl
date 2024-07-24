group "default" {
    targets = [ "foo", "bar" ]
}
target "foo" {
    context = "."
    dockerfile = "Dockerfile.foo"
    tags = [ "foo" ]
}
target "bar" {
    context = "."
    dockerfile = "Dockerfile.bar"
    contexts = {
      foo = "target:foo"
    }
    tags = [ "bar" ]
}