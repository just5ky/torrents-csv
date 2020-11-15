#!/bin/sh
git checkout master

# Creating the new tag
new_tag="$1"
git tag $new_tag

# Changing the docker-compose prod
sed -i "s/dessalines\/torrents-csv-server:.*/dessalines\/torrents-csv-server:$new_tag/" ../prod/docker-compose.yml
git add ../prod/docker-compose.yml

# The commit
git commit -m"Upping version."

# git push origin $new_tag
# git push

# Rebuilding docker
sudo docker build ../../ --file ../prod/Dockerfile -t torrents-csv-server:latest
sudo docker tag torrents-csv-server:latest dessalines/torrents-csv-server:$new_tag
sudo docker push dessalines/torrents-csv-server:$new_tag

# SSH and pull it
# ssh tyler@45.55.175.59 "cd ~/git/torrents.csv/scripts/ && ./git_update.sh && cd ../docker/prod && git pull && docker-compose up -d"
