# Часть 3. Python: автотест подключения к БД.

import os
from datetime import datetime

import psycopg


def test_database_connection():
    with psycopg.connect(
        host=os.getenv("PGHOST", "127.0.0.1"),
        port=os.getenv("PGPORT", "55432"),
        dbname=os.getenv("PGDATABASE", "testtask"),
        user=os.getenv("PGUSER", "testtask"),
        password=os.environ["PGPASSWORD"],
        connect_timeout=5,
    ) as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT now()")
            result = cursor.fetchone()

    assert result is not None, "Запрос не вернул строку"
    assert len(result) == 1, "Ожидался один столбец"
    assert isinstance(result[0], datetime), "Ожидалась дата и время PostgreSQL"
    assert result[0].tzinfo is not None, "Ожидалось время с часовым поясом"
