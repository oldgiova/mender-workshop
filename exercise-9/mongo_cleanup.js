use tenantadm;
printjson(db.tenants.find({"name":{$regex: '^demo-', $options: 'i'}}));
db.tenants.updateMany({"name":{$regex: '^demo-', $options: 'i'}},{$set: {"status": "suspended"}} );
exit
