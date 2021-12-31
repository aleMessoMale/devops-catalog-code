#######################
# Destroy The Cluster #
#######################

# This will delete the NBL. Otherwise, it would prevent deletion of some of the resources controlled by Terraform
kubectl delete \
--filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.35.0/deploy/static/provider/aws/deploy.yaml

# qua minimal o comunque quello che hai utilizzato per creare il cluster eks
cd terraform-eks/minimal

# i -var puoi pure non passarli se valori messi in tfvars come hai fatto
terraform destroy \
--var k8s_version=$K8S_VERSION \
--var release_version=$RELEASE_VERSION

cd ../..