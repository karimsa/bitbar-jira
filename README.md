# bitbar-jira

Lists issues in your JIRA project. Mainly just for HireFast usage.

## Usage

Place a file called `jira.5m.sh` in `~/.bitbar`:

```shell
#!/bin/bash

JIRA_NAMESPACE=hirefast
JIRA_USERNAME=karim@hirefast.ca
JIRA_API_KEY=keyboardcat
JIRA_PROJECT=DEV

curl -fsSL https://raw.githubusercontent.com/karimsa/bitbar-jira/master/list-issues.sh | sh
```

