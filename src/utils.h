#ifndef UTILS_H
#define UTILS_H

#include "zstr.h"
#include "zvec.h"
#include "tokens.h"
#include <stdbool.h>
#include <stdlib.h>
#include <time.h>

// Generate common vector types
Z_VEC_GENERATE_IMPL(zstr, zstr)
Z_VEC_GENERATE_IMPL(char *, char_ptr)

// ANSI Colors (legacy defines, prefer using tokens instead)
#define ANSI_RESET "\033[0m"
#define ANSI_BOLD "\033[1m"
#define ANSI_DIM "\033[2m"
#define ANSI_RED "\033[31m"
#define ANSI_GREEN "\033[32m"
#define ANSI_YELLOW "\033[33m"
#define ANSI_BLUE "\033[34m"
#define ANSI_MAGENTA "\033[35m"
#define ANSI_CYAN "\033[36m"
#define ANSI_WHITE "\033[37m"

// Defer helper for standard pointers (zstr has Z_CLEANUP(zstr_free))
static inline void cleanup_free(void *p) { free(*(void **)p); }
#define AUTO_FREE Z_CLEANUP(cleanup_free)

// String helpers
char *trim(char *str); // Operates in-place
zstr join_path(const char *dir, const char *file);
zstr get_home_dir(void);
zstr get_default_tries_path(void);

// File helpers
bool dir_exists(const char *path);
bool file_exists(const char *path);
int mkdir_p(const char *path);
zstr format_relative_time(time_t mtime);

// Directory name validation
// Returns normalized name (spaces -> hyphens, collapse multiples, strip edges)
// Returns empty string if name contains invalid characters
// Valid chars: [a-zA-Z0-9_.-]
zstr normalize_dir_name(const char *name);

// Check if name contains only valid directory name characters
bool is_valid_dir_name(const char *name);

#endif // UTILS_H
