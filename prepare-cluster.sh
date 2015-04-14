#!/bin/bash
set -e 	# Exit immediately upon failure

rm -f ./cluster.yml || true
ln -n ./clusters/$1.yml ./cluster.yml