#!/usr/bin/env python3
"""Interactive DEV-only SCF DATABASE_URL installer.

User supplies an actual Supabase DEV transaction-pooler URI in a *local* hidden terminal.
Never put a secret in chat, Git, shell history, CI output, or logs.
Requires Tencent local CAM profile (manual operator only; NOT CI).
"""
import argparse,getpass,json
from pathlib import Path
from urllib.parse import urlsplit,parse_qsl,urlunsplit,urlencode

DEV_REF="daelpglayqvibpsbklwe"
FUNCTION="hbd-api-dev"
NAMESPACE="hbd-dev"
REGION="ap-singapore"

def validate(url):
    """Check DEV pooler target and require TLS without exposing URI or password."""
    raw=url.strip()
    if len(raw)>=2 and raw[0]==raw[-1] and raw[0] in ("\"", "'"):
        raw=raw[1:-1].strip()
    try:
        parsed=urlsplit(raw)
        if parsed.scheme not in ("postgres", "postgresql"):
            raise ValueError("URI harus diawali postgresql:// atau postgres://.")
        if not parsed.hostname or not parsed.hostname.endswith(".pooler.supabase.com"):
            raise ValueError("Host bukan shared Supabase Pooler. Salin URI dari Connect > Transaction pooler.")
        if parsed.port != 6543:
            raise ValueError("Port bukan 6543. Pilih Transaction pooler, bukan Session pooler atau Direct connection.")
        if parsed.username != "postgres."+DEV_REF:
            raise ValueError("Username tidak sesuai project DEV. Harus postgres."+DEV_REF+".")
        if parsed.path != "/postgres":
            raise ValueError("Nama database harus /postgres.")
        if not parsed.password or parsed.password.startswith("[") and parsed.password.endswith("]"):
            raise ValueError("Password database belum diisi atau masih placeholder.")
        if parsed.fragment:
            raise ValueError("URI memiliki fragment (#); URL-encode karakter spesial pada password.")
        query=parse_qsl(parsed.query, keep_blank_values=True)
        modes=[v for k,v in query if k=="sslmode"]
        if not modes:
            query.append(("sslmode", "require"))
            print("TLS: parameter sslmode=require ditambahkan otomatis (tanpa menampilkan URI).")
        elif modes != ["require"]:
            raise ValueError("Hanya sslmode=require yang didukung skrip ini; nilai lain ditolak.")
        return urlunsplit((parsed.scheme,parsed.netloc,parsed.path,urlencode(query),""))
    except (ValueError,TypeError) as error:
        if isinstance(error, ValueError) and str(error).startswith("invalid literal"):
            reason="Port salah atau tidak valid."
        elif isinstance(error, ValueError) and str(error).startswith("Port could not"):
            reason="Port bukan angka valid."
        else:
            reason=str(error)
        raise SystemExit("Rejected: " + reason + " Tidak ada konfigurasi SCF yang diubah.") from None

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--profile",default="cvm-operator")
    p.add_argument("--check-only",action="store_true",help="Validate hidden URI locally without calling Tencent APIs")
    args=p.parse_args()
    url=validate(getpass.getpass("Paste DEV transaction-pooler DATABASE_URL (hidden): ").strip())
    if args.check_only:
        print("FORMAT OK: DEV transaction pooler dan TLS tervalidasi secara lokal. Tidak ada perubahan cloud.")
        return
    from tencentcloud.common import credential
    from tencentcloud.scf.v20180416 import scf_client,models
    creds=json.loads((Path.home()/".tccli"/(args.profile+".credential")).read_text(encoding="utf-8"))
    client=scf_client.ScfClient(credential.Credential(creds["secretId"],creds["secretKey"]),REGION)
    get=models.GetFunctionRequest()
    get.from_json_string(json.dumps({"FunctionName":FUNCTION,"Namespace":NAMESPACE}))
    existing=json.loads(client.GetFunction(get).to_json_string())
    if existing.get("Status")!="Active":
        raise SystemExit("SCF must be Active before updating environment.")
    variables=(existing.get("Environment") or {}).get("Variables") or []
    variables=[{"Key":v["Key"],"Value":v["Value"]} for v in variables if v.get("Key")!="DATABASE_URL"]
    variables.append({"Key":"DATABASE_URL","Value":url})
    request=models.UpdateFunctionConfigurationRequest()
    request.from_json_string(json.dumps({"FunctionName":FUNCTION,"Namespace":NAMESPACE,"Environment":{"Variables":variables}}))
    try:
        client.UpdateFunctionConfiguration(request)
    except Exception:
        raise SystemExit("SCF configuration failed; error suppressed to avoid exposing database URI. Inspect Tencent audit/error code securely.")
    print("SCF configuration update submitted. Secret not printed or stored locally. Re-check SCF Active, then test signed /health/ready.")
if __name__=="__main__":main()
