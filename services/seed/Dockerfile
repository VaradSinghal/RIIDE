FROM python:3.12-slim

WORKDIR /svc

COPY shared/ /svc/shared/
RUN pip install --no-cache-dir sqlalchemy psycopg2-binary

COPY seed/ /svc/seed/

CMD ["python", "seed/seed_all.py"]
