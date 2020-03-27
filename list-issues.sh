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
		https://${JIRA_NAMESPACE}.atlassian.net/rest/api/3/search\?jql\=`echo "project = ${JIRA_PROJECT} AND resolution IS EMPTY AND status = '${1}' ORDER BY updated DESC" | sed 's/ /%20/'g`
}

ls_issues "Selected for Development" | jq -r ".issues[] | \":memo: [\(.key)] \(.fields.summary) (\(.duedate)) | href=https://${JIRA_NAMESPACE}.atlassian.net/browse/\(.key)\""
ls_issues "In Progress" | jq -r ".issues[] | \":construction: [\(.key)] \(.fields.summary) (\(.duedate)) | href=https://${JIRA_NAMESPACE}.atlassian.net/browse/\(.key)\""
ls_issues "Done" | jq -r ".issues[] | \":white_check_mark: [\(.key)] \(.fields.summary) (\(.duedate)) | href=https://${JIRA_NAMESPACE}.atlassian.net/browse/\(.key)\""

echo "---"
boardID=`curl -fsSL -u "${JIRA_USERNAME}:${JIRA_API_KEY}" https://${JIRA_NAMESPACE}.atlassian.net/rest/agile/1.0/board | jq -r ".values[] | select(.location.projectKey == \"${JIRA_PROJECT}\") | .id"`
echo "Visit board | href=https://${JIRA_NAMESPACE}.atlassian.net/secure/RapidBoard.jspa?rapidView=${boardID}"
