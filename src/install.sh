#!/bin/sh

set -e
set -x

export USER=`whoami`
DOCKER_TESTING=false

# First, install utilities that Nix needs to install itself
opkg-install curl ca-certificates bash shadow-useradd

# Create directories
mkdir -p /var/empty /etc/nix /nix

# Create Nix build group & users.
addgroup -g 20000 nixbld
for n in $(seq 1 10);
do
    useradd \
        -c "Nix build user $n" \
        -u `expr 20000 + $n` \
        -d /var/empty \
        -g nixbld \
        -G nixbld \
        -M -N -r \
        -s "/bin/false" \
        nixbld$n
done

# Configure Nix
mkdir -m 0755 -p /nix/store
chown -R root:nixbld /nix
chmod 1775 /nix/store
echo "build-users-group = nixbld" >> /etc/nix/nix.conf

# Install Nix
cd /tmp
if $DOCKER_TESTING;
then
    # Debugging - when we don't want to download everything.
    ls -al .
    ls -al /build
    ls -al /nix

    fname=nix-1.8-x86_64-linux.tar.bz2

    cp /build/$fname .

    unpack=nix-binary-tarball-unpack
    mkdir $unpack

    cat $fname | bzcat | tar x -C "$unpack"
    "$unpack"/*/install

    rm -rf $fname $unpack
else
    # In "prod", use the online installer.
    curl -L -s https://nixos.org/nix/install | bash
fi
echo "*** Installed Nix"

# Now that Nix is installed, we can install things with it
source ~/.nix-profile/etc/profile.d/nix.sh

# E.g.: nix-env -i <PACKAGE>

# Clean up our build environment
rm -rf /build
