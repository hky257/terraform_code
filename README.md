# terraform_code

Exercise:
Terraform Code to create the below Infrastructure: 
1 VPC in us-east-1 region. This should be flexible based on region. If no region is provided, this should be built in us-east-1. 
2 Subnets with high availability supported in 2 zones
1 Route table not including the default one. Routes should not be routed using the local route. 
Autoscaling group with a flexible cool down, deregistration delay, instance warm up.
2 EC2 instances created from the autoscaling group
ALB to load-balance the app servers. Ensure the port is flexible based on the application. 
IAM roles should only be used by the account owner.
