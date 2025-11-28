import os
from fastapi import FastAPI, File, UploadFile, Depends, HTTPException, status
from fastapi.responses import FileResponse
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import List
from datetime import datetime
from pathlib import Path

app = FastAPI()
security = HTTPBearer()

UPLOAD_DIR = Path(os.getenv("UPLOAD_DIR", "uploads"))
TOKEN = os.getenv("API_TOKEN", "changeme")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    if credentials.credentials != TOKEN:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

@app.post("/upload", dependencies=[Depends(verify_token)])
async def upload_file(files: List[UploadFile] = File(...)):
    saved_files = []
    date_dir = UPLOAD_DIR / datetime.now().strftime("%Y-%m-%d")
    date_dir.mkdir(parents=True, exist_ok=True)
    for file in files:
        file_path = date_dir / file.filename
        with open(file_path, "wb") as f:
            f.write(await file.read())
        saved_files.append(str(file_path))
    return {"saved": saved_files}

@app.get("/files", dependencies=[Depends(verify_token)])
def list_files():
    files = []
    for root, _, filenames in os.walk(UPLOAD_DIR):
        for name in filenames:
            files.append(os.path.relpath(os.path.join(root, name), UPLOAD_DIR))
    return {"files": files}

@app.get("/download/{file_path:path}", dependencies=[Depends(verify_token)])
def download_file(file_path: str):
    abs_path = UPLOAD_DIR / file_path
    if not abs_path.exists():
        raise HTTPException(status_code=404, detail="File not found")
    return FileResponse(abs_path)
