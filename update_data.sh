#!/bin/bash
git submodule update --remote
git add data
git commit -m"Updating torrents-csv-data."
git push
