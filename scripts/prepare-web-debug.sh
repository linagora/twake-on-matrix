#!/bin/sh -ve

mkdir -p assets/js && cd assets/js
test -d package && rm -r package || echo "nothing to clear!"

curl -L 'https://github.com/famedly/olm/releases/latest/download/olm.zip' > olm.zip
unzip olm.zip
rm olm.zip
mv javascript package
