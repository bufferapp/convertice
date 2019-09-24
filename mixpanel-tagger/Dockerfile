FROM python:3

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

COPY main.py /app/main.py

WORKDIR /app

CMD ["python", "main.py"]
