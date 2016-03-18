#!/bin/bash

#  highlightTodo.sh
#  Tavi
#
#  Created by thislooksfun on 3/17/16.
#  Copyright © 2016 thislooksfun. All rights reserved.

buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$INFOPLIST_FILE")
buildNumber=$(($buildNumber + 1))
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "$INFOPLIST_FILE"

TAGS="TODO|FIXME"
ERRORTAG="ERROR"
find "${SRCROOT}/Tavi" \( -name "*.h" -or -name "*.m" -or -name "*.swift" \) -print0 \
    | xargs -0 egrep --with-filename --line-number --only-matching "\/\/.*($TAGS).*\$|//.*($ERRORTAG).*\$" \
    | perl -p -e "s/\/\/.*($TAGS)/ warning: \$1/" \
    | perl -p -e "s/\/\/.*($ERRORTAG)/ error: \$1/"