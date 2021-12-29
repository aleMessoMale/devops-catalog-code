#############################
# Deploy Ingress Controller #
#############################

# ho anche copiato il file su ingress-installation.yaml per vedere cosa stava applicando
kubectl apply \
--filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.35.0/deploy/static/provider/aws/deploy.yaml

export INGRESS_HOST=$(kubectl \
--namespace ingress-nginx \
get svc ingress-nginx-controller \
--output jsonpath="{.status.loadBalancer.ingress[0].hostname}")

echo $INGRESS_HOST

# Repeat the `export` command if the output is empty