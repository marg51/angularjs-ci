#!/bin/bash

cd ../karma && git fetch && git checkout origin/$1

karma start karma.conf.js
result=$?


sleep 0.4
cp /tmp/html-report.html > ../git/build/$2.html

exit $result