# git_tooling

Git related scripts and configurations. Assumptions:

* You are using Linux with bash

# Setup to contribute to this repo

* This repo uses [pre-commit](https://pre-commit.com/) to ensure constancy. Please install.

# Prompt modification

To get this:

```
username@hostname ~
$ cd git/ansible/
username@hostname ~/git/ansible ansible (JIRA-123 branch name)
$
```


Add the following to your `~/.bashrc` file


```
# From https://gist.github.com/joseluisq/1e96c54fa4e1e5647940
parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# From https://stackoverflow.com/questions/15715825/how-do-you-get-the-git-repositorys-name-in-some-git-repository
parse_git_repo() {
  git rev-parse --show-toplevel 2> /dev/null | grep -o "[^/]*$"
}

export PS1='\[\033k\u@\h\033\134\\\] \[\e[33m\]\w\[\e[0m\] $(parse_git_repo)\[\033[32m\]$(parse_git_branch)\[\033[00m\]\n$ '
```

# Git templating

Git templates make sure all new cloned repos share certain configuration settings

```
mkdir -p ~/.git_template
git config --global init.templateDir ~/.git_template
```

# Git hooks

Update or add the hook files to your `~/.git_template/hooks` folder

```
mkdir -p ~/.git_template/hooks
```

* [pre-commit](./.git_template/hooks/pre-commit)
  * Prevent commit to the `main` branch
  * Run pre-commit, this can also be auto configured alone with:
  ```
  pre-commit init-templatedir ~/.git_template
  ```
* [prepare-commit-msg](./.git_template/hooks/prepare-commit-msg)
  * Add the Jira work item id to the commit message

Copy the files to you template folder:

```
cp -i ./.git_template/hooks/* ~/.git_template/hooks/
chmod +x ~/.git_template/hooks/*
```

Or create the files and modify them with only the code your want

```
touch ~/.git_template/hooks/commit-msg
touch ~/.git_template/hooks/pre-commit
touch ~/.git_template/hooks/prepare-commit-msg
chmod +x ~/.git_template/hooks/*
```

# Scripts

## [git_clone.sh](./scripts/git_clone.sh)

Clones and configures a git repo for ssh key signing in an environment where you have multiple Github identities configured in your ssh config file. It will scan your ssh config file for Github hosts and ask you to pick one to use for authentication when cloning the repo. It will then set the signing key for the repo to the identity file associated with the ssh host you picked.