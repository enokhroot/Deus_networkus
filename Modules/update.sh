#!/bin/bash

path_to_script=$1
cd $path_to_script/Deus_networkus
git pull origin master
cp $path_to_script/Deus_networkus/config_ssh.txt /home/$USER/.ssh/config