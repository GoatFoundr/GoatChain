#!/bin/bash
set -e

echo "🏢 GoatChain Enterprise Deployment Script"
echo "Cost: ~$103/month for enterprise-grade infrastructure"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI first."
    echo "   curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'"
    echo "   unzip awscliv2.zip && sudo ./aws/install"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Run: aws configure"
    exit 1
fi

echo "✅ AWS CLI configured"

# Get parameters
read -p "Enter your EC2 Key Pair name: " KEY_PAIR
read -p "Enter your domain name (e.g., blockchain.goatfundr.com): " DOMAIN
read -p "Enter AWS region [us-west-2]: " AWS_REGION
AWS_REGION=${AWS_REGION:-us-west-2}

echo ""
echo "📋 Deployment Summary:"
echo "   Key Pair: $KEY_PAIR"
echo "   Domain: $DOMAIN"  
echo "   Region: $AWS_REGION"
echo "   Cost: ~$103/month"
echo ""

read -p "Continue with deployment? (y/N): " CONFIRM
if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

echo ""
echo "🚀 Deploying GoatChain Enterprise Infrastructure..."

# Deploy CloudFormation stack
STACK_NAME="goatchain-enterprise"
aws cloudformation deploy \
    --template-file aws-enterprise-infrastructure.yaml \
    --stack-name $STACK_NAME \
    --parameter-overrides KeyPairName=$KEY_PAIR DomainName=$DOMAIN \
    --capabilities CAPABILITY_IAM \
    --region $AWS_REGION

if [ $? -eq 0 ]; then
    echo "✅ Infrastructure deployed successfully!"
    
    # Get outputs
    echo ""
    echo "📊 Getting deployment information..."
    
    ALB_DNS=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $AWS_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
        --output text)
    
    NODE1_IP=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $AWS_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`Node1PublicIP`].OutputValue' \
        --output text)
    
    NODE2_IP=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $AWS_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`Node2PublicIP`].OutputValue' \
        --output text)
    
    echo ""
    echo "🎉 DEPLOYMENT COMPLETE!"
    echo ""
    echo "📋 Infrastructure Details:"
    echo "   Load Balancer: $ALB_DNS"
    echo "   Node 1 IP: $NODE1_IP"
    echo "   Node 2 IP: $NODE2_IP"
    echo ""
    echo "📝 Next Steps:"
    echo "   1. Point your domain '$DOMAIN' to: $ALB_DNS"
    echo "   2. SSH to each node and start the blockchain:"
    echo "      ssh -i $KEY_PAIR.pem ubuntu@$NODE1_IP"
    echo "      ssh -i $KEY_PAIR.pem ubuntu@$NODE2_IP"
    echo "   3. On each node, run: ./start-enterprise-node.sh node1 (or node2)"
    echo "   4. Set up SSL certificate with certbot"
    echo ""
    echo "💰 Monthly Cost: ~$103"
    echo "   - 2x t3.small EC2: $50"
    echo "   - Application Load Balancer: $18" 
    echo "   - CloudWatch: $10"
    echo "   - Data Transfer: ~$25"
    
else
    echo "❌ Deployment failed!"
    exit 1
fi 