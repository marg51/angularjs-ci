#!/bin/bash

cd ../karma && git fetch && git checkout origin/$1

karma start karma.conf.js > ../git/build/$2.html
result=$?


# sleep 0.4
mv /tmp/html-report.html ../git/build/$2.html

exit $result