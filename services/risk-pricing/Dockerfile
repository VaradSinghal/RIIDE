FROM python:3.12-slim

WORKDIR /svc

COPY shared/ /svc/shared/
COPY risk-pricing/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY risk-pricing/ .

EXPOSE 8002
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8002"]
