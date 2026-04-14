import requests
import time
import statistics
import argparse
import json
from concurrent.futures import ThreadPoolExecutor, as_completed
import numpy as np

def send_request(url, timeout=5):
    """Send HTTP GET and return latency in ms or None on error."""
    try:
        start = time.time()
        resp = requests.get(url, timeout=timeout)
        latency = (time.time() - start) * 1000
        return latency, resp.status_code, resp.text[:100]
    except Exception as e:
        return None, None, str(e)

def simulate_traffic(url, num_requests, concurrency, timeout):
    latencies = []
    errors = 0
    status_codes = {}
    with ThreadPoolExecutor(max_workers=concurrency) as executor:
        futures = [executor.submit(send_request, url, timeout) for _ in range(num_requests)]
        for future in as_completed(futures):
            lat, code, _ = future.result()
            if lat is None:
                errors += 1
            else:
                latencies.append(lat)
                status_codes[code] = status_codes.get(code, 0) + 1
    return latencies, errors, status_codes

def main():
    parser = argparse.ArgumentParser(description="Multi-Region Traffic Simulator")
    parser.add_argument("--url", default="http://app.yourdomain.com", help="Target URL")
    parser.add_argument("--requests", type=int, default=100, help="Number of requests")
    parser.add_argument("--concurrency", type=int, default=10, help="Concurrent workers")
    parser.add_argument("--timeout", type=int, default=5, help="Request timeout (s)")
    args = parser.parse_args()

    print(f"🚦 Simulating {args.requests} requests to {args.url}...")
    latencies, errors, codes = simulate_traffic(args.url, args.requests, args.concurrency, args.timeout)

    if latencies:
        print(f"\n✅ Successful requests: {len(latencies)}")
        print(f"❌ Errors: {errors}")
        print(f"📊 Latency (ms):")
        print(f"   Min: {min(latencies):.2f}")
        print(f"   Mean: {statistics.mean(latencies):.2f}")
        print(f"   Median: {statistics.median(latencies):.2f}")
        print(f"   p95: {np.percentile(latencies, 95):.2f}")
        print(f"   p99: {np.percentile(latencies, 99):.2f}")
        print(f"   Max: {max(latencies):.2f}")
        print(f"\n📡 HTTP Status Codes: {codes}")
    else:
        print("❌ No successful requests.")

if __name__ == "__main__":
    main()
