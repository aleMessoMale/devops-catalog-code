# Source: https://gist.github.com/ae00efa6892fcb0b295bbdba73bef3ad

############################################
# Applying GitOps Principles Using Argo CD #
############################################

######################################
# Installing And Configuring Argo CD #
######################################

# Docker Desktop (docker-3gb-2cpu.sh): https://gist.github.com/0fff4fe977b194f4e9208cde54c1aa3c
# Minikube (minikube.sh): https://gist.github.com/2a6e5ad588509f43baa94cbdf40d0d16
# GKE (gke-simple-ingress.sh): https://gist.github.com/925653c9fbf8cce23c35eedcd57de86e
# EKS (eks-simple-ingress.sh): https://gist.github.com/2fc8fa1b7c6ca6b3fefafe78078b6006
# AKS (aks-simple-ingress.sh): https://gist.github.com/e24b00a29c66d5478b4054065d9ea156

IMPORTANTE: Ricordati di aggiornare il file config di k8s tra creazione cluster eks e installazione ingress
controller se segui il link sopra per eks con questo comando:

```
aws eks update-kubeconfig \
--name \
$(terraform output --raw cluster_name) \
--region \
$(terraform output --raw region)
```

Altrimenti ciò che puoi fare per EKS è seguire questi 2 MD: 
- terraform-eks/Create-Cluster.MD 
- helm/Ingress-Installation-Post-EKS-Setup.MD (segui installazione per argo)

Dopo di che puoi partire da qua per Argo

# non necessario se hai già clonato il repo
git clone \
https://github.com/vfarcic/devops-catalog-code.git

cd devops-catalog-code

git pull

# Only if macOS
brew tap argoproj/tap

# Only if macOS
brew install argoproj/tap/argocd

# installazione ArgoCD CLI. Solo se non hai la CLI
# Only if Linux or WSL
VERSION=$(curl --silent \
"https://api.github.com/repos/argoproj/argo-cd/releases/latest" \
| grep '"tag_name"' \
| sed -E 's/.*"([^"]+)".*/\1/')
# Only if Linux or WSL
sudo curl -sSL -o /usr/local/bin/argocd \
https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
# Only if Linux or WSL
sudo chmod +x /usr/local/bin/argocd

# creazione namespace argocd
kubectl create namespace argocd

# aggiunta helm argocd - solo se non lo hai già in locale
helm repo add argo \
https://argoproj.github.io/argo-helm

cat argo/argocd-values.yaml

# installazione helm argocd da root folder
helm upgrade --install \
argocd argo/argo-cd \
--namespace argocd \
--version 2.8.0 \
--set server.ingress.hosts="{argocd.$INGRESS_HOST.nip.io}" \
--values argo/argocd-values.yaml \
--wait

# export della password
export PASS=$(kubectl --namespace argocd \
get pods \
--selector app.kubernetes.io/name=argocd-server \
--output name \
| cut -d'/' -f 2)

# login da cli su argocd
argocd login \
--insecure \
--username admin \
--password $PASS \
--grpc-web \
argocd.$INGRESS_HOST.nip.io

echo $PASS

# modifica password
argocd account update-password

# apertura del link ad argocd (url passato all'installazione del chart)
# ricordati che INGRESS_HOST deve avere valore di un IP (se ne restituisce più di 1)
# vedi installazione ingress o il gist linkato sopra che usa la folder simple
open http://argocd.$INGRESS_HOST.nip.io

kubectl --namespace argocd get pods

cd ../

#########################################
# Deploying An Application With Argo CD #
#########################################


# questo è il repo dove son presenti i descrittori k8s da deployare nel cluster, esattamente nella folder k8s
git clone \
https://github.com/vfarcic/devops-toolkit.git

cd devops-toolkit

ls -1 k8s

# creiamo il namespace nel cluster per ospitare l'app che andremo a deployare
kubectl create namespace devops-toolkit

# eseguiamo il comando di argocd per creare un'app gestita da argocd (chiamata devops-toolkit)
# gli diciamo che repo di codice deve monitorare e che folder, ossia dove trova il desidered state
# gli diciamo anche in che k8s server deve deployare
# il valore https://kubernetes.default.svc significa, deploya nello stesso k8s in cui argocd è installato
# gli forniamo naturalmente anche il namespace nel quale l'app va deployata
argocd app create devops-toolkit \
--repo https://github.com/aleMessoMale/devops-toolkit.git \
--path k8s \
--dest-server https://kubernetes.default.svc \
--dest-namespace devops-toolkit

# in questo momento non avviene nulla, abbiamo solo creato una relazione fra l'app argocd e il repo del codice
# non avendogli detto di fare il synch, in questo momento è "out of synch" entrondo nella web ui
# clicchiamo su synch e vediamo come lo stato passi da progressing fino a healthy
# quanto fatto lo possiamo naturalmente fare anche dalla CLI di ArgoCD
open http://argocd.$INGRESS_HOST.nip.io

# a questo punto abbiamo deployato nel namespace indicato i descrittori presenti nella folder k8s
kubectl --namespace devops-toolkit \
get all

