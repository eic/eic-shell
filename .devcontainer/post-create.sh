#!/bin/bash

set -e

for dir in /workspace/* ; do
  git config --global --add safe.directory "$dir"
done
git config --global commit.gpgsign false

pip install --user uproot matplotlib seaborn pandas jupyter jupyterlab

echo 'EIC Development Environment Ready!'
echo 'Available tools: geant4, ROOT, DD4hep, Acts, Epic, EICrecon'
echo 'Data analysis: jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root'
echo 'Use eic-info for software versions'