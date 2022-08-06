# EKS Cluster on EC2
This terraform for the setup `EKS Cluster` with `AWS CodePipeline`. Once Developer push the code into the `CodeCommit`' the pipelive will trigger based on poll. The cahnge trigger the pipeline and create a new image with the tag `Commit Id` and push to the ECR.

```
IMAGE_TAG=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-8)      
```
Used above mentioned command to set the images tag.

## buildspec
```
- aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
- curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.6/2022-03-09/bin/linux/amd64/kubectl
- chmod +x ./kubectl
- aws eks update-kubeconfig --name eksec2-cluster
```
ECR authentication and cluster access part handle by `pre_build` block.

# Setup ENvironment Process

+ Environment Setup
```
terraform init
terraform validate
terraform apply
```

+ Access EKS Cluster
```
aws eks update-kubeconfig --name eksec2-cluster
```
+ Deploy Loadbalancer
```
eksctl create iamserviceaccount --cluster=eksec2-cluster --namespace=kube-system --name=aws-load-balancer-controller --role-name "AmazonEKSLoadBalancerControllerRole" --attach-policy-arn=arn:aws:iam::103750175519:policy/AWSLoadBalancerControllerIAMPolicy --approve

helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller  -n kube-system   --set clusterName=eksec2-cluster   --set serviceAccount.create=false   --set serviceAccount.name=aws-load-balancer-controller 
```

+ Deploy ALB Ingress
```
kubectl apply -f alb.yaml
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-svc.yaml
```

+ Validate the deployment
```
kubectl  get ingress -A
```
Load the ingress on browser. You can viwe the web page.
![text](/alb-config/web-page.PNG)

+ Check Pipeline work
```
kubectl edit cm aws-auth  -n kube-system
```
Need to grant access to work CodeBuild. So run edit command and add below recode to provide the access.
```
    - groups:
      - system:masters
      rolearn: arn:aws:iam::<account_id>:role/ecs-code-build-role
      username: CodeBuild-user
```
Finaly Uplode the code change into the `CodeCommit.
![text](/alb-config/pipeline-webapp.PNG)
