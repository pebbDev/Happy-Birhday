#!/usr/bin/env python3
"""Manual authenticated Tencent DEV smoke test; credentials never printed."""
import argparse,datetime,hashlib,hmac,json,time,urllib.error,urllib.request
from pathlib import Path

URL="https://1499705522-0rfi31sgyj.ap-singapore.tencentscf.com"
ACCOUNT_UIN="200053398655"

def h(s):return hashlib.sha256(s.encode()).hexdigest()
def mac(key,msg):return hmac.new(key,msg.encode(),hashlib.sha256).digest()

def sign_headers(path, c):
    host=URL.removeprefix("https://")
    t=int(time.time()); day=datetime.datetime.fromtimestamp(t,datetime.timezone.utc).strftime("%Y-%m-%d")
    scope=f"{day}/scf/tc3_request"
    signed="content-type;host"
    canonical=f"GET\n{path}\n\ncontent-type:application/json\nhost:{host}\n\n{signed}\n{h('')}"
    msg=f"TC3-HMAC-SHA256\n{t}\n{scope}\n{h(canonical)}"
    key=mac(mac(mac(("TC3"+c["secretKey"]).encode(),day),"scf"),"tc3_request")
    sig=hmac.new(key,msg.encode(),hashlib.sha256).hexdigest()
    authorization=f"TC3-HMAC-SHA256 Credential={c['secretId']}/{scope}, SignedHeaders={signed}, Signature={sig}"
    return {"Authorization":authorization,"Content-Type":"application/json","Host":host,"X-Scf-Cam-Uin":ACCOUNT_UIN,"X-Scf-Cam-Timestamp":str(t)}

def fetch(path, headers):
    request=urllib.request.Request(URL+path,headers=headers)
    try:
        with urllib.request.urlopen(request,timeout=25) as result:return result.status,result.read(256)
    except urllib.error.HTTPError as e:return e.code,e.read(256)

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--profile",default="cvm-operator")
    p.add_argument("--expect-ready",type=int,choices=[200,503],default=200)
    a=p.parse_args()
    c=json.loads((Path.home()/".tccli"/(a.profile+".credential")).read_text(encoding="utf-8"))
    for path, expected in [("/health/live",200),("/health/ready",a.expect_ready)]:
        anon,_=fetch(path,{})
        signed,body=fetch(path,sign_headers(path,c))
        try: status=json.loads(body).get("status","unknown")
        except (ValueError,TypeError):status="non-JSON"
        print(f"{path}: anonymous={anon}; CAM={signed}; body.status={status}")
        if anon!=436 or signed!=expected:raise SystemExit("FAIL: expected anonymous 436 and signed "+str(expected))
    print("PASS")
if __name__=="__main__":main()
