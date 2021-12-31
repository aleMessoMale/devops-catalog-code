#############################
# Deploy Ingress Controller #
#############################

# ho anche copiato il file su ingress-descriptors.yaml per vedere cosa stava applicando
# qua crea il load balancer
kubectl apply \
--filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.35.0/deploy/static/provider/aws/deploy.yaml

# questo per lavorare con HELM - da l'hostname ma lo mette nella variabile HOST
# se devi usarlo per ARGO - SKIPPA STA PARTE
export INGRESS_HOST=$(kubectl \
--namespace ingress-nginx \
get svc ingress-nginx-controller \
--output jsonpath="{.status.loadBalancer.ingress[0].hostname}")

# questo per lavorare con argocd
export INGRESS_HOSTNAME=$(kubectl \
--namespace ingress-nginx \
get svc ingress-nginx-controller \
--output jsonpath="{.status.loadBalancer.ingress[0].hostname}")
# se ti da più di un indirizzo IP, prendine uno e fai l'export di INGRESS_HOST al valore dell'ip scelto
export INGRESS_HOST=$(\
dig +short $INGRESS_HOSTNAME)

echo $INGRESS_HOST

# Repeat the `export` command if the output is empty