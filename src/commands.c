#define _POSIX_C_SOURCE 200809L
#include "commands.h"
#include "tui.h"
#include "utils.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

// Helper to emit shell commands
void emit_task(const char *type, const char *arg1, const char *arg2) {
  if (strcmp(type, "mkdir") == 0) {
    printf("mkdir -p '%s' \\\n  && ", arg1);
  } else if (strcmp(type, "cd") == 0) {
    printf("cd '%s' \\\n  && ", arg1);
  } else if (strcmp(type, "touch") == 0) {
    printf("touch '%s' \\\n  && ", arg1);
  } else if (strcmp(type, "git-clone") == 0) {
    printf("git clone '%s' '%s' \\\n  && ", arg1, arg2);
  } else if (strcmp(type, "echo") == 0) {
    // Expand tokens for echo
    Z_CLEANUP(zstr_free) zstr expanded = zstr_expand_tokens(arg1);
    printf("echo '%s' \\\n  && ", zstr_cstr(&expanded));
  }
}

void cmd_init(int argc, char **argv, const char *tries_path) {
  (void)argc;  // Unused
  (void)argv;  // Unused

  // Determine if we're in fish shell
  const char *shell = getenv("SHELL");
  bool is_fish = (shell && strstr(shell, "fish") != NULL);

  // Override tries_path if provided as argument
  const char *path_arg = "";
  if (tries_path && strlen(tries_path) > 0) {
    static char path_buf[1024];
    snprintf(path_buf, sizeof(path_buf), " --path \"%s\"", tries_path);
    path_arg = path_buf;
  }

  // Get the path to this executable
  char self_path[1024];
  ssize_t len = readlink("/proc/self/exe", self_path, sizeof(self_path) - 1);
  if (len == -1) {
    // Fallback to argv[0] or a default
    strncpy(self_path, "try", sizeof(self_path) - 1);
  } else {
    self_path[len] = '\0';
  }

  if (is_fish) {
    // Fish shell version
    printf(
      "function try\n"
      "  set -l script_path \"%s\"\n"
      "  # Check if first argument is a known command\n"
      "  switch $argv[1]\n"
      "    case clone worktree init\n"
      "      set -l cmd (/usr/bin/env \"$script_path\"%s $argv 2>/dev/tty | string collect)\n"
      "    case '*'\n"
      "      set -l cmd (/usr/bin/env \"$script_path\" cd%s $argv 2>/dev/tty | string collect)\n"
      "  end\n"
      "  set -l rc $status\n"
      "  if test $rc -eq 0\n"
      "    if string match -r ' && ' -- $cmd\n"
      "      eval $cmd\n"
      "    else\n"
      "      printf '%%s' $cmd\n"
      "    end\n"
      "  else\n"
      "    printf '%%s' $cmd\n"
      "  end\n"
      "end\n",
      self_path, path_arg, path_arg);
  } else {
    // Bash/Zsh version
    printf(
      "try() {\n"
      "  script_path='%s'\n"
      "  # Check if first argument is a known command\n"
      "  case \"$1\" in\n"
      "    clone|worktree|init)\n"
      "      cmd=$(/usr/bin/env \"$script_path\"%s \"$@\" 2>/dev/tty)\n"
      "      ;;\n"
      "    *)\n"
      "      cmd=$(/usr/bin/env \"$script_path\" cd%s \"$@\" 2>/dev/tty)\n"
      "      ;;\n"
      "  esac\n"
      "  rc=$?\n"
      "  if [ $rc -eq 0 ]; then\n"
      "    case \"$cmd\" in\n"
      "      *\" && \"*) eval \"$cmd\" ;;\n"
      "      *) printf '%%s' \"$cmd\" ;;\n"
      "    esac\n"
      "  else\n"
      "    printf '%%s' \"$cmd\"\n"
      "  fi\n"
      "}\n",
      self_path, path_arg, path_arg);
  }
}

void cmd_clone(int argc, char **argv, const char *tries_path) {
  if (argc < 1) {
    fprintf(stderr, "Usage: try clone <url> [name]\n");
    exit(1);
  }

  char *url = argv[0];
  char *name = (argc > 1) ? argv[1] : NULL;

  // Generate name if not provided
  Z_CLEANUP(zstr_free) zstr dir_name = zstr_init();

  time_t now = time(NULL);
  struct tm *t = localtime(&now);
  char date_prefix[20];
  strftime(date_prefix, sizeof(date_prefix), "%Y-%m-%d", t);
  zstr_cat(&dir_name, date_prefix);
  zstr_cat(&dir_name, "-");

  if (name) {
    zstr_cat(&dir_name, name);
  } else {
    // Extract repo name from URL
    char *last_slash = strrchr(url, '/');
    char *repo_name = last_slash ? last_slash + 1 : url;
    char *dot_git = strstr(repo_name, ".git");

    if (dot_git) {
      zstr_cat_len(&dir_name, repo_name, dot_git - repo_name);
    } else {
      zstr_cat(&dir_name, repo_name);
    }
  }

  Z_CLEANUP(zstr_free)
  zstr full_path = join_path(tries_path, zstr_cstr(&dir_name));

  emit_task("echo", "Cloning into {b}new try{/b}...", NULL);
  emit_task("mkdir", zstr_cstr(&full_path), NULL);
  emit_task("git-clone", url, zstr_cstr(&full_path));
  emit_task("touch", zstr_cstr(&full_path), NULL); // Update mtime
  emit_task("cd", zstr_cstr(&full_path), NULL);
  printf("true\n"); // End chain
}

void cmd_worktree(int argc, char **argv, const char *tries_path) {
  (void)argc;
  (void)argv;
  (void)tries_path;
  // Simplified worktree implementation
  // try worktree [dir] [name]

  // For now, just a placeholder or basic implementation
  fprintf(stderr, "Worktree command not fully implemented in this MVP.\n");
  exit(1);
}

void cmd_cd(int argc, char **argv, const char *tries_path, TestMode *test_mode) {
  // If args provided, try to find match or use as filter
  char *initial_filter = NULL;
  if (argc > 0) {
    // Join args
    // For simplicity, just take first arg
    initial_filter = argv[0];
  }

  SelectionResult result = run_selector(tries_path, initial_filter, test_mode);

  if (result.type == ACTION_CD) {
    emit_task("touch", zstr_cstr(&result.path), NULL); // Update mtime
    emit_task("cd", zstr_cstr(&result.path), NULL);
    printf("true\n");
  } else if (result.type == ACTION_MKDIR) {
    emit_task("mkdir", zstr_cstr(&result.path), NULL);
    emit_task("cd", zstr_cstr(&result.path), NULL);
    printf("true\n");
  } else {
    // Cancelled
    printf("true\n");
  }

  zstr_free(&result.path);
}
