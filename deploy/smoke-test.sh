#!/bin/sh
set -eu

: "${GOVIEW_ADMIN_USERNAME:=admin}"
: "${GOVIEW_ADMIN_PASSWORD:?GOVIEW_ADMIN_PASSWORD is required}"

PROJECT_ID=
SECOND_ID=
UPLOAD_NAME=
UPLOAD_PATH=
cleanup() {
  if [ -n "${PROJECT_ID:-}" ] && [ -n "${TOKEN:-}" ]; then
    curl -fsS -H "satoken: $TOKEN" -X DELETE \
      "http://127.0.0.1:8082/api/goview/project/delete?ids=$PROJECT_ID" >/dev/null 2>&1 || true
  fi
  if [ -n "${SECOND_ID:-}" ]; then
    sudo -n sqlite3 /home/ubuntu/goview-deploy-staging/frontend/deploy/data/goview.db \
      "DELETE FROM t_sys_user WHERE id='$SECOND_ID';" >/dev/null 2>&1 || true
  fi
  if [ -n "${UPLOAD_NAME:-}" ]; then
    sudo -n sqlite3 /home/ubuntu/goview-deploy-staging/frontend/deploy/data/goview.db \
      "DELETE FROM t_sys_file WHERE file_name='$UPLOAD_NAME';" >/dev/null 2>&1 || true
  fi
  if [ -n "${UPLOAD_PATH:-}" ]; then
    sudo -n rm -f -- "$UPLOAD_PATH" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

sleep 3
printf '%s\n' '--- frontend ---'
curl -fsS -o /tmp/goview-index.html -w 'HTTP %{http_code} bytes %{size_download}\n' http://127.0.0.1:8082/
test -s /tmp/goview-index.html

printf '%s\n' '--- unauthenticated API ---'
code=$(curl -sS -o /tmp/goview-unauth.json -w '%{http_code}' http://127.0.0.1:8082/api/goview/project/list)
test "$code" = 401
echo "HTTP $code $(jq -r .msg /tmp/goview-unauth.json)"

printf '%s\n' '--- admin login ---'
curl -fsS -H 'Content-Type: application/json' \
  -d "{\"username\":\"$GOVIEW_ADMIN_USERNAME\",\"password\":\"$GOVIEW_ADMIN_PASSWORD\"}" \
  http://127.0.0.1:8082/api/goview/sys/login > /tmp/goview-login.json
jq -e '.code == 200 and (.data.userinfo.password == null)' /tmp/goview-login.json >/dev/null
TOKEN=$(jq -r .data.token.tokenValue /tmp/goview-login.json)

PROJECT=$(curl -fsS -H "satoken: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"projectName":"security-smoke","remarks":null,"indexImage":null}' \
  http://127.0.0.1:8082/api/goview/project/create)
PROJECT_ID=$(printf '%s' "$PROJECT" | jq -r .data.id)
test -n "$PROJECT_ID" -a "$PROJECT_ID" != null
printf 'created_project=%s\n' "$PROJECT_ID"

SAVE=$(curl -fsS -H "satoken: $TOKEN" \
  -F "projectId=$PROJECT_ID" -F 'content={"canvas":{}}' \
  http://127.0.0.1:8082/api/goview/project/save/data)
printf '%s\n' "$SAVE" | jq -e '.code == 200' >/dev/null

PUBLISH=$(curl -fsS -X PUT -H "satoken: $TOKEN" -H 'Content-Type: application/json' \
  -d "{\"id\":\"$PROJECT_ID\",\"state\":1}" \
  http://127.0.0.1:8082/api/goview/project/publish)
printf '%s\n' "$PUBLISH" | jq -e '.code == 200' >/dev/null
UNPUBLISH=$(curl -fsS -X PUT -H "satoken: $TOKEN" -H 'Content-Type: application/json' \
  -d "{\"id\":\"$PROJECT_ID\",\"state\":-1}" \
  http://127.0.0.1:8082/api/goview/project/publish)
printf '%s\n' "$UNPUBLISH" | jq -e '.code == 200' >/dev/null
printf '%s\n' 'publish_toggle=ok'

printf '%s\n' 'upload-smoke' >/tmp/goview-upload-smoke.txt
UPLOAD=$(curl -fsS -H "satoken: $TOKEN" -F object=@/tmp/goview-upload-smoke.txt \
  http://127.0.0.1:8082/api/goview/project/upload)
UPLOAD_NAME=$(printf '%s' "$UPLOAD" | jq -r .data.fileName)
UPLOAD_DATE=$(printf '%s' "$UPLOAD" | jq -r .data.relativePath)
test -n "$UPLOAD_NAME" -a "$UPLOAD_NAME" != null
UPLOAD_PATH="/home/ubuntu/goview-deploy-staging/frontend/deploy/uploads/$UPLOAD_DATE/$UPLOAD_NAME"
test -f "$UPLOAD_PATH"
printf '%s\n' 'upload=ok'

LIST=$(curl -fsS -H "satoken: $TOKEN" \
  'http://127.0.0.1:8082/api/goview/project/list?page=1&limit=12')
printf '%s\n' "$LIST" | jq -e --arg id "$PROJECT_ID" '.data | map(.id) | index($id) != null' >/dev/null
GET=$(curl -fsS -H "satoken: $TOKEN" \
  "http://127.0.0.1:8082/api/goview/project/getData?projectId=$PROJECT_ID")
printf '%s\n' "$GET" | jq -e --arg id "$PROJECT_ID" '.data.id == $id' >/dev/null
printf '%s\n' 'admin_project_access=ok'

printf '%s\n' '--- restart persistence ---'
sudo -n docker compose -f /home/ubuntu/goview-deploy-staging/frontend/deploy/docker-compose.yml restart backend >/dev/null
i=0
while [ "$i" -lt 20 ]; do
  health=$(sudo -n docker inspect --format '{{.State.Health.Status}}' goview-backend 2>/dev/null || true)
  [ "$health" = healthy ] && break
  i=$((i + 1))
  sleep 2
done
test "$health" = healthy
curl -fsS -H 'Content-Type: application/json' \
  -d "{\"username\":\"$GOVIEW_ADMIN_USERNAME\",\"password\":\"$GOVIEW_ADMIN_PASSWORD\"}" \
  http://127.0.0.1:8082/api/goview/sys/login > /tmp/goview-login-after-restart.json
TOKEN=$(jq -r .data.token.tokenValue /tmp/goview-login-after-restart.json)
PERSISTED=$(curl -fsS -H "satoken: $TOKEN" \
  "http://127.0.0.1:8082/api/goview/project/getData?projectId=$PROJECT_ID")
printf '%s\n' "$PERSISTED" | jq -e '.data.content == "{\"canvas\":{}}"' >/dev/null
printf '%s\n' 'database_persistence=ok'

printf '%s\n' '--- second user ---'
SECOND_ID=security-smoke-user
SECOND_HASH=$(printf '%s' 'security-smoke-password' | md5sum | awk '{print $1}')
sudo -n sqlite3 /home/ubuntu/goview-deploy-staging/frontend/deploy/data/goview.db \
  "INSERT INTO t_sys_user(id,username,password,nickname) VALUES ('$SECOND_ID','securitysmoke','$SECOND_HASH','Security Smoke');"
curl -fsS -H 'Content-Type: application/json' \
  -d '{"username":"securitysmoke","password":"security-smoke-password"}' \
  http://127.0.0.1:8082/api/goview/sys/login > /tmp/goview-second-login.json
SECOND_TOKEN=$(jq -r .data.token.tokenValue /tmp/goview-second-login.json)
SECOND_LIST=$(curl -fsS -H "satoken: $SECOND_TOKEN" \
  'http://127.0.0.1:8082/api/goview/project/list?page=1&limit=12')
printf '%s\n' "$SECOND_LIST" | jq -e '.data | length == 0' >/dev/null

code=$(curl -sS -o /tmp/goview-cross-get.json -w '%{http_code}' \
  -H "satoken: $SECOND_TOKEN" \
  "http://127.0.0.1:8082/api/goview/project/getData?projectId=$PROJECT_ID")
test "$code" = 200
jq -e '.code == 403' /tmp/goview-cross-get.json >/dev/null
printf '%s\n' 'cross_user_get=403'

code=$(curl -sS -o /tmp/goview-cross-delete.json -w '%{http_code}' -X DELETE \
  -H "satoken: $SECOND_TOKEN" \
  "http://127.0.0.1:8082/api/goview/project/delete?ids=$PROJECT_ID")
test "$code" = 200
jq -e '.code == 403' /tmp/goview-cross-delete.json >/dev/null
printf '%s\n' 'cross_user_delete=403'

curl -fsS -H "satoken: $TOKEN" -X DELETE \
  "http://127.0.0.1:8082/api/goview/project/delete?ids=$PROJECT_ID" | jq -e '.code == 200' >/dev/null
sudo -n sqlite3 /home/ubuntu/goview-deploy-staging/frontend/deploy/data/goview.db \
  "DELETE FROM t_sys_user WHERE id='$SECOND_ID';"
PROJECT_ID=
SECOND_ID=
printf '%s\n' 'cleanup=ok'
