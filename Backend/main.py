from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import paragon_router, home_router, stats_router, receipt_router


app = FastAPI()

app.include_router(home_router.router)
app.include_router(paragon_router.router)
app.include_router(stats_router.router)
app.include_router(receipt_router.router)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)