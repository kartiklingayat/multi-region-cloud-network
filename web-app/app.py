from flask import Flask
import socket
import requests

app = Flask(__name__)

@app.route('/')
def index():
    region = requests.get('http://169.254.169.254/latest/meta-data/placement/region').text
    return f"Region: {region}\nInstance: {socket.gethostname()}\n"

@app.route('/health')
def health():
    return "OK", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
