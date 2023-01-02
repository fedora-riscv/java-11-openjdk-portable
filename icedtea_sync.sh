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

ICEDTEA_USE_VCS=true

ICEDTEA_VERSION=3.15.0
ICEDTEA_URL=https://icedtea.classpath.org/download/source
ICEDTEA_SIGNING_KEY=CFDA0F9B35964222

ICEDTEA_HG_URL=https://icedtea.classpath.org/hg/icedtea11

set -e

RPM_DIR=${PWD}
if [ ! -f ${RPM_DIR}/jconsole.desktop.in ] ; then
    echo "Not in RPM source tree.";
    exit 1;
fi

if test "x${TMPDIR}" = "x"; then
    TMPDIR=/tmp;
fi
WORKDIR=${TMPDIR}/it.sync

echo "Using working directory ${WORKDIR}"
mkdir ${WORKDIR}
pushd ${WORKDIR}

if test "x${WGET}" = "x"; then
    WGET=$(which wget);
    if test "x${WGET}" = "x"; then
	echo "wget not found";
	exit 1;
    fi
fi

if test "x${TAR}" = "x"; then
    TAR=$(which tar)
    if test "x${TAR}" = "x"; then
	echo "tar not found";
	exit 2;
    fi
fi

echo "Dependencies:";
echo -e "\tWGET: ${WGET}";
echo -e "\tTAR: ${TAR}\n";

if test "x${ICEDTEA_USE_VCS}" = "xtrue"; then
    echo "Mode: Using VCS";

    if test "x${GREP}" = "x"; then
	GREP=$(which grep);
	if test "x${GREP}" = "x"; then
	    echo "grep not found";
	    exit 3;
	fi
    fi

    if test "x${CUT}" = "x"; then
	CUT=$(which cut);
	if test "x${CUT}" = "x"; then
	    echo "cut not found";
	    exit 4;
	fi
    fi

    if test "x${TR}" = "x"; then
	TR=$(which tr);
	if test "x${TR}" = "x"; then
	    echo "tr not found";
	    exit 5;
	fi
    fi

    if test "x${HG}" = "x"; then
	HG=$(which hg);
	if test "x${HG}" = "x"; then
	    echo "hg not found";
	    exit 6;
	fi
    fi

    echo "Dependencies:";
    echo -e "\tGREP: ${GREP}";
    echo -e "\tCUT: ${CUT}";
    echo -e "\tTR: ${TR}";
    echo -e "\tHG: ${HG}";

    echo "Checking out repository from VCS...";
    ${HG} clone ${ICEDTEA_HG_URL} icedtea

    echo "Obtaining version from configure.ac...";
    ROOT_VER=$(${GREP} '^AC_INIT' icedtea/configure.ac|${CUT} -d ',' -f 2|${TR} -d '[][:space:]')
    echo "Root version from configure: ${ROOT_VER}";

    VCS_REV=$(${HG} log -R icedtea --template '{node|short}' -r tip)
    echo "VCS revision: ${VCS_REV}";

    ICEDTEA_VERSION="${ROOT_VER}-${VCS_REV}"
    echo "Creating icedtea-${ICEDTEA_VERSION}";
    mkdir icedtea-${ICEDTEA_VERSION}
    echo "Copying required files from checkout to icedtea-${ICEDTEA_VERSION}";
    # Commented out for now as IcedTea 6's jconsole.desktop.in is outdated
    #cp -a icedtea/jconsole.desktop.in ../icedtea-${ICEDTEA_VERSION}
    cp -a ${RPM_DIR}/jconsole.desktop.in icedtea-${ICEDTEA_VERSION}
    cp -a icedtea/tapset icedtea-${ICEDTEA_VERSION}

    rm -rf icedtea
else
    echo "Mode: Using tarball";

    if test "x${ICEDTEA_VERSION}" = "x"; then
	echo "No IcedTea version specified for tarball download.";
	exit 3;
    fi

    if test "x${CHECKSUM}" = "x"; then
	CHECKSUM=$(which sha256sum)
	if test "x${CHECKSUM}" = "x"; then
	    echo "sha256sum not found";
	    exit 4;
	fi
    fi

    if test "x${PGP}" = "x"; then
	PGP=$(which gpg)
	if test "x${PGP}" = "x"; then
	    echo "gpg not found";
	    exit 5;
	fi
    fi

    echo "Dependencies:";
    echo -e "\tCHECKSUM: ${CHECKSUM}";
    echo -e "\tPGP: ${PGP}\n";

    echo "Checking for IcedTea signing key ${ICEDTEA_SIGNING_KEY}...";
    if ! gpg --list-keys ${ICEDTEA_SIGNING_KEY}; then
	echo "IcedTea signing key ${ICEDTEA_SIGNING_KEY} not installed.";
	exit 6;
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

    rm -vf icedtea-${ICEDTEA_VERSION}.tar.xz
    rm -vf icedtea-${ICEDTEA_VERSION}.tar.xz.sig
    rm -vf icedtea-${ICEDTEA_VERSION}.sha256
fi

echo "Replacing desktop files...";
mv -v icedtea-${ICEDTEA_VERSION}/jconsole.desktop.in ${RPM_DIR}

echo "Creating new tapset tarball...";
mv -v icedtea-${ICEDTEA_VERSION} openjdk
${TAR} cJf ${RPM_DIR}/tapsets-icedtea-${ICEDTEA_VERSION}.tar.xz openjdk

rm -rvf openjdk

popd
rm -rf ${WORKDIR}
