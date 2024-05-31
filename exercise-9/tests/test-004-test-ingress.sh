#!/bin/bash
# Copyright 2023 Northern.tech AS
#    
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

echo -n "> Waiting for the Ingress Load Balancer to become ready"
n=0
max_wait=512
while [ $n -lt $max_wait ]; do
    sleep 1
    LB_HOSTNAME=$(kubectl get ing -n mender mender-ingress --no-headers -o custom-columns=HOST:".status.loadBalancer.ingress[0].hostname")
    if [ -n "${LB_HOSTNAME}" ] ; then
        echo -e "\n> LB is ready: ${LB_HOSTNAME}"
        break
    fi
    echo -n "."
    n=$((n+1))
done

if [ $n -ge $max_wait ]; then
    echo -e "\n> Ingress is not ready, aborting"
    kubectl get ing -A
    exit 1
fi

