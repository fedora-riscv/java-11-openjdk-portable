#!/bin/bash
# Generates the 'source tarball' for JDK projects.
#
# Example:
# When used from local repo set REPO_ROOT pointing to file:// with your repo
# If your local repo follows upstream forests conventions, it may be enough to set OPENJDK_URL
#
# In any case you have to set PROJECT_NAME REPO_NAME and VERSION. eg:
# PROJECT_NAME=openjdk
# REPO_NAME=jdk11u
# VERSION=jdk-11.0.18+10
# or to eg prepare systemtap:
# icedtea7's jstack and other tapsets
# VERSION=6327cf1cea9e
# REPO_NAME=icedtea7-2.6
# PROJECT_NAME=release
# OPENJDK_URL=http://icedtea.classpath.org/hg/
# TO_COMPRESS="*/tapset"
#
# They are used to create correct name and are used in construction of sources url (unless REPO_ROOT is set)

# This script creates a single source tarball out of the repository
# based on the given tag and removes code not allowed in fedora/rhel. For
# consistency, the source tarball will always contain 'openjdk' as the top
# level folder, name is created, based on parameter
#

set -e

OPENJDK_URL_DEFAULT=https://github.com
COMPRESSION_DEFAULT=xz
# Corresponding IcedTea version
ICEDTEA_VERSION=6.0

if [ "x$1" = "xhelp" ] ; then
    echo -e "Behaviour may be specified by setting the following variables:\n"
    echo "VERSION - the version of the specified OpenJDK project"
    echo "PROJECT_NAME -- the name of the OpenJDK project being archived (optional; only needed by defaults)"
    echo "REPO_NAME - the name of the OpenJDK repository (optional; only needed by defaults)"
    echo "OPENJDK_URL - the URL to retrieve code from (optional; defaults to ${OPENJDK_URL_DEFAULT})"
    echo "COMPRESSION - the compression type to use (optional; defaults to ${COMPRESSION_DEFAULT})"
    echo "FILE_NAME_ROOT - name of the archive, minus extensions (optional; defaults to PROJECT_NAME-REPO_NAME-VERSION)"
    echo "REPO_ROOT - the location of the Git repository to archive (optional; defaults to OPENJDK_URL/PROJECT_NAME/REPO_NAME)"
    echo "TO_COMPRESS - what part of clone to pack (default is openjdk)"
    echo "BOOT_JDK - the bootstrap JDK to satisfy the configure run"
    exit 1;
fi


if [ "x$VERSION" = "x" ] ; then
    echo "No VERSION specified"
    exit 2
