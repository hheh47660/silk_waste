FROM python:3.11-slim
WORKDIR /code
RUN pip install flask redis
COPY . .
CMD ["python", "app.py"]
