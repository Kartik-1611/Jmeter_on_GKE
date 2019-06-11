# Distributed Load Testing using JMeter on Google Kubernetes Engine (GKE)

This implementation is for running distributed Load Tests using Jmeter deployed on Kubernetes Pods. The cluster used for this is deployed on Google Kubernetes Engine (GKE).

> You can use any K8s cluster on any Cloud Platform or On-Premises. You just need to populate the Kubeconfig file accordingly.

We will provision the below resources for this implementation :  
1) Multiple (Multi-Regional) Kubernetes clusters on GKE.  
2) Jmeter, InfluxDB and Grafana pods in the deployed clusters.


## Deploying GKE clusters

First we need to setup our K8s clusters. In this guide, we will be provisioning 3 clusters in 3 regions (US, Europe and Asia).  
(You can use a single cluster as well if you wish)

You can refer this [guide](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-cluster#regional) on how to provision clusters in GKE.  
Create 3 clusters with 1 node per zone in each cluster.

## Getting credentials for the deployed clusters.

Once you successfully deploy the K8s clusters, next step is to get the access credentials for those clusters. We will do this using the below gcloud command.

> Clone this repo first if you haven't done it yet and go the root folder.

Execute the below command in the Cloud Shell for each of the clusters.
```
KUBECONFIG=clusters.yaml gcloud beta container clusters get-credentials <cluster-name> --region <region-name> --project <project-name>
```

The above command will create a Kubeconfig file in the current folder and will have the credentials for all 3 clusters. Next we will deploy InfluxDB and Grafana in a VM.


## Deploying resources in K8s clusters

Jmeter and InfluxDB resources required for this implementation are located in ***manifests*** folder.  
Executing the ***deploy_manifests.sh*** script from the ***scripts*** folder will deploy these manifests in all the K8s clusters.

> Make sure to run all the commands from the root of Github Repo.

A quick explanation of the K8s manifests :  
1) ***jmeter_master_configmap.yaml*** - The command to execute to start the Load test from the pod is mounted as a configmap in the Master pod.  
2) ***jmeter_master_deploy.yaml*** - The Deployment spec for the Jmeter master pod.  
3) ***jmeter_slaves_svc.yaml*** - The Service used to expose Jmeter slave pods so that masster can communicate with them.  
4) ***jmeter_slaves_deploy.yaml*** - The Deployment spec for the Jmeter slave pods.  
5) ***jmeter_influxdb_stateful.yaml*** - The Statefulset spec for the InfluxDB pods. We are using Statefulset instead of deployment because we don't want to lose our data if the pods are restarted.

After deploying the manifests, you need to execute the ***setup.sh*** script in ***scripts*** folder. This script grants execute permission to the Jmeter start command mounted as a configmap.

One last resource that needs to be deployed is the Grafana pod.
We will only require one Grafana pod as we will be visualizing the data for all the clusters in a single dashboard.

To deploy the grafana pod use the file ***jmeter_grafana_deploy.yaml*** in the root folder.
(If you have multiple clusters then you can choose any one of them to deploy this)

```
kubectl --kubeconfig $working_dir/clusters.yaml create -f $working_dir/jmeter_grafana_deploy.yaml
```


## JMeter test plans

While creating your test plan in Jmeter, you need to specify a Backend Listener if you are storing the test results in a external storage.  
In our case, this is InfluxDB.
> You can refer this [link](https://www.blazemeter.com/blog/how-to-use-grafana-to-monitor-jmeter-non-gui-results-part-2) to setup InfluxDB as the backend for Jmeter.  

> While specifying *influxDBHost* field in the backend Listener config, you need to put in the name of the InfluxDB service name that was created along with InfluxDB Statefulset.


## How to start/stop JMeter tests

The *scipts* folder has 2 scripts ***start_test_single*** and ***start_test_multi***.

The single script executes the same provided JMX on all deployed K8s clusters, whereas, the multi script executes different JMX scripts for different K8s cluster.
> While creating different JMX scripts make sure they contain the name of the region of the cluster it is meant to execute on. See the script for more info.

> The single script requires the location of the JMX script to be executed.  
The multi script automatically discovers JMX scripts in the current directory.

Both the scripts run in foreground. If you need to stop the tests in between, open a new terminal session and execute the ***jmeter_stop*** script.  
This script will send a KILL command to the JMeter test running in all clusters.


## Configuring Grafana dashboards

You can configure the Grafana dashboards according to your needs.  
[This](https://grafana.com/dashboards/5496) is a sample dashboard to get started.

You will also need to configure the data sources for your grafana dashboard. While creating a new data source in Grafana, you can select the Influx option.

> The IP for the InfluxDB data source is the one which is allocated to the InfluxDB service that is created for the Statefulset.
  
> By default the database name in influxdb is 'jmeter', you can change this by editing the value of the environment variable defined in the InfluxDB Statefulset YAML file.
