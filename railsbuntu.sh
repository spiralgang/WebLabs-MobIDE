#!/bin/bash

print_step() {
  local fmt="$1"; shift

  # shellcheck disable=SC2059
  printf "\n\n------------$fmt-------------\n\n" "$@"
}

sudo apt-get update

# Install and setup PostgreSQL ################################################

print_step "Checking Postgres installation"
if ! dpkg -s postgresql; then
  sudo apt-get install -y postgresql postgresql-contrib
  sudo service postgresql start
fi

# Install Asdf ###############################################################

print_step "Checking Asdf version manager"
if ! asdf --version; then
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.5.0
  echo '. $HOME/.asdf/asdf.sh' >> ~/.bashrc
  echo '. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc
  # Restart bash
  . $HOME/.bashrc

  asdf plugin-add ruby
  asdf plugin-add nodejs
  bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
fi


# Install Redis ###############################################################

print_step "Checking Redis installation"
if ! dpkg -s redis-server; then
  sudo apt-get install -y redis-server
fi

# Install Node.js #############################################################

print_step "Checking for Node.js"
if ! node --version; then
  asdf install nodejs 10.5.0
  asdf global nodejs 10.5.0
fi

# Install Yarn #############################################################

print_step "Checking for Yarn"
if ! yarn --v; then
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
  sudo apt-get update && sudo apt-get install -y yarn
fi


# Ruby and Version Manager ####################################################

print_step "Checking for Ruby"
if ! ruby -v; then
  sudo apt-get install -y curl
  sudo apt-get install -y libssl1.0-dev
  # Capybara dependencies
  sudo apt-get install -y qt5-default libqt5webkit5-dev gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-x
  asdf install ruby 2.5.1
  asdf global ruby 2.5.1
fi


# Install Heroku CLI ##########################################################

print_step "Checking for Heroku CLI"
if ! heroku --version; then
  wget -qO- https://cli-assets.heroku.com/install-ubuntu.sh | sh
fi

# Install Ngrok exposer ######################################################

print_step "Checking for Ngrok"
if ! ngrok; then
  sudo apt install -y unzip
  wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip
  sudo unzip ngrok-stable-linux-amd64.zip -d /usr/local/bin
  rm -rf ngrok-stable-linux-amd64.zip
fi

# Install Elasticsearch #################################################

print_step "Elasticsearch"
if ! systemctl is-active elasticsearch.service; then
  # Remove Java 10 (non supported)
  sudo apt-get purge -y openjdk-\* icedtea-\* icedtea6-\*

  sudo apt install -y openjdk-8-jre apt-transport-https wget nginx
  wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
  sudo echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" > /etc/apt/sources.list.d/elastic.list
  sudo apt update
  sudo apt install elasticsearch
  sudo systemctl start elasticsearch
fi


# Cleaning up #################################################################

print_step "Removing unused software..."
sudo apt autoremove -y
