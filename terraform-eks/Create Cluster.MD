# Action to create cluster

- Be sure to have a aws credentials file or have the relative variables set as env variables
- Have installed aws cli
- Go to simple-versioned folder
- Perform the following command ```terraform apply```
- Perform the following command to update the k8s config (.kube/config) adding the new context:

```
aws eks update-kubeconfig \
--name \
$(terraform output --raw cluster_name) \
--region \
$(terraform output --raw region)
```
- (Optional) If you need to make assume a particular role to the authenticated user into EKS, change 
  the config file accordingly adding the ```--role-arn <value>``` to the k8s config file:
```
users:
- name: arn:aws:eks:eu-west-1:391721830672:cluster/casula-cluster
  user:
  exec:
  apiVersion: client.authentication.k8s.io/v1alpha1
  args:
  - --region
  - eu-west-1
  - eks
  - get-token
  - --cluster-name
  - casula-cluster
  command: aws
```
the command used is (for eks>1.16) the ``` awk eks get-token --cluster-name <cluster-name> [--role-arn <value>]```
