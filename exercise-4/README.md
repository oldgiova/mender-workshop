# Exercise 4: Mender Setup 

## Step 1: Create the helmRepository resource

```
cat <<EOF | kubectl apply -f -
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: mender
  namespace: mender
spec:
  interval: 5m
  url: https://charts.mender.io
EOF
```

You should see the source controller storing artifacts:

```
kubectl describe helmrepository mender -n mender

Status:
  Artifact:
    Digest:            sha256:0047e79ac46913017deffa061ce0a7ec0ee37efad3545e4023920ec57857a194
    Last Update Time:  2024-05-29T22:16:28Z
    Path:              helmrepository/mender/mender/index-0627dc1e828bfd1cc88743b191c732159dfc6cdcbd1fb7bb4349a66fe8999d7c.yaml
    Revision:          sha256:0627dc1e828bfd1cc88743b191c732159dfc6cdcbd1fb7bb4349a66fe8999d7c
    Size:              60877
    URL:               http://source-controller.flux-system.svc.cluster.local./helmrepository/mender/mender/index-0627dc1e828bfd1cc88743b191c732159dfc6cdcbd1fb7bb4349a66fe8999d7c.yaml
  Conditions:
    Last Transition Time:  2024-05-29T22:16:28Z
    Message:               stored artifact: revision 'sha256:0627dc1e828bfd1cc88743b191c732159dfc6cdcbd1fb7bb4349a66fe8999d7c'
    Observed Generation:   1
    Reason:                Succeeded
    Status:                True
    Type:                  Ready
    Last Transition Time:  2024-05-29T22:16:28Z
    Message:               stored artifact: revision 'sha256:0627dc1e828bfd1cc88743b191c732159dfc6cdcbd1fb7bb4349a66fe8999d7c'
    Observed Generation:   1
    Reason:                Succeeded
    Status:                True
    Type:                  ArtifactInStorage
  Observed Generation:     1
  URL:                     http://source-controller.flux-system.svc.cluster.local./helmrepository/mender/mender/index.yaml
Events:
  Type    Reason       Age   From               Message
  ----    ------       ----  ----               -------
  Normal  NewArtifact  25s   source-controller  stored fetched index of size 60.88kB from 'https://charts.mender.io'
```

## Step 2: Prepare your values file

```
cp ../exercise-1/mender-3.6.4.yml mender-custom-values.yml
```

## Step 3: create a configmap
```
kubectl create configmap mender-custom-values --from-file=mender-custom-values.yml --namespace mender
```

## Step 4: Create the Mender HelmRelease

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
      version: '5.7.0'
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
