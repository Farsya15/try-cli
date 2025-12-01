#ifndef CONFIG_H
#define CONFIG_H

// TRY_VERSION is passed via -D flag from Makefile (reads VERSION file)
#ifndef TRY_VERSION
#define TRY_VERSION "dev"
#endif

#define DEFAULT_TRIES_PATH_SUFFIX "src/tries" // Relative to HOME

#endif // CONFIG_H
