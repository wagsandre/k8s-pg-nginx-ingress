# **NGINX Ingress Controller training**
---
# Challenge 1 - Configure a simple app on a Kubernetes cluster

In this challenge, you will:

1. Deploy a minikube cluster
2. Install the PodInfo app

## Create a cluster
### Step 1: Create the Cluster
Create your minikube cluster with this command:

`$ minikube start`

## Install the app
### Step 1: Create a Deployment
You'll use a YAML file to create a Deployment with a single replica and a service.
Use the Editor tab or the text editor of your choice.
*Hint:* If you use the Editor tab, be sure to click the save icon next to the file title.

File name: `1-deployment.yaml`

File definition (note that it defines one deployment - `apps/v1` - and one service - `v1`):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: podinfo
spec:
  selector:
    matchLabels:
      app: podinfo
  template:
    metadata:
      labels:
        app: podinfo
    spec:
      containers:
      - name: podinfo
        image: stefanprodan/podinfo
        ports:
        - containerPort: 9898
---
apiVersion: v1
kind: Service
metadata:
  name: podinfo
spec:
  ports:
    - port: 80
      targetPort: 9898
      nodePort: 30001
  selector:
    app: podinfo
  type: LoadBalancer
```
### Step 2: Deploy the Podinfo App
Use this command to deploy your app:

`$ kubectl apply -f 1-deployment.yaml`

### Step 3: Confirm App Deployment
Run this command to confirm that the app is running:

`$ kubectl get pods`

Next, switch to the "Podinfo" tab and click the refresh icon.
You should see something like this: ...

---
# Challenge 2 - Use NGINX Ingress Controller to expose the app
In this challenge, you will:

1. Deploy NGINX Ingress Controller
2. Expose PodInfo to the outside world

## Install NGINX ingress controller
### Step 1: Install NGINX Ingress Controller using Helm
The fastest way to install NGINX Ingress Controller is with Helm, which is already installed on this host.

Begin by adding the NGINX repository to Helm:

`$ helm repo add nginx-stable https://helm.nginx.com/stable`

Next, download and install NGINX Ingress Controller in your cluster. We're using the open source version maintained by F5 NGINX.

```bash
  $ helm install main nginx-stable/nginx-ingress \
  --set controller.watchIngressWithoutClass=true \
  --set controller.service.type=NodePort \
  --set controller.service.httpPort.nodePort=30005
```

### Step 2: Verify NGINX Ingress Controller is Running
Use this command to verify installation:

`$ kubectl get pods`

You're ready to use the Ingress manifest to route traffic to your app.

## Route traffic to your app
### Step 1: Create the Ingress Manifest
You need a YAML file to create an Ingress manifest. You can use the Editor tab or the text editor of your choice.

File name: `2-ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: podinfo
spec:
  ingressClassName: nginx
  rules:
    - host: "example.com"
      http:
        paths:
          - backend:
              service:
                name: podinfo
                port:
                  number: 80
            path: /
            pathType: Prefix
```

### Step 2: Submit the YAML File
Use the following command to submit your Ingress manifest:

`$ kubectl apply -f 2-ingress.yaml`

### Step 3: Confirm Your App is Receiving Traffic
Click the "Podinfo Ingress" tab and then click the refresh icon.
You should see something like this (look familiar?):


---
# Challenge 3: Visualize and Generate Traffic
In this challenge, you will:
1. Use Prometheus to get visibility into NGINX Ingress Controller performance
2. Use Locust to simulate a traffic surge
3. Observe the impact of increased traffic on NGINX Ingress Controller performance

