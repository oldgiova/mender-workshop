# Exercise 1: Mender setup with SubCharts


## Step 1: Device authentication keys

```
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 | openssl rsa -out device_auth.key
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 | openssl rsa -out useradm.key
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 | openssl rsa -traditional -out tenantadm.key
```

## Step 2: add Mender helm repo
```
helm repo add mender https://charts.mender.io
helm repo update
```


## Step 3: create and customize your values.yaml file
```
export MENDER_REGISTRY_USERNAME="replace-with-your-username"
export MENDER_REGISTRY_PASSWORD="replace-with-your-password"
export MENDER_SERVER_DOMAIN="mender.example.com"
export MENDER_SERVER_URL="https://${MENDER_SERVER_DOMAIN}"
export MENDER_VERSION_TAG="mender-3.6.4"
export MONGODB_EXISTING_SECRET="replace-with-your-secret"
export AZURE_CONNECTION_STRING="replace"
export AZURE_CONTAINER_NAME="replace"
export TLS_SECRET_NAME="optionally-replace"

cat >mender-3.6.4.yml <<EOF
global:
  enterprise: true
  image:
    username: "${MENDER_REGISTRY_USERNAME}"
    password: "${MENDER_REGISTRY_PASSWORD}"
    tag: ${MENDER_VERSION_TAG}
  mongodb:
    existingSecret: "${MONGODB_EXISTING_SECRET}"
    URL: ""
  nats:
    URL: ""
  storage: azure
  azure:
    AUTH_CONNECTION_STRING: "${AZURE_CONNECTION_STRING}"
    CONTAINER_NAME: "${AZURE_CONTAINER_NAME}"
  url: "${MENDER_SERVER_URL}"

default:
  updateStrategy:
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 100%

# This enables bitnami/mongodb sub-chart
mongodb:
  enabled: false

# This enabled nats sub-chart
nats:
  enabled: true


ingress:
  enabled: true
  annotations:
    appgw.ingress.kubernetes.io/backend-protocol: http
    appgw.ingress.kubernetes.io/health-probe-path: /ui/
    appgw.ingress.kubernetes.io/request-timeout: "600"
    appgw.ingress.kubernetes.io/ssl-redirect: "true"
  ingressClassName: azure/application-gateway
  path: /
  hosts:
    - ${MENDER_SERVER_DOMAIN}
  tls:
  # this secret must exists or it can be created from a working cert-manager instance
   - secretName: ${TLS_SECRET_NAME}
     hosts:
       - ${MENDER_SERVER_DOMAIN}

api_gateway:
  env:
    SSL: false

device_auth:
  certs:
    existingSecret: "you-secret-here"

tenantadm:
  certs:
    existingSecret: "you-secret-here"

useradm:
  certs:
    existingSecret: "you-secret-here"

EOF

```

## Step 4 [optional]: create the Ingress certificate:
Use the following config only if the ingress has not the following annotation:
```
    cert-manager.io/issuer: "letsencrypt"
```

Config:
```
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: mender-ingress-tls
  namespace: mender
spec:
  secretName: mender-ingress-tls
  issuerRef:
    name: letsencrypt
    kind: Issuer
  dnsNames:
  - ${MENDER_SERVER_DOMAIN}
EOF
```

## Step 5: Deploy the cluster
Now deploy the cluster:
```
helm upgrade --install mender mender/mender --namespace mender --wait -f mender-3.6.4.yml

```

## Step 6: Access the Mender server
```
TENANTADM_POD=$(kubectl get pod -l 'app.kubernetes.io/component=tenantadm' -o name -n mender | head -1)
TENANT_ID=$(kubectl exec $TENANTADM_POD -n mender -- tenantadm create-org --name demo --username "admin@mender.io" --password "adminadmin" --plan enterprise)
USERADM_POD=$(kubectl get pod -l 'app.kubernetes.io/component=useradm' -o name -n mender | head -1)
kubectl exec $USERADM_POD -n mender -- useradm-enterprise create-user --username "demo@mender.io" --password "demodemo" --tenant-id $TENANT_ID
```
