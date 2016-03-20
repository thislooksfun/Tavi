#!/bin/bash

#  buildDocs.sh
#  Tavi
#
#  Created by thislooksfun on 3/17/16.
#  Copyright © 2016 thislooksfun. All rights reserved.

export PATH=$(bash -l -c 'echo $PATH')
export GEM_HOME=$(bash -l -c 'echo $GEM_HOME')

jazzy \
  --clean \
  --author thislooksfun \
  --github_url https://github.com/thislooksfun/Tavi \
  --module Tavi \
  --output docs/swift \
  --min-acl internal
# --skip-undocumented   TODO: Add this once code is sufficiently documented (Don't forget to put a backslash on the previous line!)