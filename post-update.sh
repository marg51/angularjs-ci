#!/bin/bash



cd ~/customer-service && git fetch && git checkout origin/$1

echo "<pre>" > ~/public_html/build/cs/$2.html
karma start karma-ci.conf.js >> ~/public_html/build/cs/$2.html
result=$?
echo $result

# sleep 0.4
mv /tmp/html-report.html ~/public_html/build/cs/$2.html

exit $result
