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
export MONGODB_ROOT_PASSWORD=$(pwgen 32 1)
export MONGODB_REPLICA_SET_KEY=$(pwgen 32 1)
export ACCESS_KEY_ID="replace"
export SECRET_ACCESS_KEY="replace"
export AWS_URI="replace-with-your-uri"
export AWS_BUCKET="replace-with-your-bucket"

cat >mender-3.6.4.yml <<EOF
global:
  enterprise: true
  image:
    username: "${MENDER_REGISTRY_USERNAME}"
    password: "${MENDER_REGISTRY_PASSWORD}"
    tag: ${MENDER_VERSION_TAG}
  mongodb:
    URL: ""
  nats:
    URL: ""
  s3:
    AWS_URI: "${AWS_URI}"
    AWS_BUCKET: "${AWS_BUCKET}"
    AWS_REGION: "us-east-1"
    AWS_FORCE_PATH_STYLE: "true"
    AWS_ACCESS_KEY_ID: "${ACCESS_KEY_ID}"
    AWS_SECRET_ACCESS_KEY: "${SECRET_ACCESS_KEY}"
  url: "${MENDER_SERVER_URL}"

default:
  updateStrategy:
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 100%

# This enables bitnami/mongodb sub-chart
mongodb:
  enabled: true
  auth:
    enabled: true
    rootPassword: ${MONGODB_ROOT_PASSWORD}
    replicaSetKey: ${MONGODB_REPLICA_SET_KEY}

# This enabled nats sub-chart
nats:
  enabled: true

ingress:
  enabled: true
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/proxy-buffering: "off"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    cert-manager.io/issuer: "letsencrypt"
  path: /
  ingressClassName: nginx
  hosts:
    - ${MENDER_SERVER_DOMAIN}
  tls:
  # this secret must exists or it can be created from a working cert-manager instance
   - secretName: mender-ingress-tls
     hosts:
       - ${MENDER_SERVER_DOMAIN}

api_gateway:
  env:
    SSL: false

device_auth:
  certs:
    key: |-
$(cat device_auth.key | sed -e 's/^/      /g')

tenantadm:
  certs:
    key: |-
$(cat tenantadm.key | sed -e 's/^/      /g')

useradm:
  certs:
    key: |-
$(cat useradm.key | sed -e 's/^/      /g')

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
