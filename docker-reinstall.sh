#!/bin/bash

#sudo docker stop $(docker ps -q -a)
#sudo docker rm $(docker ps -q -a)
#sudo docker rmi $(docker images -q)
#sudo docker rmi $(docker images -q)
rm -rf /Users/ggu329/workspace/spacefarm-bot/Farmbot-Web-App/docker_volumes/*
docker-compose run web gem install bundler:2.1.4
docker-compose run web bundle install
docker-compose run web npm install
docker-compose run web bundle exec rails db:create db:migrate
docker-compose run web rake keys:generate d
docker-compose run web rake assets:precompile
