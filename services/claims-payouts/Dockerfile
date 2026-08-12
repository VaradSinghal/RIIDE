FROM python:3.12-slim

WORKDIR /svc

# Copy shared module
COPY shared/ /svc/shared/

# Install dependencies
COPY claims-payouts/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy service code
COPY claims-payouts/ .

EXPOSE 8003
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8003"]
