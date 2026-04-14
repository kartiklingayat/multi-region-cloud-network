import boto3
import argparse
import time
import requests

def stop_asg_instances(region, asg_name):
    """Stop all instances in an Auto Scaling Group (simulate regional failure)."""
    ec2 = boto3.client('ec2', region_name=region)
    autoscaling = boto3.client('autoscaling', region_name=region)
    
    # Get instance IDs from ASG
    response = autoscaling.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_name])
    instances = response['AutoScalingGroups'][0]['Instances']
    instance_ids = [i['InstanceId'] for i in instances]
    
    if not instance_ids:
        print(f"No instances found in ASG {asg_name}")
        return
    
    print(f"Stopping {len(instance_ids)} instances in {region}...")
    ec2.stop_instances(InstanceIds=instance_ids)
    print("Instances stopping. Health checks will fail in ~60s.")

def main():
    parser = argparse.ArgumentParser(description="Failover Simulator")
    parser.add_argument("--region", required=True, choices=['us-east-1', 'us-west-2'])
    parser.add_argument("--action", required=True, choices=['stop-asg', 'start-asg'])
    parser.add_argument("--asg-name", help="Auto Scaling Group name (optional, will auto-detect)")
    parser.add_argument("--failover-url", default="http://failover.yourdomain.com")
    args = parser.parse_args()

    if args.action == 'stop-asg':
        # Auto-detect ASG name based on tags
        autoscaling = boto3.client('autoscaling', region_name=args.region)
        asgs = autoscaling.describe_auto_scaling_groups()['AutoScalingGroups']
        target_asg = None
        for asg in asgs:
            for tag in asg.get('Tags', []):
                if tag['Key'] == 'environment' and tag['Value'] == 'failover-lab':
                    target_asg = asg['AutoScalingGroupName']
                    break
            if target_asg:
                break
        if not target_asg:
            print(f"No ASG found in {args.region} with environment=failover-lab")
            return
        stop_asg_instances(args.region, target_asg)
        
        # Monitor failover URL
        print("Monitoring failover endpoint...")
        for i in range(12):  # 2 minutes
            try:
                resp = requests.get(args.failover_url, timeout=5)
                print(f"  Attempt {i+1}: HTTP {resp.status_code} from {resp.text[:50]}")
            except:
                print(f"  Attempt {i+1}: Timeout / error")
            time.sleep(10)
    elif args.action == 'start-asg':
        # Restart instances (optional)
        print("Restart logic not implemented – use AWS Console to start instances.")
    else:
        print("Unknown action")

if __name__ == "__main__":
    main()
