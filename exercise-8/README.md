# Exercise 8: Adding Helm Chart Smoke Tests

## Step 1: Modify the configmap

```
cp ../exercise-5/mender-custom-values.yml ./mender-custom-values.yml
```

Edit the file:

```
cat <<-EOF >> ./mender-custom-values.yml

tests:
  enabled: true

EOF
```

## Step 2: update the configmap
```
kubectl create configmap mender-custom-values \
    --from-file=mender-custom-values.yml \
    --namespace mender \
    -o yaml --dry-run=client | kubectl apply -f -
```
And wait for the deployment to finish.

## Step 3: Perform a manual test
```
helm test mender -n mender


NAME: mender
LAST DEPLOYED: Fri May 31 12:10:12 2024
NAMESPACE: mender
STATUS: deployed
REVISION: 4
TEST SUITE:     mender-nats-test-request-reply
Last Started:   Fri May 31 14:12:11 2024
Last Completed: Fri May 31 14:12:13 2024
Phase:          Succeeded
TEST SUITE:     mender-test-mender
Last Started:   Fri May 31 14:12:14 2024
Last Completed: Fri May 31 14:12:19 2024
Phase:          Succeeded
NOTES:
Mender v3.7.4 has been deployed!

Thank you for using Mender.
Release name: mender
```

## Step 4: Update the Mender Helmrelease to enable tests after every deployment

```
cat <<EOF | kubectl apply -f -
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: mender
  namespace: mender
spec:
  chart:
    spec:
      chart: mender
      sourceRef:
        kind: GitRepository
        name: mender
        namespace: mender
      valuesFiles:
      - values.yaml
  install:
    remediation:
      ignoreTestFailures: false
      remediateLastFailure: true
      retries: 1
  interval: 1m0s
  releaseName: mender
  targetNamespace: mender
  upgrade:
    cleanupOnFail: true
    remediation:
      ignoreTestFailures: false
      remediateLastFailure: true
      retries: 1
      strategy: rollback
  test:
    enable: true
  valuesFrom:
  - kind: ConfigMap
    name: mender-custom-values
    valuesKey: mender-custom-values.yml
EOF
```
