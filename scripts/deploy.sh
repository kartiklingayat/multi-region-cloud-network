#!/bin/bash
set -e
echo "🚀 Deploying multi-region network infrastructure..."
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply -auto-approve tfplan
echo "✅ Deployment complete!"
echo "🌐 Application URL: $(terraform output -raw app_latency_url)"
echo "🔁 Failover URL: $(terraform output -raw failover_url)"
