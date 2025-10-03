#!/bin/bash

function printStatus
{
  echo "=== [OK] $1 ==="
}

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

source ~/.nvm/nvm.sh && printStatus "nvm sourced"

nvm install --lts && printStatus "Node and npm installed"

git clone https://github.com/lewenhagen/maxlew_videosystem_node.git "$HOME/maxlew_videosystem" && printStatus "Maxlew Videosystem cloned" 

# source ~/.nvm/nvm.sh

npm install

