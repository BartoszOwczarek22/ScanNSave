from fastapi import APIRouter
from fastapi.responses import HTMLResponse

router = APIRouter()

@router.get("/", response_class=HTMLResponse)
def homepage():
    return """
    <html>
        <head><title>ScanNSave API</title></head>
        <body style="font-family:sans-serif;text-align:center;padding:50px;">
            <h1>🚀 ScanNSave działa!</h1>
            <p>Sprawdź <a href="/docs">dokumentację API</a>.</p>
        </body>
    </html>
    """