## Explore metrics
As you already discovered, an Ingress controller is a regular pod that bundles a reverse proxy (NGINX) with some code that integrates with Kubernetes. If your app will receive a lot of traffic, you'll want to scale the number of NGINX Ingress Controller pods and increase the replica count. To do this, you need metrics.
### Step 1: Explore Available Metrics
NGINX Ingress Controller exposes [multiple metrics](https://github.com/nginxinc/nginx-prometheus-exporter#exported-metrics). There are eight metrics for the NGINX Ingress Controller you're using in this lab (based on NGINX Open Source) and 80+ metrics for the option based on NGINX Plus.

### Step 2: Create a Temporary Pod
First you need the IP address of the NGINX Ingress Controller pod. Get it using the command:

`$ kubectl get pods -o wide`

You will see the internal IP address of the NGINX Ingress Controller pod in the output (172.17.0.4 in this case)

Now you can create the temporary pod with this command:

`$ kubectl run -ti --rm=true busybox --image=busybox`

You will get a shell on a machine inside the Kubernetes cluster.
```
If you don't see a command prompt, try pressing enter.
/ #
```
### Step 3: View Available Metrics

Use the following command to retrieve a list of the available metrics (note that it includes the IP address you found earlier):

`$ wget -qO- 172.17.0.4:9113/metrics`

You'll get the list of metrics provided by this version of NGINX Ingress Controller - but which one should you use?


For scaling purposes, `nginx_connections_active` is ideal because it keeps track of the number of requests being actively processed, which will help you identify when a pod needs to scale.

Type `exit` at the command prompt of the temporary pod to get back to the Kubernetes server.

## Install Prometheus
To trigger autoscaling based on `nginx_connections_active`, you need two tools:

- A mechanism to scrape the metrics - we'll use Prometheus
- A tool to store and expose the metrics so that Kubernetes can use them - we'll use KEDA.

Prometheus is a popular open source project of the Cloud Native Computing Foundation (CNCF) for monitoring and alerting. NGINX Ingress Controller offers Prometheus metrics that are useful for visualization and troubleshooting.

### Step 1: Install Prometheus
The fastest way to install Prometheus is with Helm, which is already installed on this host.
Add the Prometheus repository to Helm using this command:

`$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`

Next, download and install Prometheus:

```bash 
$ helm install prometheus prometheus-community/prometheus \
  --set server.service.type=NodePort \
  --set server.service.nodePort=30010
```

### Step 2: Verify Prometheus is Installed
Run this command to confirm that Prometheus is installed and running:

`$ kubectl get pods`

Prometheus isn't completely installed yet! All pods must be running before you can start using Prometheus - full installation usually takes 30-60 seconds to complete.
```
NAME                                             READY   STATUS              RESTARTS   AGE
main-nginx-ingress-779b74bb8b-mtdkr              1/1     Running             0          3m23s
podinfo-5d76864686-fjncl                         1/1     Running             0          5m41s
prometheus-alertmanager-d6d94cf4b-85ww5          0/2     ContainerCreating   0          7s
prometheus-kube-state-metrics-7cd8f95c7b-86hhs   0/1     Running             0          7s
prometheus-node-exporter-gqxfz                   1/1     Running             0          7s
prometheus-pushgateway-56745d8d8b-qnwcb          0/1     ContainerCreating   0          7s
prometheus-server-b78c9449f-kwhzp                0/2     ContainerCreating   0          7s
```

### Step 3: Query Prometheus
Switch to the "Prometheus" tab to view the dashboard. As before, you will need to use the refresh icon. If you came straight here after the last step, be prepared to wait up to 30 seconds before the dashboard loads.

Now that Prometheus is available, search for the active connections metric in the search bar: `nginx_ingress_nginx_connections_active`

You will see one active connection, which makes sense because you've deployed one NGINX Ingress Controller pod.

## Install Locust
Next you will use Locust to simulate a traffic surge that you can detect with the Prometheus dashboard.

### Step 1: Create a Locust Pod
You need a YAML file to create a pod for the load generator. You can use the Editor tab or the text editor of your choice.

File name: `3-locust.yaml`

File Definition:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: locust-script
data:
  locustfile.py: |-
    from locust import HttpUser, task, between

    class QuickstartUser(HttpUser):
        wait_time = between(0.7, 1.3)

        @task
        def hello_world(self):
            self.client.get("/", headers={"Host": "example.com"})
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: locust
spec:
  selector:
    matchLabels:
      app: locust
  template:
    metadata:
      labels:
        app: locust
    spec:
      containers:
        - name: locust
          image: locustio/locust
          ports:
            - containerPort: 8089
          volumeMounts:
            - mountPath: /home/locust
              name: locust-script
      volumes:
        - name: locust-script
          configMap:
            name: locust-script
---
apiVersion: v1
kind: Service
metadata:
  name: locust
spec:
  ports:
    - port: 8089
      targetPort: 8089
      nodePort: 30015
  selector:
    app: locust
  type: LoadBalancer
```

Locust reads the following `locustfile.py`, which is stored in a ConfigMap. The script issues a request to the pod with the correct headers.

```python
from locust import HttpUser, task, between

class QuickstartUser(HttpUser):
    wait_time = between(0.7, 1.3)

    @task
    def hello_world(self):
        self.client.get("/", headers={"Host": "example.com"})
```
### Step 2: Submit the YAML File
To submit the YAML file, use the following command:

`$ kubectl apply -f  3-locust.yaml`

### Step 3: Use Locust to Scale Traffic
Go to the "Locust" tab and click refresh. You'll see a welcome page with the option to change number of users, spawn rate, and host.

To simulate a traffic surge, enter the following details into Locust:

- Number of users: 1000
- Spawn rate: 10
- Host: http://main-nginx-ingress

Click "Start swarming" and observe the traffic reaching NGINX Ingress Controller.

### Step 4: Return to Prometheus
Now that you have traffic routing through NGINX Ingress Controller to your Podinfo app, you can return to Prometheus to see how the Ingress controller responds.
- As a vast amount of connections are issued, the single Ingress controller pod struggles to process the increased traffic without latency.
- Through observing where performance degrades, you might notice that 100 active connections is a tipping point for latency issues. This tipping point may be lower depending on your organization's tolerance for latency.
- Once you determine an ideal active threshold for active connections (example: 100), then you can use that information to determine when scale NGINX Ingress Controller.

---
# Challenge 4: Autoscale NGINX Ingress Controller
In this challenge, will:
1. Configure an autoscaling policy using KEDA
2. Generate a traffic surge with Locust
3. Observe how NGINX Ingress Controller autoscales to cope with the traffic surge

## Install KEDA

In the last challenge we gathered NGINX Ingress Controller metrics with Prometheus then simulated a traffic surge with Locust. Now it's time to build a configuration that autoscales resources as the load (traffic) increases.

For this task, you'll use KEDA, a Kubernetes event-driven autoscaler. KEDA integrates a metrics server (the component that stores and transforms metrics for Kubernetes) and it can consume metrics directly from Prometheus (as well as other tools).

### Step 1: Install KEDA
As with the other tools, we'll use Helm since it's quick and effective.

Add "kedacore" to your repositories with:

`$ helm repo add kedacore https://kedacore.github.io/chart`

If successful, you will see:
```
"kedacore" has been added to your repositories
```

Install KEDA with this command:

`$ helm install keda kedacore/keda`

If successful, you will see:
```
NAME: keda
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

### Step 2: Verify KEDA Installation
Verify that KEDA is running with:

`$ kubectl get pods`
