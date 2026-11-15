#!/bin/bash
# Build Ubuntu noble's systemd source package with the patches in patches/.
# Runs inside an ubuntu:24.04 container; the repository is mounted at /work
# and the .debs land in /work/out.
set -euo pipefail

cd /work
UBUNTU_VERSION=$(cat UBUNTU_VERSION)
VERSION="${UBUNTU_VERSION}$(cat LOCAL_SUFFIX)"
SRC_URL="https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/systemd/${UBUNTU_VERSION}/systemd_${UBUNTU_VERSION}.dsc"

export DEBIAN_FRONTEND=noninteractive
export DEB_BUILD_OPTIONS="nocheck parallel=$(nproc)"
export DEB_BUILD_PROFILES="nocheck noudeb"
export DEBFULLNAME="Brad House" DEBEMAIL="bhouse@nexthop.ai"

apt-get update -qq
apt-get install -y -qq --no-install-recommends \
    build-essential devscripts equivs ca-certificates curl >/dev/null

rm -rf build out && mkdir -p build out
cd build
dget -q -u -d "$SRC_URL"
dpkg-source -x "systemd_${UBUNTU_VERSION}.dsc" src
cd src

for p in $(cat /work/patches/series); do
    cp "/work/patches/$p" debian/patches/
    echo "$p" >> debian/patches/series
done

dch -v "$VERSION" -D noble "Add $(paste -sd' ' /work/patches/series) (see https://github.com/bhouse-nexthop/systemd-stable/tree/noble-nexthop)."

mk-build-deps -i -r -t "apt-get -y -qq --no-install-recommends" debian/control >/dev/null
rm -f systemd-build-deps_*

dpkg-buildpackage -b -uc -us
cd ..
cp ./*.deb ./*.buildinfo ./*.changes /work/out/
ls -l /work/out
