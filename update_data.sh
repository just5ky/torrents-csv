#!/bin/bash
git submodule update --remote
git add data
git add ui
git commit -m"Updating torrents-csv-data."
git push
