# Exercise 5: Upgrade Mender

## Step 1: Update new values in the configmap

```
cp ../exercise-4/mender-custom-values.yml ./mender-custom-values.yml
```

Edit the file:

```
sed -i 's/3.6.4/3.7.4/g' mender-custom-values.yml
```

## Step 2: update the configmap
```
kubectl create configmap mender-custom-values \
    --from-file=mender-custom-values.yml \
    --namespace mender \
    -o yaml --dry-run=client | kubectl apply -f -
```
