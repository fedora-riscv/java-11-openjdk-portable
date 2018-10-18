#!/bin/bash -x
#  this file contains defaults for currently generated source tarballs

set -e

# TAPSET
export PROJECT_NAME="hg"
export REPO_NAME="icedtea8"
export VERSION="9d464368e06d"
export COMPRESSION=xz
export OPENJDK_URL=http://icedtea.classpath.org
export FILE_NAME_ROOT=${PROJECT_NAME}-${REPO_NAME}-${VERSION}
export TO_COMPRESS="*/tapset"
# warning, filename  and filenameroot creation is duplicated here from generate_source_tarball.sh
CLONED_FILENAME=${FILE_NAME_ROOT}.tar.${COMPRESSION}
TAPSET_VERSION=3.2
TAPSET=systemtap_"$TAPSET_VERSION"_tapsets_$CLONED_FILENAME
if [ ! -f ${TAPSET} ] ; then
  if [ ! -f ${CLONED_FILENAME} ] ; then
  echo "Generating ${CLONED_FILENAME}"
    sh ./generate_source_tarball.sh
  else 
    echo "exists exists exists exists exists exists exists "
    echo "reusing reusing reusing reusing reusing reusing "
    echo ${CLONED_FILENAME}
  fi
  mv -v $CLONED_FILENAME  $TAPSET
else 
  echo "exists exists exists exists exists exists exists "
  echo "reusing reusing reusing reusing reusing reusing "
  echo ${TAPSET}
fi

# OpenJDK from Shenandoah project
export PROJECT_NAME="shenandoah"
export REPO_NAME="jdk11"
# warning, clonning without shenadnaoh suffix, you will clone pure jdk - thus without shenandaoh GC
export VERSION="shenandoah-jdk-11.0.1+13"
export COMPRESSION=xz
# unset tapsets overrides
export OPENJDK_URL=""
export TO_COMPRESS=""
# warning, filename  and filenameroot creation is duplicated here from generate_source_tarball.sh
export FILE_NAME_ROOT=${PROJECT_NAME}-${REPO_NAME}-${VERSION}
FILENAME=${FILE_NAME_ROOT}.tar.${COMPRESSION}

if [ ! -f ${FILENAME} ] ; then
echo "Generating ${FILENAME}"
  sh ./generate_source_tarball.sh
else 
  echo "exists exists exists exists exists exists exists "
  echo "reusing reusing reusing reusing reusing reusing "
  echo ${FILENAME}
fi

set +e

major=`echo $REPO_NAME | sed 's/[a-zA-Z]*//g'`
build=`echo $VERSION | sed 's/.*+//g'`
name_helper=`echo $FILENAME | sed s/$major/'%{majorver}'/g `
name_helper=`echo $name_helper | sed s/$build/'%{buildver}'/g `
echo "align specfile acordingly:" 
echo " sed 's/^Source0:.*/Source0: $name_helper/' -i *.spec"
echo " sed 's/^Source8:.*/Source8: $TAPSET/'   -i *.spec"
echo " sed 's/^%global buildver.*/%global buildver        $build/'   -i *.spec"
echo " sed 's/Release:.*/Release: 1%{?dist}/'   -i *.spec"
echo "and maybe others...."
echo "you should fedpkg/rhpkg new-sources $TAPSET $FILENAME"
echo "you should fedpkg/rhpkg prep --arch XXXX on all architectures: x86_64 i386 i586 i686 ppc ppc64 ppc64le s390 s390x aarch64 armv7hl"

