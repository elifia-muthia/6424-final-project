import os
import sqlite3
import subprocess
import requests
from flask import Flask, request, jsonify, abort

# Configuration
DB_PATH       = '/data/fithealth.db'
SECRET_NAME   = os.environ.get('SECRET_NAME')
GOOGLE_CREDENTIALS = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')

app = Flask(__name__)

def get_tdx_quote():
    # Generate TDX quote using Intel TDX CLI
    subprocess.run(['tdx-quote', '--output', 'quote.bin'], check=True)
    with open('quote.bin', 'rb') as f:
        return f.read()

def verify_quote_and_get_key():
    quote = get_tdx_quote()
    # Submit quote to Intel attestation service
    resp = requests.post(
        'https://api.trust-attestation.intel.com/v1/verify',
        files={'quote': quote}
    )
    if resp.status_code != 200 or not resp.json().get('is_trusted'):
        abort(500, 'TDX attestation failed')
    # Fetch SQLCipher key from Secret Manager
    cmd = [
        'gcloud', 'secrets', 'versions', 'access', 'latest',
        f'--secret={SECRET_NAME}',
        '--format=value(payload.data:UNBUFFERED)'
    ]
    result = subprocess.run(cmd, capture_output=True, check=True)
    key_hex = result.stdout.strip().decode('utf-8')
    # Assuming you stored the 32-byte key as hex
    return key_hex

def init_db(conn, key_hex):
    # Use SQLCipher hex key format
    conn.execute(f"PRAGMA key = \"x'{key_hex}'\";")
    conn.execute('''
        CREATE TABLE IF NOT EXISTS records (
            user_id TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            heart_rate INTEGER NOT NULL,
            blood_pressure TEXT NOT NULL,
            notes BLOB,
            PRIMARY KEY(user_id)
        );
    ''')
    conn.commit()

def get_db_connection(key_hex):
    conn = sqlite3.connect(DB_PATH)
    init_db(conn, key_hex)
    return conn

# Perform attestation and open encrypted DB
encryption_key = verify_quote_and_get_key()
db_conn = get_db_connection(encryption_key)

@app.route('/insert', methods=['POST'])
def insert_record():
    data = request.json or {}
    user_id = data.get('user_id')
    timestamp = data.get('timestamp')
    heart_rate = data.get('heart_rate')
    bp = data.get('blood_pressure')
    notes = data.get('notes')
    if not all([user_id, timestamp, heart_rate, bp]):
        abort(400, 'Missing fields')
    cur = db_conn.cursor()
    cur.execute(
        'INSERT OR REPLACE INTO records VALUES (?, ?, ?, ?, ?)',
        (user_id, timestamp, heart_rate, bp, notes)
    )
    db_conn.commit()
    return jsonify({'status': 'ok'}), 201

@app.route('/fetch/<user_id>', methods=['GET'])
def fetch_record(user_id):
    cur = db_conn.cursor()
    cur.execute('SELECT * FROM records WHERE user_id = ?', (user_id,))
    row = cur.fetchone()
    if not row:
        abort(404, 'User not found')
    keys = ['user_id','timestamp','heart_rate','blood_pressure','notes']
    return jsonify(dict(zip(keys, row)))

if __name__ == '__main__':
    # Plain HTTP on port 80
    app.run(host='0.0.0.0', port=80)
