from fastapi import FastAPI
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
from fastapi.responses import Response
from .db import init_db
from .routes import router

app = FastAPI(title="TaskAPI")


@app.on_event("startup")
def on_startup():
    init_db()


app.include_router(router)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/metrics")
def metrics():
    data = generate_latest()
    return Response(content=data, media_type=CONTENT_TYPE_LATEST)