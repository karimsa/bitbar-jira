#!/bin/bash
set -e
set -o pipefail

export PATH="$PATH:/usr/local/bin"

function assert_env_var() {
	if test -z "$2"; then
		echo "Missing env var: $1"
		exit 1
	fi
}

if ! jq --version &>/dev/null; then
	echo "Did not find 'jq' on your system."
	exit 1
fi

assert_env_var "JIRA_NAMESPACE" "$JIRA_NAMESPACE"
assert_env_var "JIRA_PROJECT" "$JIRA_PROJECT"
assert_env_var "JIRA_USERNAME" "$JIRA_USERNAME"
assert_env_var "JIRA_API_KEY" "$JIRA_API_KEY"

echo "JIRA / $JIRA_PROJECT"
echo "---"

function ls_issues() {
	curl \
		-fsSL \
		-u "${JIRA_USERNAME}:${JIRA_API_KEY}" \
		https://${JIRA_NAMESPACE}.atlassian.net/rest/api/3/search\?jql\=`echo "project = ${JIRA_PROJECT} AND (fixVersion IS EMPTY OR fixVersion IN unreleasedVersions()) AND status = '${1}' ORDER BY updated DESC" | sed 's/ /%20/'g` \
		| jq -c '.issues[]' \
		| while read row; do
		echo "$row" | jq -r "\":$2: [\(.key)] \(.fields.summary) (\(.duedate)) | href=https://${JIRA_NAMESPACE}.atlassian.net/browse/\(.key)\""

		echo "Backlog,Selected for Development,In Progress,Done," | while read -d, status; do
			echo "--Move to $status | bash=$HOME/.bitbar-jira.sh param1=$JIRA_NAMESPACE param2=`echo "$row" | jq -r .key` param3=$JIRA_USERNAME param4=$JIRA_API_KEY param5='$status' terminal=false"
		done
	done
}

cat > ~/.bitbar-jira.sh << _EOF
#!/bin/bash
set -e
set -o pipefail

JIRA_NAMESPACE=\$1
JIRA_ISSUE_KEY=\$2
JIRA_USERNAME=\$3
JIRA_API_KEY=\$4
JIRA_TRANSITION=\$5

transitionID=\`curl -fsSL -u "\${JIRA_USERNAME}:\${JIRA_API_KEY}" https://${JIRA_NAMESPACE}.atlassian.net/rest/api/3/issue/\$JIRA_ISSUE_KEY/transitions | jq -r ".transitions[] | select(.name == \"\$JIRA_TRANSITION\") | .id"\`
if test -z "\$transitionID"; then
	echo "No such transition exists."
	exit 1
fi

curl \
	-fsSL \
	-u "\${JIRA_USERNAME}:\${JIRA_API_KEY}" \
	-X POST \
	-H 'Content-Type: application/json' \
	--data "{\"transition\":{\"id\":\"\$transitionID\"}}" \
	https://${JIRA_NAMESPACE}.atlassian.net/rest/api/3/issue/\$JIRA_ISSUE_KEY/transitions
open -g "bitbar://refreshPlugin?name=jira*.*.sh"

_EOF
chmod +x ~/.bitbar-jira.sh

ls_issues "Selected for Development" "memo"
ls_issues "In Progress" "construction"
ls_issues "Done" "white_check_mark"

echo "---"
boardID=`curl -fsSL -u "${JIRA_USERNAME}:${JIRA_API_KEY}" https://${JIRA_NAMESPACE}.atlassian.net/rest/agile/1.0/board | jq -r ".values[] | select(.location.projectKey == \"${JIRA_PROJECT}\") | .id"`
echo "Visit board | href=https://${JIRA_NAMESPACE}.atlassian.net/secure/RapidBoard.jspa?rapidView=${boardID}"
echo "Releases | href=https://${JIRA_NAMESPACE}.atlassian.net/projects/${JIRA_PROJECT}?selectedItem=com.atlassian.jira.jira-projects-plugin:release-page"
echo "Refresh Issues | terminal=false refresh=true"
