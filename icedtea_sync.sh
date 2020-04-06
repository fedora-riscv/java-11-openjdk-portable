#!/bin/bash

# Copyright (C) 2019 Red Hat, Inc.
# Written by Andrew John Hughes <gnu.andrew@redhat.com>.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

ICEDTEA_VERSION=3.15.0
ICEDTEA_URL=https://icedtea.classpath.org/download/source
ICEDTEA_SIGNING_KEY=CFDA0F9B35964222

set -e

if test "x${WGET}" = "x"; then
    WGET=$(which wget);
    if test "x${WGET}" = "x"; then
	echo "wget not found";
	exit 1;
    fi
fi

if test "x${CHECKSUM}" = "x"; then
    CHECKSUM=$(which sha256sum)
    if test "x${CHECKSUM}" = "x"; then
	echo "sha256sum not found";
	exit 2;
    fi
fi

if test "x${PGP}" = "x"; then
    PGP=$(which gpg)
    if test "x${PGP}" = "x"; then
	echo "gpg not found";
	exit 3;
    fi
fi

if test "x${TAR}" = "x"; then
    TAR=$(which tar)
    if test "x${TAR}" = "x"; then
	echo "tar not found";
	exit 4;
    fi
fi

echo "Dependencies:";
echo -e "\tWGET: ${WGET}";
echo -e "\tCHECKSUM: ${CHECKSUM}";
echo -e "\tPGP: ${PGP}\n";
echo -e "\tTAR: ${TAR}\n";

echo "Checking for IcedTea signing key ${ICEDTEA_SIGNING_KEY}...";
if ! gpg --list-keys ${ICEDTEA_SIGNING_KEY}; then
    echo "IcedTea signing key ${ICEDTEA_SIGNING_KEY} not installed.";
    exit 5;
fi

echo "Downloading IcedTea release tarball...";
${WGET} -v ${ICEDTEA_URL}/icedtea-${ICEDTEA_VERSION}.tar.xz
echo "Downloading IcedTea tarball signature...";
${WGET} -v ${ICEDTEA_URL}/icedtea-${ICEDTEA_VERSION}.tar.xz.sig
echo "Downloading IcedTea tarball checksums...";
${WGET} -v ${ICEDTEA_URL}/icedtea-${ICEDTEA_VERSION}.sha256

echo "Verifying checksums...";
${CHECKSUM} --check --ignore-missing icedtea-${ICEDTEA_VERSION}.sha256

echo "Checking signature...";
${PGP} --verify icedtea-${ICEDTEA_VERSION}.tar.xz.sig

echo "Extracting files...";
${TAR} xJf icedtea-${ICEDTEA_VERSION}.tar.xz \
       icedtea-${ICEDTEA_VERSION}/tapset \
       icedtea-${ICEDTEA_VERSION}/jconsole.desktop.in

echo "Replacing desktop files...";
mv -v icedtea-${ICEDTEA_VERSION}/jconsole.desktop.in .

echo "Creating new tapset tarball...";
mv -v icedtea-${ICEDTEA_VERSION} openjdk
${TAR} cJf tapsets-icedtea-${ICEDTEA_VERSION}.tar.xz openjdk

rm -rvf openjdk
rm -vf icedtea-${ICEDTEA_VERSION}.tar.xz
rm -vf icedtea-${ICEDTEA_VERSION}.tar.xz.sig
rm -vf icedtea-${ICEDTEA_VERSION}.sha256
