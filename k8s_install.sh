#!/bin/bash
# - Script to install Minikube cluster and its dependencies
# - v1.0.0 by Wagner daS Andre

if [ -z $1 ]; then
  echo -e "Usage: ./k8s_install.sh [CLUSTER_NAME]"
  echo -e
  echo -e "Default cluster name: minikube"
  echo -e "Do you like to continue with default cluster name? (y/n)"
  read Q
  if [ $Q == "y" -o $Q == "Y" -o $Q == "yes" ]; then    
    CLUSTER_NAME="minikube"
  else
    echo -e "Skipping..."
    exit 0
  fi
else
  CLUSTER_NAME=$1
fi

SYSTEM=$(uname)

# Function
install_minikube(){
  echo -e "Minikube Installation"
  echo -e -----------------------
  # Check minikube installation
  if [ -e /usr/local/bin/minikube -o -e /usr/bin/minikube ];then
    echo -e "Minikube already installed"
    echo -e "Skipping installation..."
    echo -e ----------------------------
  else
    echo -e "Checking if Docker is installed, otherwise install it"
    echo -e -------------------------------------------------------

    if [ -e /usr/bin/docker -o -e /usr/local/bin/docker ]; then
      echo -e "Docker already installed"
      echo -e --------------------------
    else
      echo -e "Setup the repository for Docker installation"
      echo -e ----------------------------------------------

      # Update the apt package index and install packages to allow apt to use a repository over HTTPS:
      sudo apt-get update
      sudo apt-get install -y \
      ca-certificates \
      curl \
      gnupg \
      lsb-release
      # Add Docker’s official GPG key:
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      
      # Use the following command to set up the stable repository
      echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
      echo -e "Installing Docker Engine"
      echo -e --------------------------
      sudo apt-get update
      sudo apt-get install -y docker-ce docker-ce-cli containerd.io

      echo -e "Add user to the docker group"
      echo -e ------------------------------
      sudo usermod -aG docker $USER && newgrp docker

      echo -e "Verifying Docker installation"
      echo -e -------------------------------
      docker run hello-world
      if [ $? != 0 ]; then
        echo -e "Something get wrong. Exiting..."
        echo -e ---------------------------------
        exit 1
      fi

    fi
    echo -e "Installing Minikube"
    echo -e ---------------------
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube

    echo -e "Removing installation file"
    echo -e ----------------------------
    rm -rf minikube-linux-amd64
  fi
}

install_minikube
if [ $? != 0 ]; then
  echo -e "Something get wrong. Please check the Minikube installation."
  echo -e --------------------------------------------------------------
  exit 1
fi

echo -e "Creating Cluster name:${CLUSTER_NAME}"
echo -e -----------------------
#minikube start -p ${CLUSTER_NAME} --extra-config=apiserver.service-node-port-range=1-65535
minikube start -p ${CLUSTER_NAME}
if [ $? != 0 ]; then
  echo -e "Something get wrong. Please check the Minikube output log!"
  exit 1
else
  minikube status -p ${CLUSTER_NAME}
  echo -e ---------------------------------------------------
  echo -e "Your cluster ${CLUSTER_NAME} is ready to be used!"
  echo -e ---------------------------------------------------
fi