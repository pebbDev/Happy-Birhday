#!/usr/bin/env python3
"""Prepare/apply Supabase DEV CA to Tencent SCF; never print DATABASE_URL.

Example:
  python infra/tencent/tools/configure_tls_ca.py --cert "$HOME/Downloads/prod-ca-2021.crt"
  python infra/tencent/tools/configure_tls_ca.py --cert "$HOME/Downloads/prod-ca-2021.crt" --apply

Without --apply: local TLS/SELECT 1 only; no cloud configuration updates.
"""
import argparse
import base64
import json
import os
from pathlib import Path
import re
import ssl
import subprocess
from urllib.parse import urlsplit, urlunsplit, parse_qsl, urlencode

DEV_REF = "daelpglayqvibpsbklwe"
REGION = "ap-singapore"
FUNCTION = "hbd-api-dev"
NAMESPACE = "hbd-dev"

def validate_cert(path: Path) -> str:
    text = path.read_text(encoding="ascii").strip()
    match = re.fullmatch(r"-----BEGIN CERTIFICATE-----\s+[A-Za-z0-9+/=\s]+-----END CERTIFICATE-----", text)
    if not match:
        raise SystemExit("Certificate rejected: expected one PEM CA certificate from Supabase Dashboard.")
    try:
        ssl.PEM_cert_to_DER_cert(text)
    except ValueError:
        raise SystemExit("Certificate rejected: invalid PEM encoding.") from None
    return text + "\n"

def prepare_url(uri: str) -> str:
    x = urlsplit(uri)
    if not x.hostname or not x.hostname.endswith(".pooler.supabase.com") or x.port != 6543 or x.username != "postgres." + DEV_REF or x.path != "/postgres" or not x.password:
        raise SystemExit("Incorrect DEV pooler URI in SCF; no changes applied.")
    query = [(k, v) for k, v in parse_qsl(x.query, keep_blank_values=True) if k != "sslmode"]
    return urlunsplit((x.scheme, x.netloc, x.path, urlencode(query), ""))

def test_local_pg(uri: str, pem: str) -> bool:
    # Signed-in computer test. No URI or PEM is included in command argv, stdout or files.
    js = '''import pg from 'pg';
const c = new pg.Client({
  connectionString: process.env.HBD_DIAG_DSN,
  ssl: { ca: process.env.HBD_DIAG_CA, rejectUnauthorized: true },
  connectionTimeoutMillis: 6000,
});
try {
  await c.connect();
  const r = await c.query('SELECT 1 AS ready');
  console.log('LOCAL_TLS_VERIFIED_QUERY', r.rows[0].ready === 1 ? 'PASS' : 'FAIL');
} catch (e) {
  console.log('LOCAL_TLS_VERIFIED_QUERY', 'FAIL', 'ERROR_CODE', String(e.code || 'UNKNOWN').replace(/[^A-Z0-9_]/gi,''));
} finally { try { await c.end(); } catch {} }
'''
    env = os.environ.copy()
    env["HBD_DIAG_DSN"] = uri
    env["HBD_DIAG_CA"] = pem
    try:
        p = subprocess.run(["node", "--input-type=module", "-e", js], cwd=str(Path.cwd()/"apps"/"api"), env=env, capture_output=True, timeout=25)
    except (OSError, subprocess.TimeoutExpired):
        print("LOCAL_TLS_VERIFIED_QUERY FAILED: Node not executable or connection timed out.")
        return False
    line = p.stdout.decode("utf-8", "replace")
    if line.strip():
        # Print only predictable status, never arbitrary stderr.
        print("LOCAL_TLS_VERIFIED_QUERY PASS" if "LOCAL_TLS_VERIFIED_QUERY PASS" in line else "LOCAL_TLS_VERIFIED_QUERY FAIL", "(see local Node TLS or DB configuration)")
    return p.returncode == 0 and "LOCAL_TLS_VERIFIED_QUERY PASS" in line

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--profile", default="cvm-operator")
    p.add_argument("--cert", type=Path, required=True, help="CA PEM downloaded from Supabase DEV > Database > Settings > SSL Configuration")
    p.add_argument("--apply", action="store_true", help="Write public CA to SCF function config after local query test passes")
    args = p.parse_args()
    cert = validate_cert(args.cert.expanduser())
    from tencentcloud.common import credential
    from tencentcloud.scf.v20180416 import scf_client, models
    c = json.loads((Path.home()/".tccli"/(args.profile+".credential")).read_text(encoding="utf8"))
    client = scf_client.ScfClient(credential.Credential(c["secretId"], c["secretKey"]), REGION)
    req = models.GetFunctionRequest()
    req.from_json_string(json.dumps({"FunctionName": FUNCTION, "Namespace": NAMESPACE}))
    obj = json.loads(client.GetFunction(req).to_json_string())
    if obj.get("Status") != "Active":
        raise SystemExit("SCF not Active; no changes applied.")
    variables = (obj.get("Environment") or {}).get("Variables") or []
    existing = {v["Key"]:v["Value"] for v in variables}
    if "DATABASE_URL" not in existing:
        raise SystemExit("DATABASE_URL missing in SCF; no changes applied.")
    uri = prepare_url(existing["DATABASE_URL"])
    if not test_local_pg(uri, cert):
        raise SystemExit("TLS/DB test did not pass; refusing SCF modification. Check downloaded certificate and password.")
    if not args.apply:
        print("CHECK ONLY: No cloud changes. To apply trusted CA, rerun with --apply.")
        return
    existing["SUPABASE_DB_CA_CERT_BASE64"] = base64.b64encode(cert.encode("ascii")).decode("ascii")
    update = models.UpdateFunctionConfigurationRequest()
    update.from_json_string(json.dumps({"FunctionName":FUNCTION,"Namespace":NAMESPACE,"Environment":{"Variables":[{"Key":k,"Value":v} for k,v in existing.items()]}}))
    try:
        client.UpdateFunctionConfiguration(update)
    except Exception:
        raise SystemExit("SCF update failed; cloud error intentionally suppressed to protect secrets.") from None
    print("SCF CA environment update submitted. Certificate is public; database URI not printed. Wait for Active and deploy CA-aware API build.")

if __name__ == "__main__":
    main()
