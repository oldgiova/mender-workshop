# Exercise 0: Lab Setup

## Step 1: Kubernetes setup
From the [Mender Doc](https://docs.mender.io/3.6/server-installation/production-installation-with-kubernetes/kubernetes)

Example with KinD:
```
cat >kind-config.yaml <<EOF
# three node (two workers) cluster config
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
- role: worker
- role: worker
EOF

kind create cluster --name menderworkshop --config kind-config.yaml
```

## Step 2: Ingress setup

Skip this step is you're using a cloud provider that provides a LoadBalancer service.
Example using KinD:

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

## Step 2: Setup certificates

```
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --version v1.14.5 \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```

### Option 1: http01 solver
```
export LETSENCRYPT_SERVER_URL="https://acme-v02.api.letsencrypt.org/directory"
export LETSENCRYPT_EMAIL="your-email@example.com"

cat >issuer-letsencrypt.yml <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    server: ${LETSENCRYPT_SERVER_URL}
    email: ${LETSENCRYPT_EMAIL}
    privateKeySecretRef:
      name: letsencrypt
    solvers:
    - http01:
        ingress: {}
EOF

kubectl apply -f issuer-letsencrypt.yml
```


### Option 2: self-signed certificates

Create Mender namespace and certificate

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: mender
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: cluster-selfsigned-ca
  namespace: mender
spec:
  isCA: true
  commonName: cluster-selfsigned-ca
  secretName: root-secret
  privateKey:
    algorithm: ECDSA
    size: 256
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
    group: cert-manager.io
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt
  namespace: mender
spec:
  ca:
    secretName: root-secret
EOF
```

Then install the CA certificate in the browser

```
kubectl get secret -n mender root-secret -o jsonpath='{.data.ca\.crt}' | base64 -d > local-ca.crt

sudo cp local-ca.crt /usr/local/share/ca-certificates
sudo update-ca-certificates
```


## Cluster cleanup
When you finished your lab, you can delete the cluster with:
```
kind delete cluster --name menderworkshop
```
