#!/bin/bash

cd ~/customer-service

echo "deploy $1"
echo "<pre>" > ~/public_html/deploy/cs/$1.html

time grunt --no-color deploy:$1 >> ~/public_html/deploy/cs/$1.html

result=$?

exit $result
