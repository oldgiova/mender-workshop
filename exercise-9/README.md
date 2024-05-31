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
