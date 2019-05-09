#!/usr/bin/env bash
#Script created to launch Jmeter tests directly from the current terminal without accessing the jmeter master pod.
#It requires that you supply the path to the jmx file
#After execution, test script jmx file may be deleted from the pod itself but not locally.

# This test can be used to run specific JMX on specific clusters
# You need to name the JMX file as jmeter-{region}.jmx to select the jmx for the cluster in the specifid {region}.

working_dir=`pwd`

for ctx in $(kubectl config get-contexts -o=name --kubeconfig $working_dir/clusters.yaml); do


  # Check which is the current context and choose the appropriate JMX file
  # Region must be a part of the JMX file name
  # You can set multiple checks for every unique region being used
  if echo "$ctx" | grep -q "asia"; then
	  jmx="jmeter-asia.jmx"
  elif echo "$ctx" | grep -q "us"; then
	  jmx="jmeter-us.jmx"
  elif echo "$ctx" | grep -q "europe"; then
	  jmx="jmeter-europe.jmx"
  else
    echo "No JMX file found for this regional cluster. Aborting"
    exit 1
  fi

  master_pod=`kubectl --kubeconfig $working_dir/clusters.yaml --context="${ctx}" get po | grep jmeter-master | awk '{print $1}'`

  kubectl --kubeconfig $working_dir/clusters.yaml --context="${ctx}" cp $jmx $master_pod:/$jmx

  ## Echo Starting Jmeter load test

  echo "Starting Test for $ctx"

  kubectl --kubeconfig $working_dir/clusters.yaml --context="${ctx}" exec -it $master_pod -- /jmeter/load_test $jmx &

done
