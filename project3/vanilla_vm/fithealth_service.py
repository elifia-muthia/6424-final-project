import os
import sqlite3
import subprocess
import logging
import time
import secrets

from metrics_sampler import latest_sample
from flask import Flask, request, jsonify, abort

# Configuration
DB_PATH = '/data/fithealth.db'

app = Flask(__name__)

start_time = int(time.time() * 1000)
key_retrieved_ms = None

def get_encryption_key():
    """Fetch the latest secret directly—no TDX involved."""
    proc = subprocess.run(
        ['gcloud', 'secrets', 'versions', 'access', 'latest', '--secret=fithealth-sqlcipher-key'],
        stdout=subprocess.PIPE, check=True
    )
    return proc.stdout.decode().strip()

def init_db(conn, key_hex):
    conn.execute(f"PRAGMA key = \"x'{key_hex}'\";")
    conn.execute('''
        CREATE TABLE IF NOT EXISTS records (
            user_id TEXT NOT NULL PRIMARY KEY,
            timestamp INTEGER NOT NULL,
            heart_rate INTEGER NOT NULL,
            blood_pressure TEXT NOT NULL,
            notes BLOB
        );
    ''')
    conn.commit()

def get_db_connection(key_hex):
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    init_db(conn, key_hex)
    return conn

# Fetch key once at startup
encryption_key = get_encryption_key()
key_retrieved_ms = int(time.time() * 1000)
logging.info("KEY_RETRIEVED %d", key_retrieved_ms)

db_conn = get_db_connection(encryption_key)

@app.route('/metrics', methods=['GET'])
def get_metrics():
    row_cnt = db_conn.execute("SELECT COUNT(*) FROM records").fetchone()[0]
    return jsonify({
        "start_time": start_time,
        "key_retrieved_ms": key_retrieved_ms,
        "records": row_cnt,
        "cpu_percent": latest_sample.get("cpu_percent"),
        "mem_bytes": latest_sample.get("mem_bytes"),
        "metrics_ts": latest_sample.get("timestamp_ms")
    }), 200

@app.route('/fetch_all', methods=['GET'])
def fetch_all():
    rows = db_conn.execute('SELECT * FROM records').fetchall()
    payload = [
        dict(zip(['user_id','timestamp','heart_rate','blood_pressure','notes'], row))
        for row in rows
    ]
    return jsonify(payload), 200

@app.route('/insert', methods=['POST'])
def insert_record():
    data = request.get_json(silent=True) or {}
    for k in ('user_id','timestamp','heart_rate','blood_pressure'):
        if k not in data:
            abort(400, f'Missing field: {k}')
    vals = (
        data['user_id'], data['timestamp'],
        data['heart_rate'], data['blood_pressure'],
        data.get('notes')
    )
    cur = db_conn.cursor()
    cur.execute("""
        INSERT INTO records(user_id, timestamp, heart_rate, blood_pressure, notes)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(user_id) DO UPDATE SET
            timestamp      = excluded.timestamp,
            heart_rate     = excluded.heart_rate,
            blood_pressure = excluded.blood_pressure,
            notes          = excluded.notes
        WHERE
            timestamp      != excluded.timestamp OR
            heart_rate     != excluded.heart_rate OR
            blood_pressure != excluded.blood_pressure OR
            notes IS NOT excluded.notes
    """, vals)
    db_conn.commit()
    if cur.rowcount == 1:
        return jsonify({'status':'created'}), 201
    elif cur.rowcount == 2:
        return jsonify({'status':'updated'}), 200
    else:
        abort(409, 'No change')
    
@app.route('/fetch/<user_id>', methods=['GET'])
def fetch_record(user_id):
    row = db_conn.execute(
        'SELECT * FROM records WHERE user_id = ?', (user_id,)
    ).fetchone()
    if not row:
        abort(404, 'User not found')
    return jsonify(dict(zip(
        ['user_id','timestamp','heart_rate','blood_pressure','notes'], row
    )))

@app.route('/', methods=['GET'])
def root():
    return 'FitHealth: Hello!', 200

if __name__ == '__main__':
    ctx=('/certs/server.crt','/certs/server.key')
    app.run(host='0.0.0.0', port=443, ssl_context=ctx, threaded=True)
