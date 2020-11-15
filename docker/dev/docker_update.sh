#!/bin/sh
sudo docker build ../../ --file ../dev/Dockerfile -t torrents-csv:latest
sudo docker-compose up -d
