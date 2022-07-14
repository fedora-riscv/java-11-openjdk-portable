#!/bin/bash
# Generates the 'source tarball' for JDK projects.
#
# Example:
# When used from local repo set REPO_ROOT pointing to file:// with your repo
# If your local repo follows upstream forests conventions, it may be enough to set OPENJDK_URL
# If you want to use a local copy of patch GH001, set the path to it in the GH001 variable
#
# In any case you have to set PROJECT_NAME REPO_NAME and VERSION. eg:
# PROJECT_NAME=openjdk
# REPO_NAME=jdk11u
# VERSION=HEAD
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

if [ ! "x$GH001" = "x" ] ; then
  if [ ! -f "$GH001" ] ; then
    echo "You have specified GH001 as $GH001 but it does not exist. Exiting"
    exit 1
  fi
fi

if [ ! "x$GH003" = "x" ] ; then
  if [ ! -f "$GH003" ] ; then
    echo "You have specified GH003 as $GH003 but it does not exist. Exiting"
    exit 1
  fi
fi

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
    echo "REPO_ROOT - the location of the Mercurial repository to archive (optional; defaults to OPENJDK_URL/PROJECT_NAME/REPO_NAME)"
    echo "TO_COMPRESS - what part of clone to pack (default is openjdk)"
    echo "GH001 - the path to the ECC code patch, GH001, to apply (optional; downloaded if unavailable)"
    echo "GH003 - the path to the ECC test patch, GH003, to apply (optional; downloaded if unavailable)"
    exit 1;
fi


if [ "x$VERSION" = "x" ] ; then
    echo "No VERSION specified"
    exit -2
fi
echo "Version: ${VERSION}"
    
# REPO_NAME is only needed when we default on REPO_ROOT and FILE_NAME_ROOT
if [ "x$FILE_NAME_ROOT" = "x" -o "x$REPO_ROOT" = "x" ] ; then
  if [ "x$PROJECT_NAME" = "x" ] ; then
    echo "No PROJECT_NAME specified"
    exit -1
  fi
  echo "Project name: ${PROJECT_NAME}"
  if [ "x$REPO_NAME" = "x" ] ; then
    echo "No REPO_NAME specified"
    exit -3
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
    echo "No to be compressed targets specified, ; default to ${TO_COMPRESS}"
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
echo -e "\tGH001: ${GH001}"
echo -e "\tGH003: ${GH003}"

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
    if [ -d openjdk/src ]; then 
        pushd openjdk
            echo "Removing EC source code we don't build"
            CRYPTO_PATH=src/jdk.crypto.ec/share/native/libsunec/impl
	    rm -vf ${CRYPTO_PATH}/ec2.h
	    rm -vf ${CRYPTO_PATH}/ec2_163.c
	    rm -vf ${CRYPTO_PATH}/ec2_193.c
	    rm -vf ${CRYPTO_PATH}/ec2_233.c
	    rm -vf ${CRYPTO_PATH}/ec2_aff.c
	    rm -vf ${CRYPTO_PATH}/ec2_mont.c
	    rm -vf ${CRYPTO_PATH}/ecp_192.c
	    rm -vf ${CRYPTO_PATH}/ecp_224.c

            echo "Syncing EC list with NSS"
            if [ "x$GH001" = "x" ] ; then
                # get gh001-4curve.patch (from https://github.com/icedtea-git/icedtea) in the ${ICEDTEA_VERSION} branch
                # Do not push it or publish it
		echo "GH001 not found. Downloading..."
		wget -v https://github.com/icedtea-git/icedtea/raw/${ICEDTEA_VERSION}/patches/gh001-4curve.patch
	        echo "Applying ${PWD}/gh001-4curve.patch"
		git apply --stat --apply -v -p1 gh001-4curve.patch
		rm gh001-4curve.patch
	    else
		echo "Applying ${GH001}"
		git apply --stat --apply -v -p1 $GH001
            fi;
            if [ "x$GH003" = "x" ] ; then
                # get gh001-4curve.patch (from https://github.com/icedtea-git/icedtea) in the ${ICEDTEA_VERSION} branch
		echo "GH003 not found. Downloading..."
		wget -v https://github.com/icedtea-git/icedtea/raw/${ICEDTEA_VERSION}/patches/gh003-4curve.patch
	        echo "Applying ${PWD}/gh003-4curve.patch"
		git apply --stat --apply -v -p1 gh003-4curve.patch
		rm gh003-4curve.patch
	    else
		echo "Applying ${GH003}"
		git apply --stat --apply -v -p1 $GH003
            fi;
            find . -name '*.orig' -exec rm -vf '{}' ';' || echo "No .orig files found. This is suspicious, but may happen."
        popd
    fi

    # Generate .src-rev so build has knowledge of the revision the tarball was created from
    mkdir build
    pushd build
    sh ${PWD}/../openjdk/configure
    make store-source-revision
    popd
    rm -rf build

    echo "Compressing remaining forest"
    if [ "X$COMPRESSION" = "Xxz" ] ; then
        SWITCH=cJf
    else
        SWITCH=czf
    fi
    TARBALL_NAME=${FILE_NAME_ROOT}-4curve.tar.${COMPRESSION}
    tar --exclude-vcs -$SWITCH ${TARBALL_NAME} $TO_COMPRESS
    mv ${TARBALL_NAME} ..
popd
echo "Done. You may want to remove the uncompressed version - $FILE_NAME_ROOT."
