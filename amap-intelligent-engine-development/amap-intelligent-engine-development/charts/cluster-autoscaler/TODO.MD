- [ ] Download chart from internet
      helm repo add autoscaler https://kubernetes.github.io/autoscaler
      helm repo update 
      helm pull autoscaler/cluster-autoscaler --version=9.23.0
      
      #helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler --values=values-${ENVIRONMENT}.yaml --version=9.23.0 -n kube-system