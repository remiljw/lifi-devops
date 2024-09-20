#!/bin/bash
RELEASE_NAME="lifi"
NAMESPACE="lifi-bird-stack"
MY_IP=$(curl http://checkip.amazonaws.com)

# Update and install dependencies
sudo apt-get update
sudo apt-get install -y curl git
sudo apt install -y apache2-utils
    
# Install Docker
sudo apt install -y docker.io
sudo usermod -aG docker ubuntu

# Install Kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install conntrack
sudo apt install conntrack

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
#Install k3s
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san $MY_IP"  sh -s

#Setup Config
sudo mkdir -p $HOME/.kube
sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#Disable firewall
sudo ufw disable
sudo ufw allow 6443/tcp #apiserver
sudo ufw allow from 10.42.0.0/16 to any #pods
sudo ufw allow from 10.43.0.0/16 to any #services
   
# Wait for k3s to be ready
until kubectl get nodes; do
    sleep 10
done

# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
wait 10

#Update ArgoCD password
kubectl patch secret -n argocd argocd-secret \
  -p '{"stringData": { "admin.password": "'$(htpasswd -bnBC 10 "" newpassword | tr -d ':\n')'"}}'


#Setup Prometheus for monitoring application
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --version 45.1.1 -n monitoring --create-namespace --wait


echo "Waiting for prometheus pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=prometheus -n monitoring --timeout=300s

#Download Repository and install it
git clone https://github.com/remiljw/lifi-devops.git
kubectl apply -f  ./lifi-devops/manifests/argocd.yml

#Wait for the pods to be ready
echo "Waiting for application pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=$RELEASE_NAME -n $NAMESPACE --timeout=300s


kubectl apply -f  ./lifi-devops/manifests/ingress.yml

