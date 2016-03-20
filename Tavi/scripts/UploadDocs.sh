#!/bin/bash

#  highlightTodo.sh
#  Tavi
#
#  Created by thislooksfun on 3/19/16.
#  Copyright © 2016 thislooksfun. All rights reserved.

echo "Creating docs"
bash ./Tavi/scripts/BuildDocs.sh

echo
echo "Adding docs to pages"
cp -r ./docs/ ~/Desktop/Programming/GitHub/Pages/Tavi/
cd ~/Desktop/Programming/GitHub/Pages/Tavi/
rm -rf ./docs
mv ./swift ./docs

echo
echo "Updating pages"
git add -A
git commit -m "Automatically updated docs"
exit 1
git push origin gh-pages
echo "Documentation update complete! Updates are live at https://thislooksfun.github.io/Tavi/docs"