fi
echo "Version: ${VERSION}"
NUM_VER=${VERSION##jdk-}
RELEASE_VER=${NUM_VER%%+*}
BUILD_VER=${NUM_VER##*+}
MAJOR_VER=${RELEASE_VER%%.*}
echo "Major version is ${MAJOR_VER}, release ${RELEASE_VER}, build ${BUILD_VER}"

if [ "x$BOOT_JDK" = "x" ] ; then
    echo "No boot JDK specified".
    BOOT_JDK=/usr/lib/jvm/java-${MAJOR_VER}-openjdk;
    echo -n "Checking for ${BOOT_JDK}...";
    if [ -d ${BOOT_JDK} -a -x ${BOOT_JDK}/bin/java ] ; then
        echo "Boot JDK found at ${BOOT_JDK}";
    else
        echo "Not found";
        PREV_VER=$((${MAJOR_VER} - 1));
        BOOT_JDK=/usr/lib/jvm/java-${PREV_VER}-openjdk;
        echo -n "Checking for ${BOOT_JDK}...";
        if [ -d ${BOOT_JDK} -a -x ${BOOT_JDK}/bin/java ] ; then
            echo "Boot JDK found at ${BOOT_JDK}";
        else
            echo "Not found";
            exit 4;
        fi
    fi
else
    echo "Boot JDK: ${BOOT_JDK}";
fi

# REPO_NAME is only needed when we default on REPO_ROOT and FILE_NAME_ROOT
if [ "x$FILE_NAME_ROOT" = "x" -o "x$REPO_ROOT" = "x" ] ; then
  if [ "x$PROJECT_NAME" = "x" ] ; then
    echo "No PROJECT_NAME specified"
    exit 1
  fi
  echo "Project name: ${PROJECT_NAME}"
  if [ "x$REPO_NAME" = "x" ] ; then
    echo "No REPO_NAME specified"
    exit 3
  fi
  echo "Repository name: ${REPO_NAME}"
fi

if [ "x$OPENJDK_URL" = "x" ] ; then
    OPENJDK_URL=${OPENJDK_URL_DEFAULT}
    echo "No OpenJDK URL specified; defaulting to ${OPENJDK_URL}"
else
    echo "OpenJDK URL: ${OPENJDK_URL}"
fi

if [ "x$COMPRESSION" = "x" ] ; then
    # rhel 5 needs tar.gz
    COMPRESSION=${COMPRESSION_DEFAULT}
fi
echo "Creating a tar.${COMPRESSION} archive"

if [ "x$FILE_NAME_ROOT" = "x" ] ; then
    FILE_NAME_ROOT=${PROJECT_NAME}-${REPO_NAME}-${VERSION}
    echo "No file name root specified; default to ${FILE_NAME_ROOT}"
fi
if [ "x$REPO_ROOT" = "x" ] ; then
    REPO_ROOT="${OPENJDK_URL}/${PROJECT_NAME}/${REPO_NAME}.git"
    echo "No repository root specified; default to ${REPO_ROOT}"
fi;

if [ "x$TO_COMPRESS" = "x" ] ; then
    TO_COMPRESS="openjdk"
    echo "No targets to be compressed specified, ; default to ${TO_COMPRESS}"
fi;

echo -e "Settings:"
echo -e "\tVERSION: ${VERSION}"
echo -e "\tPROJECT_NAME: ${PROJECT_NAME}"
echo -e "\tREPO_NAME: ${REPO_NAME}"
echo -e "\tOPENJDK_URL: ${OPENJDK_URL}"
echo -e "\tCOMPRESSION: ${COMPRESSION}"
echo -e "\tFILE_NAME_ROOT: ${FILE_NAME_ROOT}"
echo -e "\tREPO_ROOT: ${REPO_ROOT}"
echo -e "\tTO_COMPRESS: ${TO_COMPRESS}"
echo -e "\tBOOT_JDK: ${BOOT_JDK}"

if [ -d ${FILE_NAME_ROOT} ] ; then
  echo "exists exists exists exists exists exists exists "
  echo "reusing reusing reusing reusing reusing reusing "
  echo ${FILE_NAME_ROOT}
else
  mkdir "${FILE_NAME_ROOT}"
  pushd "${FILE_NAME_ROOT}"
    echo "Cloning ${VERSION} root repository from ${REPO_ROOT}"
    git clone -b ${VERSION} ${REPO_ROOT} openjdk
  popd
fi
pushd "${FILE_NAME_ROOT}"
# UnderlineTaglet.java has a BSD license with a field-of-use restriction, making it non-Free
    if [ -d openjdk/test ] ; then
	echo "Removing langtools test case with non-Free license"
	rm -vf openjdk/test/langtools/tools/javadoc/api/basic/taglets/UnderlineTaglet.java
    fi

    # Generate .src-rev so build has knowledge of the revision the tarball was created from
    mkdir build
    pushd build
    sh ${PWD}/../openjdk/configure --with-boot-jdk=${BOOT_JDK}
    make store-source-revision
    popd
    rm -rf build

    # Remove commit checks
    echo "Removing $(find openjdk -name '.jcheck' -print)"
    find openjdk -name '.jcheck' -print0 | xargs -0 rm -rf

    # Remove history and GHA
    echo "find openjdk -name '.hgtags'"
    find openjdk -name '.hgtags' -exec rm -fv '{}' '+'
    echo "find openjdk -name '.hgignore'"
    find openjdk -name '.hgignore' -exec rm -fv '{}' '+'
    echo "find openjdk -name '.gitattributes'"
    find openjdk -name '.gitattributes' -exec rm -fv '{}' '+'
    echo "find openjdk -name '.gitignore'"
    find openjdk -name '.gitignore' -exec rm -fv '{}' '+'
    echo "find openjdk -name '.git'"
    find openjdk -name '.git' -exec rm -rfv '{}' '+'
    echo "find openjdk -name '.github'"
    find openjdk -name '.github' -exec rm -rfv '{}' '+'

    echo "Compressing remaining forest"
    if [ "X$COMPRESSION" = "Xxz" ] ; then
        SWITCH=cJf
    else
        SWITCH=czf
    fi
    TARBALL_NAME=${FILE_NAME_ROOT}.tar.${COMPRESSION}
    tar --exclude-vcs -$SWITCH ${TARBALL_NAME} $TO_COMPRESS
    mv ${TARBALL_NAME} ..
popd
echo "Done. You may want to remove the uncompressed version - $FILE_NAME_ROOT."
