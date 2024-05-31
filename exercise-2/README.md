# Exercise 2: Mender upgrade


## Step 2: Adapt the values.yaml file

```
cp ../exercise-1/mender-3.6.4.yml ./mender-3.7.4.yml
```

Edit the file:

```
sed -i 's/3.6.4/3.7.4/g' mender-3.7.4.yml
```

## Step 3: Upgrade the Mender server

```
helm upgrade --install mender mender/mender --namespace mender --wait -f mender-3.7.4.yml
```
