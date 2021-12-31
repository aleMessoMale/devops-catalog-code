#Cancellazione cluster

- terraform destroy della folder (simple, simple-versioned)-
- se hai installato Argo, fai l'uninstall del chart - helm uninstall <chart-name> -n argocd (così cancella
  il service load balancer)
- se hai installato l'ingress, vedi MD: helm/Ingress-Destroy.MD
