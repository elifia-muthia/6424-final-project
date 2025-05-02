import os
import sqlite3
import subprocess
import requests
import base64, logging
import secrets
from flask import Flask, request, jsonify, abort

# Configuration
DB_PATH       = '/data/fithealth.db'
SECRET_NAME   = os.environ.get('SECRET_NAME')
GOOGLE_CREDENTIALS = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')

app = Flask(__name__)

TSM_PATH = '/sys/kernel/config/tsm/report/report0'
QUOTE_FILE = '/data/quote.bin'
NONCE_SIZE = 64

def get_tdx_quote():
    # 1. Prepare the report directory
    os.makedirs(TSM_PATH, exist_ok=True)

    # 2. Generate a random nonce
    nonce = secrets.token_bytes(NONCE_SIZE)
    with open(f'{TSM_PATH}/inblob', 'wb') as f:
        f.write(nonce)

    # 3. Read the raw quote
    quote = open(f'{TSM_PATH}/outblob', 'rb').read()

    # (Optionally) persist it for debugging
    with open(QUOTE_FILE, 'wb') as f:
        f.write(quote)

    return quote, nonce

def verify_with_go_tdx_guest():
    # run 'check' on the dumped quote
    proc = subprocess.run(
        ['check', '-in', QUOTE_FILE],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    if proc.returncode != 0:
        raise RuntimeError(
            f"TDX quote verification failed:\n{proc.stderr.strip()}"
        )
    # else it's a zero-exit "Success"

def verify_quote_and_get_key():
    # collect the local quote
    quote, nonce = get_tdx_quote()

    verify_with_go_tdx_guest()

    encryption_key = subprocess.run(
        ['gcloud','secrets','versions','access','latest','--secret=fithealth-db-key'],
        stdout=subprocess.PIPE, check=True
    ).stdout.strip().decode('utf-8')

    return encryption_key

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
    data = request.get_json(silent=True) or {}
    required = ('user_id', 'timestamp', 'heart_rate', 'blood_pressure')
    if not all(k in data for k in required):
        abort(400, 'Missing required fields')

    vals = (
        data['user_id'],
        data['timestamp'],
        data['heart_rate'],
        data['blood_pressure'],
        data.get('notes')
    )

    cur = db_conn.cursor()

    cur.execute("""
        INSERT INTO records(user_id, timestamp, heart_rate, blood_pressure, notes)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(user_id) DO UPDATE SET
            timestamp       = excluded.timestamp,
            heart_rate      = excluded.heart_rate,
            blood_pressure  = excluded.blood_pressure,
            notes           = excluded.notes
        WHERE
            timestamp      != excluded.timestamp OR
            heart_rate     != excluded.heart_rate OR
            blood_pressure != excluded.blood_pressure OR
            notes IS NOT excluded.notes
    """, vals)

    if cur.rowcount == 1: # new row inserted
        status = ('created', 201)
    elif cur.rowcount == 2: # updated existing user on differing column
        status = ('updated', 200)
    else:  # 0 -> conflict
        abort(409, 'Duplicate record: no change')

    db_conn.commit()
    return jsonify({'status': status[0]}), status[1]

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
    ctx=('/certs/server.crt','/certs/server.key')
    app.run(host='0.0.0.0',port=443,ssl_context=ctx)
