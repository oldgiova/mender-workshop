#!/bin/bash


SECRET=$(kubectl get secret mongodb-common -n mender -o jsonpath='{.data.MONGO_URL}' |base64 -d)
kubectl run -n mender mongosh --image=rtsp/mongosh:1.5.4 --restart=Never
kubectl cp -n mender mongo_cleanup.js mongosh:/mongo_cleanup.js
kubectl exec -n mender mongosh -- bash -c "mongosh $SECRET -f /mongo_cleanup.js"
kubectl delete pod -n mender mongosh

