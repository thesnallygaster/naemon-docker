variable "DEFAULT_TAG" {
  default = "naemon-docker:local"
}

// Special target: https://github.com/docker/metadata-action#bake-definition
target "docker-metadata-action" {
  tags = ["${DEFAULT_TAG}"]
}

// Default target if none specified
group "default" {
  targets = ["image-local"]
}

target "image" {
  inherits = ["docker-metadata-action"]
}

target "image-local" {
  inherits = ["image"]
  output = ["type=docker"]
  args = {
    APT_PROXY = ""
  }
}

target "image-all" {
  inherits = ["image"]
  platforms = [
    "linux/amd64",
  ]
}

target "image-all-alpine" {
  inherits = ["image"]
  dockerfile = "Dockerfile.alpine"
  platforms = [
    "linux/amd64",
  ]
}
