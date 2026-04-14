#!/bin/bash
set -e
echo "⚠️  Destroying all resources..."
cd terraform
terraform destroy -auto-approve
echo "✅ Cleanup complete."
