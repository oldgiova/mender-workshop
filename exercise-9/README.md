# Mender helm chart tests

## Credits: https://github.com/mendersoftware/mender-helm/tree/master/tests

## Requirements
* You have Mender successfully installed in a Kubernetes cluster
* Mender is running in a namespace named `mender`

## Note
Please note that this test is creating users and tenants in the Mender server.
Please make sure that the environment is clean before make it production ready.

## Step 1: run the tests

```bash
bash -c ./tests/tests.sh
```


## Step 2: cleanup the tenants

Connect to MongoDB:
```bash
SECRET=$(kubectl get secret mongodb-common -n mender -o jsonpath='{.data.MONGO_URL}' |base64 -d)
kubectl run -n mender mongosh -it --rm=true --attach=true --image=rtsp/mongosh:1.5.4 --restart=Never -- bash -c "mongosh $SECRET"
```

Find the tenants:
```
use tenantadm;

db.tenants.find({"name":{$regex: '^demo-', $options: 'i'}});

db.tenants.updateMany({"name":{$regex: '^demo-', $options: 'i'}},{$set: {"status": "suspended"}} );

exit
```
