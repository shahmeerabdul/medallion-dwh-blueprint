"""Database and application configuration."""

import os
from pathlib import Path

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

# Project root (parent of dashboard/)
PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATASETS_DIR = PROJECT_ROOT / "datasets"

# MySQL connection (Gold layer)
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "medallion_dw")

# Set USE_CSV=1 to force CSV fallback (useful without MySQL)
FORCE_CSV = os.getenv("USE_CSV", "0") == "1"
