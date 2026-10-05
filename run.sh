 #!/usr/bin/env bash
  set -euo pipefail

  cd "$(dirname "$0")"

  for container in serebryakov-08-web serebryakov-08-db; do
    if docker container inspect "$container" >/dev/null 2>&1; then
      docker rm -f "$container"
    fi
  done

  docker build --build-arg VERSION=2.0 \
    -t serebryakov-08/probe:2.0 .

  docker volume create serebryakov-08-data

  docker run -d --name serebryakov-08-db \
    -p 8026:3306 \
    -e MARIADB_ROOT_PASSWORD=lab \
    -e MARIADB_DATABASE=lab \
    -v serebryakov-08-data:/var/lib/mysql \
    mariadb:11

  docker run -d --name serebryakov-08-web \
    -p 8024:5008 \
    --add-host host.docker.internal:host-gateway \
    -e APP_PORT=5008 \
    -e MARKER=netlab \
    -e DATABASE_URL=mysql://root:lab@host.docker.internal:8026/lab \
    serebryakov-08/probe:2.0

  echo "Ожидание готовности приложения и базы..."
  SECONDS=0
  until curl -sf -m 3 localhost:8024/notes >/dev/null; do
    if [ "$SECONDS" -ge 60 ]; then
      echo "Стенд не готов за 60 секунд."
      docker logs --tail 20 serebryakov-08-db
      exit 1
    fi
    sleep 2
  done

  echo "Стенд готов: приложение localhost:8024, база на порту 8026"
  docker ps --filter name=serebryakov-08
  curl -s localhost:8024/notes
  echo
