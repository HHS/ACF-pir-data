#!/usr/bin/env/bash

# Activate virtual environment
python3 -m venv .venv
source .venv/bin/activate

# install packages
pip install -U pip
pip install PIR_Pipeline/.

# remove old documentation and regenerate
rm -rf documentation/_autosummary
cd PIR_Pipeline/documentation
make text

cd ..