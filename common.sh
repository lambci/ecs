#!/bin/bash -e

[ -n "$START_TIME" ] || export START_TIME=$(date +%s)

export SCRIPT_DIR=$(cd $(dirname $0) && pwd)

export CLONE_DIR="/tmp/lambci/${LAMBCI_REPO}/${LAMBCI_COMMIT}"

export LAMBCI_BUILD_NUM="${LAMBCI_BUILD_NUM:-1}"
export LAMBCI_BRANCH="${LAMBCI_BRANCH:-master}"
export LAMBCI_CLONE_REPO="${LAMBCI_CLONE_REPO:-$LAMBCI_REPO}"
export LAMBCI_CHECKOUT_BRANCH="${LAMBCI_CHECKOUT_BRANCH:-$LAMBCI_BRANCH}"
export LAMBCI_DOCKER_CMD="${LAMBCI_DOCKER_CMD:-$SCRIPT_DIR/runbuild.sh}"
export LAMBCI_DOCKER_FILE="${LAMBCI_DOCKER_FILE:-Dockerfile.test}"
export LAMBCI_DOCKER_TAG="${LAMBCI_DOCKER_TAG:-lambci-ecs-${LAMBCI_REPO,,}:${LAMBCI_COMMIT}}"

export CONTAINER_ID=$(cat /proc/self/cgroup | grep "cpu:/" | sed 's/\([0-9]\):cpu:\/docker\///g')

export LOG_FILE="${SCRIPT_DIR}/lambci.log"
export LOG_GROUP="${LOG_GROUP:-/lambci/ecs}"
export LOG_STREAM="${LOG_STREAM:-$CONTAINER_ID}"

export STACK="${STACK:-lambci}"

cleanup() {
  EXIT_STATUS=$1

  if [ $EXIT_STATUS -eq 0 ]; then
    echo "Build #${LAMBCI_BUILD_NUM} successful" | tee "$LOG_FILE"
    github_status success "Build #${LAMBCI_BUILD_NUM} successful"
    slack_status good "Build #${LAMBCI_BUILD_NUM} successful" '' "Success: ${LAMBCI_REPO} #${LAMBCI_BUILD_NUM}"
  else
    echo "Build #${LAMBCI_BUILD_NUM} failed" | tee "$LOG_FILE"
    github_status failure "Build #${LAMBCI_BUILD_NUM} failed"
    slack_status danger "Build #${LAMBCI_BUILD_NUM} failed" "$(json_escape "\`\`\`$(tail -60 "$LOG_FILE")\`\`\`")" \
       "Failed: ${LAMBCI_REPO} #${LAMBCI_BUILD_NUM}"
  fi
}

github_status() {
  github_request "repos/${LAMBCI_REPO}/statuses/${LAMBCI_COMMIT}" \
'{
  "state": "'"$1"'",
  "description": "'"$2"'",
  "target_url": "'"$(aws_log_url)"'",
  "context": "continuous-integration/'"${STACK}"'"
}'
}

slack_status() {
  if [ -n "$3" ]; then
    # Must be JSON escaped already, including surrounding double quotes
    local STATUS_TEXT='"text": '"$3"', "mrkdwn_in": ["text"],'
  fi
  if [ -n "$LAMBCI_PULL_REQUEST" ]; then
    local TITLE="Pull Request"
    local VALUE="<https://github.com/${LAMBCI_REPO}/pull/${LAMBCI_PULL_REQUEST}|#${LAMBCI_PULL_REQUEST}>"
  else
    local TITLE="Branch"
    local VALUE="<https://github.com/${LAMBCI_REPO}/tree/${LAMBCI_BRANCH}|${LAMBCI_BRANCH}>"
  fi
  slack_msg --data-urlencode attachments=\
'[{
  "color": "'"$1"'",
  "title": "'"$2"'",
  "title_link": "'"$(aws_log_url)"'",
  "fallback": "'"${4:-$2}"'",
  '"$STATUS_TEXT"'
  "fields": [{
    "title": "Repository",
    "value": "<https://github.com/'"$LAMBCI_REPO"'|'"$LAMBCI_REPO"'>",
    "short": true
  }, {
    "title": "'"$TITLE"'",
    "value": "'"$VALUE"'",
    "short": true
  }]
}]'
}

github_request() {
  [ -n "$GITHUB_TOKEN" ] || return 0
  curl -s -u ${GITHUB_TOKEN}:x-oauth-basic -H 'User-Agent: lambci' \
    -H 'Accept: application/vnd.github.v3+json' -H 'Content-Type: application/vnd.github.v3+json' \
    -d "$2" "https://api.github.com/$1" > /dev/null
}

slack_msg() {
  [ -n "$SLACK_TOKEN" ] || return 0
  ARGS=(-d token="$SLACK_TOKEN" -d channel="${SLACK_CHANNEL:-#general}" -d username="${SLACK_USERNAME:-LambCI}")
  ARGS+=(-d icon_url="${SLACK_ICON_URL:-https://lambci.s3.amazonaws.com/assets/logo-48x48.png}")
  [ -n "$SLACK_AS_USER" ] && ARGS+=(-d as_user=true)
  curl -s "${ARGS[@]}" "$@" https://slack.com/api/chat.postMessage > /dev/null
}

aws_log_url() {
  node -p '
    var region = "'"${AWS_REGION:-us-east-1}"'"
    var params = {
      group: "'"$LOG_GROUP"'",
      stream: "'"$LOG_STREAM"'",
      start: new Date('$START_TIME' * 1000).toISOString().slice(0, 19) + "Z",
    }
    "https://console.aws.amazon.com/cloudwatch/home?region=" + region + "#logEvent:" +
      Object.keys(params).map(function(key) { return key + "=" + encodeURIComponent(params[key]) }).join(";")
  '
}

json_escape() {
  node -p 'JSON.stringify(process.argv[1])' -- "$1"
}

