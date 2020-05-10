#!/bin/bash
set -e
set -u
set -o xtrace

GH_USER=$1
GH_PASS=$2
GH_TOKEN=$3
DEPLOYMENT_REPO=$4
DH_USER=$5
DH_PASS=$6
AWS_KEY_ID=$7
AWS_KEY=$8
CLUSTER_NAME=$9


#Wait for sealed-secrets container to be running
echo "Waiting for sealed-secrets pod to be ready..."
ATTEMPTS=0
until kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=sealed-secrets -n capstone-adm --timeout=120s || [ $ATTEMPTS -eq 60 ]; do
  ATTEMPTS=$((ATTEMPTS + 1))
  sleep 1
done


git clone https://github.com/$GH_USER/$DEPLOYMENT_REPO.git deployment
cd deployment

#Create secrets necessary for jenkins
kubeseal --fetch-cert \
--controller-namespace=capstone-adm \
--controller-name=sealed-secrets \
> pub-cert.pem

kubectl create secret docker-registry regcred --dry-run --docker-username=florianseidel --docker-password=test -o yaml

kubectl create secret docker-registry regcred \
	--namespace capstone-build  \
	--docker-username=$DH_USER --docker-password=$DH_PASS \
	--dry-run \
	-o json > reg-cred.json

kubeseal --format=yaml --cert=pub-cert.pem < reg-cred.json > releases/capstone-build/reg-cred.yaml

rm reg-cred.json
cat releases/capstone-build/reg-cred.yaml

git add releases/capstone-build/reg-cred.yaml

kubectl -n capstone-build create secret generic jenkins-secret \
        --from-literal=GITHUB_USER=$GH_USER \
        --from-literal=GITHUB_PW=$GH_PASS \
        --from-literal=GITHUB_TOKEN=$GH_TOKEN \
        --from-literal=DOCKERHUB_USER=$DH_USER \
        --from-literal=DOCKERHUB_PW=$DH_PASS \
        --dry-run \
        -o json > jenkins-secret.json

kubeseal --format=yaml \
         --cert=pub-cert.pem \
         < jenkins-secret.json \
         > releases/capstone-build/jenkins-secret.yaml

rm jenkins-secret.json

git add releases/capstone-build/jenkins-secret.yaml
git commit -m "Add Jenkins password secret" || true


echo -ne "[default]\nregion = eu-central-1" > config
echo -ne "[default]\naws_access_key_id = ${AWS_KEY_ID}\naws_secret_access_key = ${AWS_KEY}" > credentials
kubectl create secret generic aws-credentials --from-file=credentials --from-file=config \
        -n capstone-build \
        --dry-run \
        -o json > aws-credentials-secret.json
rm credentials
rm config
kubeseal --format=yaml \
         --cert=pub-cert.pem \
         < aws-credentials-secret.json \
         > releases/capstone-build/aws-credentials-secret.yaml
rm aws-credentials-secret.json

git add releases/capstone-build/aws-credentials-secret.yaml
git commit -m "AWS Credentials" || true

git push
rm pub-cert.pem

# Only here for historical reasons.
# Tried to use kubetl by configuring aws credentials and kubeconfig before fully understanding RBAC service roles...
#../flux/./create-kube-config.sh $CLUSTER_NAME
#kubectl create configmap kube-config --from-file=config \
#        -n capstone-build \
#        --dry-run \
#        -o yaml > releases/capstone-build/kube-config.yaml
#git add releases/capstone-build/kube-config.yaml
#git commit -m "Add Kube config" || true
#git push
#rm config

kubeseal --fetch-cert \
--controller-namespace=capstone-adm \
--controller-name=sealed-secrets \
> pub-cert.pem

kubectl create secret docker-registry regcred \
	--namespace capstone-dev  \
	--docker-username=$DH_USER --docker-password=$DH_PASS \
	--dry-run \
	-o json > reg-cred.json
kubeseal --format=yaml --cert=pub-cert.pem < reg-cred.json > releases/capstone-dev/reg-cred.yaml
rm reg-cred.json
cat releases/capstone-dev/reg-cred.yaml
git add releases/capstone-dev/reg-cred.yaml

kubectl create secret docker-registry regcred \
	--namespace capstone-stag  \
	--docker-username=$DH_USER --docker-password=$DH_PASS \
	--dry-run \
	-o json > reg-cred.json
kubeseal --format=yaml --cert=pub-cert.pem < reg-cred.json > releases/capstone-stag/reg-cred.yaml
rm reg-cred.json
cat releases/capstone-stag/reg-cred.yaml
git add releases/capstone-stag/reg-cred.yaml


kubectl create secret docker-registry regcred \
	--namespace capstone-prod-blue  \
	--docker-username=$DH_USER --docker-password=$DH_PASS \
	--dry-run \
	-o json > reg-cred.json
kubeseal --format=yaml --cert=pub-cert.pem < reg-cred.json > releases/capstone-prod-blue/reg-cred.yaml
rm reg-cred.json
cat releases/capstone-prod-blue/reg-cred.yaml
git add releases/capstone-prod-blue/reg-cred.yaml

kubectl create secret docker-registry regcred \
	--namespace capstone-prod-green  \
	--docker-username=$DH_USER --docker-password=$DH_PASS \
	--dry-run \
	-o json > reg-cred.json
kubeseal --format=yaml --cert=pub-cert.pem < reg-cred.json > releases/capstone-prod-green/reg-cred.yaml
rm reg-cred.json
cat releases/capstone-prod-green/reg-cred.yaml
git add releases/capstone-prod-green/reg-cred.yaml

(git commit -a -m "Add docker registry credentials." || true) && git push
