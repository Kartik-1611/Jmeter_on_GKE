#!/usr/bin/env bash

working_dir=`pwd`

# For every cluster present, create Deployments and Services located in the 'manifests' folder
# The contexts are retreived from the 'clusters.yaml' file.

for ctx in $(kubectl config get-contexts -o=name --kubeconfig $working_dir/clusters.yaml); do
  kubectl --kubeconfig $working_dir/clusters.yaml --context="${ctx}" create -f $working_dir/manifests/
done
