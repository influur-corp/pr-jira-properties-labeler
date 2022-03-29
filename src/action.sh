#!/usr/bin/env bash

source "$ROOT_DIRECTORY/src/github.sh"
source "$ROOT_DIRECTORY/src/jira.sh"

action::setInputVariables() {
    GITHUB_TOKEN=$1
    JIRA_ENCODED_TOKEN=$2
    JIRA_URI=$3
    REGEXP_JIRA_ISSUE_CODE_ON_PR_TITLE=$4
    ISSUE_PROPERTIES=$5
}

action::input::githubToken() {
    echo "$GITHUB_TOKEN"
}

action::input::jiraUri() {
    echo "$JIRA_URI"
}

action::input::jiraEncodedToken() {
    echo "$JIRA_ENCODED_TOKEN"
}

action::input::regexpJiraCodeOnPrTitle() {
    local input_regexp=$REGEXP_JIRA_ISSUE_CODE_ON_PR_TITLE

    if [[ -z $input_regexp ]]; then
        echo '^([A-Z]{3}-[0-9]{4}).*'
    fi

    echo "$input_regexp"
}

action::input:issueProperties() {
    echo "$ISSUE_PROPERTIES"
}

action::getJiraCodeFromPRTitle() {
    local pr_title
    pr_title=$(github::getPullRequestTitle)

    local jira_code
    jira_code=$(echo "$pr_title" | grep -Eo 'INFM-[0-9]{3,4}')

    if [[ "$pr_title" == "$jira_code" ]]; then
      echo false
      exit
    fi

    echo "$jira_code"
}

action::addPriorityLabel() {
    local issue_code=$1
    local issue_prio
    issue_prio=$(jira::getPriorityOf "$issue_code")

    echo "Prio: $issue_prio"

    github::addLabelsToThePR "$issue_prio"
}

action::addFixVersionLabel() {
    local issue_code=$1
    local fix_version
    fix_version=$(jira::getFixVersionOf "$issue_code")

    if [[ $fix_version == "null" ]]; then
      echo false
      exit
    fi

    echo "fix_version: $fix_version"

    github::addLabelsToThePR "$fix_version"
}

action::run() {
    if [[ -z "$GITHUB_REPOSITORY" ]]; then
        echo "Set the GITHUB_REPOSITORY env variable."
        exit 1
    fi

    action::setInputVariables "$@"

    local issue_code
    issue_code=$(action::getJiraCodeFromPRTitle)

    if [[ $issue_code == false ]];then
      echo "Nothing to do, exiting..."
      exit 0
    fi

    echo "issue code: $issue_code"

    echo "Adding priority label to the PR..."
	  action::addFixVersionLabel "$issue_code"
}