# cancelliamo l'app e verifichiamo che non sia presente più nulla nel namespace destinazione
argocd app delete devops-toolkit
open http://argocd.$INGRESS_HOST.nip.io
kubectl --namespace devops-toolkit \
get all
# cancelliamo quindi a questo punto anche il relativo namespace
kubectl delete namespace devops-toolkit

# come vedremo, ArgoCD è in grado di integrarsi anche con Helm e di deployare anche descrittori helm, non solo pure k8s
ls -1 helm

cd ..

###############################
# Defining Whole Environments #
###############################

open https://github.com/vfarcic/argocd-production

# Replace `[...]` with the GitHub organization
export GH_ORG=[...]

# crea un repo per ogni environment, non necessariamente il modo migliore di fare le cose
git clone \
https://github.com/$GH_ORG/argocd-production.git

cd argocd-production

# questo è il file descrittore dell'ambiente. I commenti li ho aggiunti nel file
# cosa è un progetto? E' un raggruppamento logico delle applicazioni gestite da ArgoCD
cat project.yaml

# applichiamo quindi il descrittore del progetto argocd, essendo un CRD possiamo farlo
kubectl apply \
--filename project.yaml

# recuperiamo gli oggetti CRD di tipologia appproject (ArgoCD)
kubectl --namespace argocd \
get appprojects

#NAME         AGE
#default      8h
#production   48s

# possiamo vedere i progetti anche dalla webui 
open http://argocd.$INGRESS_HOST.nip.io/settings/projects

# creaiamo il ns per deployare l'app in produzione
kubectl create namespace production

# vediamo il contenuto della folder helm e della folder templates (dove son presenti i descrittori)
ls -1 helm
ls -1 helm/templates

# questi due descrittori presenti, son 2 applicazioni
cat helm/templates/devops-toolkit.yaml

cat helm/templates/devops-paradox.yaml

# questa è l'app di app, ossia è l'app che controlla per le modifiche sul repo argocd-production
# e che quando facciamo una modifica al repo si occupa di applicare l'helm chart presente nei due repo delle due 
# app referenziate (paradox e toolkit) presenti nel repo e nella folder specificate nel descrittore dell'app di app
cat apps.yaml

cat apps.yaml \
| sed -e "s@vfarcic@$GH_ORG@g" \
| tee apps.yaml

git add .

git commit -m "Changed the org"

git push

# applichiamo anche l'apps di app e entriamo su argocd per vedere le 3 app (l'app di apps e le altre due referenziate)
# l'app di apps anche visivamente referenzia le altre 2, vedi appunti su google docs
kubectl --namespace argocd apply \
--filename apps.yaml

open http://argocd.$INGRESS_HOST.nip.io

# qua vediamo fondamentalmente che tutti i descrittori presenti nei due repo (devops-paradox e devops-toolkit) son stati
# applicati al namespace production. Questo perché al push dell'app di apps, grazie al synch, lui aggiorna tutte le apps
# che referenzia, apps che sono packettizzate grazie ad helm e son presenti nei vari repo (path helm, ndr)

# quindi quello che facciamo è creare un'app di apps, aggiungere le app di argocd con i vari descrittori come in questo caso
# (devops-paradox.yaml su helm folder di argocd-production) e a quel punto, pushare i descrittori k8s nei vari repo
# devops-paradox.git ecc ecc e lasciar fare tutto ad ArgoCD
kubectl --namespace production get all

# approfittiamo per fare un deploy e lo facciamo modificando gli ingresses
kubectl --namespace production get ingresses

###################################################
# Updating Applications Through GitOps Principles #
###################################################

# vogliamo far si che il tag dell'immagine a cui punta devops-toolkit app sia non latest ma una specifica
# e vogliamo che punti anche ad un altro ingress, ossia quello presente nel nostro cluster e non quello nel repo di Viktor
# per farlo modifichiamo logicamente il descrittore dell'app devops-toolkit.yaml dell'ambiente di production
# ossia il file helm/templates/devops-toolkit.yaml nel repo argocd-production.git
# non abbiamo modificato il descrittore dell'app nel repo specifico (devops-toolkit.git)
# ci basta pushare questa modifica perché ArgoCD faccia il resto, vedendo la modifica in una delle argocd app
# puntate dall'app di apps
cat helm/templates/devops-toolkit.yaml \
| sed -e "s@latest@2.9.17@g" \
| sed -e "s@devopstoolkitseries.com@devops-toolkit.$INGRESS_HOST.nip.io@g" \
| tee helm/templates/devops-toolkit.yaml

git add .

git commit -m "New release"

git push

# verificato quindi che il tag dell'immagine è cambiato dopo qualche minuto idem per l'ingress 
kubectl --namespace production get \
deployment devops-toolkit-devops-toolkit \
--output jsonpath="{.spec.template.spec.containers[0].image}"

kubectl --namespace production get ingresses

open http://devops-toolkit.$INGRESS_HOST.nip.io

# rimuoviamo inoltre devops-paradox app per verificare che non sia piu presente
rm helm/templates/devops-paradox.yaml

git add .

git commit -m "Removed DOP"

git push

open http://argocd.$INGRESS_HOST.nip.io

kubectl --namespace production get pods

############################
# Destroying The Resources #
############################

kubectl delete namespace argocd

kubectl delete namespace production

cd ..