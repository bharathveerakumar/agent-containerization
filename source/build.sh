#!/bin/sh

#DOCKER_USERNAME=""
#DOCKER_PASSWORD=""
PRIVATE_REGISTRY=$1
IMAGE_NAME_BASE=$2
IMAGE_TAG=$3
ARCH=$4

if [ -z "$PRIVATE_REGISTRY" ] || [ -z "$IMAGE_NAME_BASE" ] || [ -z "$IMAGE_TAG" ] || [ -z "$ARCH" ]; then
  echo "Usage: $0 <registry> <image-name> <tag> <arch>"
  exit 1
fi

# Generate /tmp/buildkitd.toml dynamically
BUILDKIT_CONFIG="/tmp/buildkitd.toml"
cat > "$BUILDKIT_CONFIG" <<EOF
[registry."${PRIVATE_REGISTRY}"]
  http = true
  insecure = true
EOF

# echo "Logging into $PRIVATE_REGISTRY..."
# echo "$DOCKER_PASSWORD" | docker login "$PRIVATE_REGISTRY" --username "$DOCKER_USERNAME" --password-stdin

echo "--- Logging in to Private Registry (Insecure) ---"
echo "$CS_REGISTRY_PASSWORD" | docker login -u "$CS_REGISTRY_USER" --password-stdin "$PRIVATE_REGISTRY_URL"

echo "$CS_REGISTRY_PASSWORD"
echo "username $CS_REGISTRY_USER"
echo "$PRIVATE_REGISTRY_URL"

echo "Removing old buildx builder if exists..."
docker buildx rm custom-builder >/dev/null 2>&1

echo "Creating new buildx builder with docker-container driver..."
docker buildx create --name custom-builder \
  --driver docker-container \
  --use \
  --config "$BUILDKIT_CONFIG"

echo "Building and pushing image to $PRIVATE_REGISTRY/$IMAGE_NAME_BASE:$IMAGE_TAG..."

docker buildx build --builder custom-builder \
  --output type=registry \
  --platform "$ARCH" \
  --pull \
  --no-cache \
  -t "$PRIVATE_REGISTRY/$IMAGE_NAME_BASE:$IMAGE_TAG" .

echo "[+] Done: Image pushed to $PRIVATE_REGISTRY/$IMAGE_NAME_BASE:$IMAGE_TAG"
#build.sh 10.63.38.137:5000 site24x7/testdocker-agent 1.0.0

