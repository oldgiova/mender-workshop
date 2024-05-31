# Exercise 6: Upgrade Mender Helm Chart

## Step 1: Update the Mender HelmRelease version:

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
        kind: HelmRepository
        name: mender
        namespace: mender
      valuesFiles:
      - values.yaml
      # use: version: '*' for rolling releases
      version: '>=5.7.0'
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
    enable: false
  valuesFrom:
  - kind: ConfigMap
    name: mender-custom-values
    valuesKey: mender-custom-values.yml
EOF
```
