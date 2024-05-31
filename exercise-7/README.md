# Exercise 4: Mender Setup 

## Step 1: Create the GitRepository resource

```
cat <<EOF | kubectl apply -f -
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: mender
  namespace: mender
spec:
  interval: 1m0s
  ref:
    branch: master
  timeout: 5m0s
  url: https://github.com/oldgiova/mender-helm
EOF
```

You should see the source controller storing artifacts:

```
kubectl describe gitrepository mender -n mender                                                  
Name:         mender
Namespace:    mender
Labels:       <none>
Annotations:  <none>
API Version:  source.toolkit.fluxcd.io/v1
Kind:         GitRepository
Metadata:
  Creation Timestamp:  2024-05-30T08:57:22Z
  Finalizers:
    finalizers.fluxcd.io
  Generation:        1
  Resource Version:  3383
  UID:               e6f17d67-5baa-43b0-97fb-07bf8ffabd31
Spec:
  Interval:  1m0s
  Ref:
    Branch:  MC-7452-helm-smoke-tests
  Timeout:   5m0s
  URL:       https://github.com/oldgiova/mender-helm
Status:
  Artifact:
    Digest:            sha256:3356bd992d1e64e822da9a1aa7d578b8be3e9aa66ea12e06d4ac4153a66e42d3
    Last Update Time:  2024-05-30T08:57:23Z
    Path:              gitrepository/mender/mender/439dad8eee94c93eb8f125b5b678c0654a290c48.tar.gz
    Revision:          MC-7452-helm-smoke-tests@sha1:439dad8eee94c93eb8f125b5b678c0654a290c48
    Size:              272304
    URL:               http://source-controller.flux-system.svc.cluster.local./gitrepository/mender/mender/439dad8eee94c93eb8f125b5b678c0654a290c48.tar.gz
  Conditions:
    Last Transition Time:  2024-05-30T08:57:23Z
    Message:               stored artifact for revision 'MC-7452-helm-smoke-tests@sha1:439dad8eee94c93eb8f125b5b678c0654a290c48'
    Observed Generation:   1
    Reason:                Succeeded
    Status:                True
    Type:                  Ready
    Last Transition Time:  2024-05-30T08:57:23Z
    Message:               stored artifact for revision 'MC-7452-helm-smoke-tests@sha1:439dad8eee94c93eb8f125b5b678c0654a290c48'
    Observed Generation:   1
    Reason:                Succeeded
    Status:                True
    Type:                  ArtifactInStorage
  Observed Generation:     1
Events:
  Type    Reason       Age   From               Message
  ----    ------       ----  ----               -------
  Normal  NewArtifact  12s   source-controller  stored artifact for commit 'chore: removing helm chart label'

```

## Step 2: Prepare your values file

```
cp ../exercise-5/mender-custom-values.yml mender-custom-values.yml

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
        kind: GitRepository
        name: mender
        namespace: mender
      valuesFiles:
      - mender/values.yaml
  install:
    createNamespace: false
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
