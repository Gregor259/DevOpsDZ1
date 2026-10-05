FROM python:3.11-alpine

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
ARG VERSION=dev
RUN echo "$VERSION" > /app/VERSION
ENV APP_PORT=5008
ENV PYTHONDONTWRITEBYTECODE=1
EXPOSE 5008
ENV MARKER=netlab
CMD ["python", "app.py"]

