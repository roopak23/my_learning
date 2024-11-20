# Internal ALB for Segtool and Tableau

This Terraform folder is for creating an application load balancer that points to Segtool, Tableau, Jenkins EC2 instances. Currently the internal network load balancer is controlled by ingress-nginx and we cannot add a rule-based path to the ec2 instances for an NLB, also Segtool and Tableau are outside the Kubernetes cluster, so ingress-nginx won't be able to point the paths directly to the instances. So we need to create a new Application Load Balancer with TLS termination and host-based paths pointing to the EC2 instances. 

## Requirements
1. Tableau private ip address
2. Segtool private ip address
3. Jenkins private ip address
4. Certificate (from AWS Certificate Manager to be applied to the ALB listener)

## Output
1. Application Load Balancer with https listeners
2. Target groups for Tableau, Segtool, Jenkins

After applying and creating the ALB, Route53 needs to be updated. If there is a domain for tableau already create a CNAME record pointing to the ALB. If not, create a new subdomain and point that new subdomain for tableau to the ALB. 

## Tableau requirements
Once the ALB is set up, tableau will not immediately work, as it needs to be configured to use with a load balancer. 

*https://help.tableau.com/current/server/en-us/distrib_lb.htm*