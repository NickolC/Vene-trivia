from __future__ import annotations

import sqlite3
from pathlib import Path


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    sql_path = repo_root / "documents-internos" / "create_superadmin.sql"
    db_path = repo_root / "DB" / "venetrivia.db"

    if not sql_path.exists():
        print(f"No se encontro el SQL: {sql_path}")
        return 1

    if not db_path.exists():
        print(f"No se encontro la DB: {db_path}")
        return 1

    script = sql_path.read_text(encoding="utf-8")

    connection = sqlite3.connect(db_path)
    try:
        connection.executescript(script)
        connection.commit()

        rows = connection.execute(
            "SELECT NU_USU, NM_SUPERADMIN FROM SuperAdmin ORDER BY NU_USU"
        ).fetchall()
    finally:
        connection.close()

    print("Script SQL ejecutado correctamente.")
    print("Superadmins registrados:")
    for user_id, username in rows:
        print(f"- #{user_id} {username}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
