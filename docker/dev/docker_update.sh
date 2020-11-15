#!/bin/sh
sudo docker build ../../ --file ../dev/Dockerfile -t torrents-csv-server:latest
sudo docker-compose up -d
