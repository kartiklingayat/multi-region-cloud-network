#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
yum update -y
yum install -y python3 python3-pip
pip3 install flask
cat <<EOF > /home/ec2-user/app.py
from flask import Flask
import socket
app = Flask(__name__)
@app.route('/')
def index():
    return f"Region: ${region}\\nInstance: {socket.gethostname()}"
@app.route('/health')
def health():
    return "OK", 200
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
EOF
python3 /home/ec2-user/app.py &
