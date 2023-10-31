# Git Watcher (NTFY)

A command line tool to watch file changes on git repositories and send notifications to your NTFY topics that can be
used with cron jobs to schedule tasks.

## Install

#### Mac:

```bash
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/BirjuVachhani/git_watcher/main/install_mac.sh -sSf | bash
```

#### Linux:

```bash
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/BirjuVachhani/git_watcher/main/install_linux.sh -sSf | bash
```

## Usage

```
A CLI tool to watch files on git repositories and notify with NTFY.

Usage: gitwatcher <command> [arguments]

Global options:
-h, --help       Print this usage information.
-v, --version    Print the version of the tool.

Available commands:
  disable   Remove a watcher from the watchlist.
  enable    Remove a watcher from the watchlist.
  list      List all the watchers from the watchlist.
  ntfy      Configure NTFY.
  remove    Remove a watcher from the watchlist.
  run       Run all the watchers and notify with NTFY.
  version   Print the version of the tool.
  watch     Watch files on git repositories and notify with NTFY.

Run "gitwatcher help <command>" for more information about a command.
```