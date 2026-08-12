FROM python:3.12-slim

WORKDIR /svc

COPY gateway/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY gateway/ .

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
