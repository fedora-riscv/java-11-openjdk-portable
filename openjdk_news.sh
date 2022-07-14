#!/bin/bash

# Copyright (C) 2022 Red Hat, Inc.
# Written by Andrew John Hughes <gnu.andrew@redhat.com>, 2012-2022
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

OLD_RELEASE=$1
NEW_RELEASE=$2
SUBDIR=$3
REPO=$4
SCRIPT_DIR=$(dirname ${0})

if test "x${SUBDIR}" = "x"; then
    echo "No subdirectory specified; using .";
    SUBDIR=".";
fi

if test "x$REPO" = "x"; then
    echo "No repository specified; using ${PWD}"
    REPO=${PWD}
fi

if test x${TMPDIR} = x; then
    TMPDIR=/tmp;
fi

echo "Repository: ${REPO}"

if [ -e ${REPO}/.git ] ; then
    TYPE=git;
elif [ -e ${REPO}/.hg ] ; then
    TYPE=hg;
else
    echo "No Mercurial or Git repository detected.";
    exit 1;
fi

if test "x$OLD_RELEASE" = "x" || test "x$NEW_RELEASE" = "x"; then
    echo "ERROR: Need to specify old and new release";
    exit 2;
fi

echo "Listing fixes between $OLD_RELEASE and $NEW_RELEASE in $REPO"
rm -f ${TMPDIR}/fixes2 ${TMPDIR}/fixes3 ${TMPDIR}/fixes
for repos in . $(${SCRIPT_DIR}/discover_trees.sh ${REPO});
do
    if test "x$TYPE" = "xhg"; then
	hg log -r "tag('$NEW_RELEASE'):tag('$OLD_RELEASE') - tag('$OLD_RELEASE')" -R $REPO/$repos -G -M ${REPO}/${SUBDIR} | \
	    egrep '^[o:| ]*summary'|grep -v 'Added tag'|sed -r 's#^[o:| ]*summary:\W*([0-9])#  - JDK-\1#'| \
	    sed 's#^[o:| ]*summary:\W*#  - #' >> ${TMPDIR}/fixes2;
	hg log -v -r "tag('$NEW_RELEASE'):tag('$OLD_RELEASE') - tag('$OLD_RELEASE')" -R $REPO/$repos -G -M ${REPO}/${SUBDIR} | \
	    egrep '^[o:| ]*[0-9]{7}'|sed -r 's#^[o:| ]*([0-9]{7})#  - JDK-\1#' >> ${TMPDIR}/fixes3;
    else
	git -C ${REPO} log --no-merges --pretty=format:%B ${NEW_RELEASE}...${OLD_RELEASE} -- ${SUBDIR} |egrep '^[0-9]{7}' | \
	    sed -r 's#^([0-9])#  - JDK-\1#' >> ${TMPDIR}/fixes2;
	touch ${TMPDIR}/fixes3 ; # unused
    fi
done

sort ${TMPDIR}/fixes2 ${TMPDIR}/fixes3 | uniq > ${TMPDIR}/fixes
rm -f ${TMPDIR}/fixes2 ${TMPDIR}/fixes3

echo "In ${TMPDIR}/fixes:"
cat ${TMPDIR}/fixes
