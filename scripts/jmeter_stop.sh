#!/usr/bin/env bash
#Script writtent to stop a running jmeter master test
#Kindly ensure you have the necessary kubeconfig

working_dir=`pwd`

for ctx in $(kubectl config get-contexts -o=name --kubeconfig $working_dir/clusters.yaml); do

  master_pod=`kubectl --kubeconfig $working_dir/clusters.yaml --context="${ctx}" get po | grep jmeter-master | awk '{print $1}'`

  kubectl --kubeconfig $working_dir/clusters.yaml --context="${ctx}" exec -ti $master_pod bash /jmeter/apache-jmeter-5.0/bin/stoptest.sh

done
