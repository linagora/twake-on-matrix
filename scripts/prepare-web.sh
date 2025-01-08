#!/bin/sh -ve

# OLM_VERSION=${OLM_VERSION:-$(cat pubspec.yaml | yq .dependencies.flutter_olm | tr -d '"^~' )}
# ## Version from pubspec is outdated and not buildable...
OLM_VERSION="${OLM_VERSION:-3.2.16}"
DOCKER_BUILD="${DOCKER_BUILD:-1}"
NIX_VERSION="2.22.1"

if [[ $DOCKER_BUILD == "1" ]]; then
	docker run -v ./assets/js:/assets/js nixos/nix:"${NIX_VERSION}" nix build -v --extra-experimental-features flakes --extra-experimental-features nix-command gitlab:matrix-org/olm/"${OLM_VERSION}"?host=gitlab.matrix.org\#javascript && cp -rvf /result/ /assets/js/package
else
	DOWNLOAD_PATH="https://github.com/famedly/olm/releases/download/v${OLM_VERSION}/olm.zip"

	mkdir -p assets/js && cd assets/js
	test -d package && rm -r package || echo "nothing to clear!"

	curl -OLSs $DOWNLOAD_PATH
	unzip olm.zip
	rm olm.zip
	mv javascript package
fi

sudo chown $(id -u):$(id -g) ./assets/js/package -R
