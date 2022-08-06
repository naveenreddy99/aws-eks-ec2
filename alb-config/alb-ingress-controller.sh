eksctl create iamserviceaccount --cluster=eksec2-cluster --namespace=kube-system --name=aws-load-balancer-controller --role-name "AmazonEKSLoadBalancerControllerRole" --attach-policy-arn=arn:aws:iam::103750175519:policy/AWSLoadBalancerControllerIAMPolicy --approve

helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller  -n kube-system   --set clusterName=eksec2-cluster   --set serviceAccount.create=false   --set serviceAccount.name=aws-load-balancer-controller 