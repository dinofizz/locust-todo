# locust-todo
Simple Locust load test for my ToDo API.

This repo forms part of the work I am doing to learn Kubernetes by building applications on my Raspberry Pi Cluster.

See my blog post here: https://www.dinofizzotti.com/blog/2020-07-04-raspberry-pi-cluster-part-3-running-load-tests-with-kubernetes-and-locust/

*Note: This repo is primarily for my own interests and learning. Feel free to read/copy the code, but I won't be supporting or maintaining anything here other than for my own benefit.*

## Locust
[Locust](https://locust.io) is an open source load testing tool which allows you to write your performance tests in Python code. Test runs can be headless, or controlled via a simple web UI and it has the ability to run in a distributed mode, with multiple worker nodes controlled by a coordinator node. The core Python classes are extensible, allowing one to provide custom implementations for specific web protocols and traffic patterns.

## locustfile.py
This file describes a very simple load test targetting my [ToDo API](https://github.com/dinofizz/todo-api-go), with the following steps:

1) Create a ToDo item with a random description and a completion status set to “false”.
2) Retrieve the ToDo item that was created in the first step.
3) Update the ToDo item with a completion status set to “true.
4) Delete the ToDo item.

Is this a great performance test? Not really, I don’t think this sequence of events represents meaningful user behaviour. But it should do OK for my purposes of demonstrating Locust running in my cluster - and maybe even gain some insight into the ToDo API performance.

## Helm chart
To facilitate the installation of the Locust coordinator and worker nodes into my cluster I am using a [Helm](https://helm.sh/) chart.

There does exist an [existing Locust Helm chart within the official Helm repository](https://github.com/helm/charts/tree/master/stable/locust), but it is currently referencing an older version of Locust which uses different configuration environment variables than the latest (v1.0.1) that I wish to use.  

So I created my own Helm chart with the following features:

* Locust runtime parameters are specified via environment variables, configurable from the values.yml.
* Locust workers can be deployed as either a DaemonSet or as a Deployment with a configurable number of replicas.
  * The former guarantees each node will run a single worker pod.
  * The latter allows for the scheduler to run multiple replica worker pods per node.
  * The reason for providing for both configurations is solely for my own interest in learning to work with different deployment models.
* ARM-compatible Locust image (see below).

## Locust Docker build for ARM
Kubernetes sources the container images from the repository specified in the `values.yaml` file. Ideally I should be able to just point to the official Locust repository "[locustio/locust"](https://hub.docker.com/r/locustio/locust), install my Helm chart and run my load tests. Unfortunately the Locust Docker Hub repository does not provide images built to run on the ARM architecture, and thus they will not run on my Raspberry Pi cluster. If you attempt to run an image built for x86 on an ARM device this you will most likely see an error message displaying something like `exec user process caused "exec format error"`.

To solve this problem I cloned the [Locust GitHub repository](https://github.com/locustio/locust) and used Docker's [buildx](https://docs.docker.com/buildx/working-with-buildx/) tool to [create a multi-architecture image](https://community.arm.com/developer/tools-software/tools/b/tools-software-ides-blog/posts/getting-started-with-docker-for-arm-on-linux) which I then pushed to my [own Docker Hub repository](https://hub.docker.com/r/dinofizz/locust). No changes to the Locust code or the existing Dockerfile were required.

## Running Locust in the Cluster as a DaemonSet

### Node labels and nodeSelector

You will need to label your nodes accordingly. There should be at least 1x Locust coordinating node and 1x Locust worker node.

```bash
kubectl label nodes <YOUR_COORDINATING_NODE> locustRole=coordinator
```

This is specified in the `coordinator-deployment.yaml` template:

```yaml
...
nodeSelector:
  locustRole: coordinator 
...
```

Likewise the remaining nodes are labelled as worker nodes:

```bash
kubectl label nodes <WORKER_NODE_1> locustRole=worker
kubectl label nodes <WORKER_NODE_2> locustRole=worker
...
```

And the `worker.yaml` file specifies the following nodeSelector:

```yaml
...
nodeSelector:
  locustRole: worker
...
```

### Helm Chart Install

*Note: I am running my applications in Kubernetes with a LoadBalancer available - you may need to make changes to the chart if you wish to use a different Service type.*

To run Locust in with the DaemonSet configuration the `workers.kind` property in the chart `values.yaml` should be set to `DaemonSet`:

```yaml
...
workers:
  kind: Daemonset 
...
```

The chart can then be installed with the following command:

```bash
$ helm install --namespace locust locustchart --generate-name
NAME: locustchart-1590923674                                          
LAST DEPLOYED: Sun May 31 12:14:34 2020
NAMESPACE: locust                                                     
STATUS: deployed                                                      
REVISION: 1                                                           
NOTES:                                                                
1. Get the application URL by running these commands:
     NOTE: It may take a few minutes for the LoadBalancer IP to be available.
           You can watch the status of by running 'kubectl get --namespace locust svc -w locustchart-1590923674-locust'
  export SERVICE_IP=$(kubectl get svc --namespace locust locustchart-1590923674-coordinator-service-web --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
  echo http://$SERVICE_IP:80                                          

```

## Running Locust with worker replicas

Alternatively you may run the Locust workers in a Deployment with a number of replicas:

```bash
$ helm --namespace locust install --set workers.kind=Deployment --set workers.replicas=6 locust ./locustchart
NAME: locust
LAST DEPLOYED: Sun Jun 28 11:16:23 2020
NAMESPACE: locust
STATUS: deployed
REVISION: 1
NOTES:
1. Get the application URL by running these commands:
     NOTE: It may take a few minutes for the LoadBalancer IP to be available.
           You can watch the status of by running 'kubectl get --namespace locust svc -w locust-locust'
  export SERVICE_IP=$(kubectl get svc --namespace locust locust-coordinator-service-web --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
  echo http://$SERVICE_IP:80
```
