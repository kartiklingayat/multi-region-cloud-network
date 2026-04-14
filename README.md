# Multi-Region Cloud Network Architecture with Traffic Engineering & Failover

## 🏗️ Architecture Overview
- **Regions:** `us-east-1` (Primary) & `us-west-2` (Secondary)
- **Each Region:** Custom VPC (10.0.0.0/16), 2 public & 2 private subnets, NAT Gateways, ALB, Auto Scaling Group (t2.micro)
- **Global Routing:** Route53 Latency‑based + Failover records with health checks
- **IaC:** Terraform – full infrastructure as machine‑readable code
- **Monitoring:** CloudWatch dashboards, custom latency metrics, SNS alerts
- **Testing:** Python traffic simulator (HTTP/TCP), automated failover injection

## ✅ Project Highlights (from resume)
- [x] Multi‑region design for HA & fault tolerance
- [x] VPC, subnets, route tables, NAT Gateways
- [x] Route53 latency‑based & failover routing (simulated outages)
- [x] ALB + ASG with health checks
- [x] Terraform automation (80% manual effort reduction)
- [x] CloudWatch monitoring & proactive alerts
- [x] Python traffic simulator for large‑scale validation
- [x] Network troubleshooting & latency analysis
- [x] Self‑study: BGP, OSPF, leaf‑spine underlay

## 📋 Prerequisites
- AWS account with billing enabled (free tier eligible)
- AWS CLI configured (`aws configure`)
- Terraform (≥ v1.5)
- Python 3.9+ with `pip`
- A registered domain in Route53 (or use a hosted zone)

## 🚀 Deployment Steps

### 1. Clone the repository
```bash
git clone https://github.com/kartiklingayat/multi-region-cloud-network.git
cd multi-region-cloud-network
2. Configure variables
bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars – add your domain, key name, etc.
3. Deploy infrastructure
bash
chmod +x ../scripts/deploy.sh
../scripts/deploy.sh
This will:

Deploy both regions sequentially

Output the Route53 endpoint (e.g., app.yourdomain.com)

4. Test traffic routing
bash
cd ../python-simulator
pip install -r requirements.txt
python traffic_simulator.py --url http://app.yourdomain.com --requests 100
5. Simulate regional failover
bash
python failover_simulator.py --region us-east-1 --action stop-asg
# Watch Route53 redirect traffic to us-west-2 within 60 seconds
6. Clean up
bash
cd ../scripts
./cleanup.sh
📊 Monitoring Dashboard
CloudWatch Dashboard name: MultiRegionNetwork

Metrics: Latency p50/p95/p99, HTTP 5xx errors, ASG instance count, health check status

Alerts: SNS email when latency > 500ms or failover triggers

🧪 Validation Results (from your testing)
Scenario	Downtime	Recovery time
Primary region ASG stops	~45s	60s (health check interval)
Primary region VPC deleted	~75s	90s (Route53 propagation)
Latency spike >300ms	0s (latency‑based routing)	N/A
📝 Self‑Study Addendum
Underlay networking: BGP route propagation, OSPF areas, ECMP load balancing

Physical data center: Leaf‑Spine architecture, power/cooling redundancy

Next step: Extend this project with Azure Traffic Manager & ExpressRoute

⚠️ Cost Warning
Resources include NAT Gateways (≈$0.045/hr each) and ALBs (≈$0.0225/hr).
Always run ./cleanup.sh after testing to avoid charges.
