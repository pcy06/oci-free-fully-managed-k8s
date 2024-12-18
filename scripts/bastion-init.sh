
cd /home/ubuntu

wget https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh
chmod 755 install.sh
su -c './install.sh --accept-all-defaults' - ubuntu
rm -f install.sh

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
sudo rm -f kubectl

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
sudo rm -f get_helm.sh

echo "export OCI_CLI_AUTH=instance_principal" >> /home/ubuntu/.bashrc
until sudo -u ubuntu OCI_CLI_AUTH=instance_principal CLUSTER_ID=$CLUSTER_ID REGION=$REGION /home/ubuntu/bin/oci ce cluster create-kubeconfig --cluster-id $CLUSTER_ID --file /home/ubuntu/.kube/config --region $REGION --token-version 2.0.0 --kube-endpoint PRIVATE_ENDPOINT; do
  echo "Retrying in 10 seconds..."
  sleep 10
done

chown -R ubuntu:ubuntu /home/ubuntu/.kube
chmod -R 700 /home/ubuntu/.kube

echo "Bastion Host Initialization Complete!"