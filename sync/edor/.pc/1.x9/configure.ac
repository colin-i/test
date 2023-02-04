#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.
AC_PREREQ([2.69])

AC_INIT([edor], [0.1])
#AC_SUBST([PROJ], 'edor')

AC_CONFIG_SRCDIR([s/main.c])

AC_CONFIG_AUX_DIR([build-aux])
# compile with -x c++
AC_ARG_ENABLE(cpp,
  AS_HELP_STRING([--enable-cpp],[enable cpp, default: yes]),
  [case "${enableval}" in yes) cpp=true ;; no) cpp=false ;; *) AC_MSG_ERROR([bad value ${enableval} for --enable-cpp]) ;; esac],
  [cpp=true])
AM_CONDITIONAL(CPP, test x"$cpp" = x"true")

# Checks for programs.
AC_PROG_CC

# Checks for header files. Checks for libraries.

AC_CHECK_HEADERS(dirent.h errno.h fcntl.h poll.h stdio.h stdlib.h string.h unistd.h)
AC_CHECK_HEADERS(curses.h, [AC_SUBST(CSS, "")], [AC_SUBST(CSS, "-Wno-padded")])
AC_SUBST(UNW, "")

#arm32 unwind
AC_CANONICAL_BUILD
AC_MSG_CHECKING([build_cpu])
AC_MSG_RESULT([$build_cpu])
AC_MSG_CHECKING([armhf])
AS_IF([ [[ "$build_cpu" = "arm" ]] || [[ "$build_cpu" = "armv7l" ]] ],
  [
  AC_MSG_RESULT([yes])
  AC_DEFINE(ARM7L, 1, [armv7l])
  AC_CHECK_HEADERS(dlfcn.h signal.h)
  AC_CHECK_HEADERS(libunwind.h, [], [AC_SUBST(UNW, "-Wno-c++98-compat-pedantic")])
#not all platforms need these
  AC_SEARCH_LIBS([dladdr],[dl])
  AC_SEARCH_LIBS([_Uarm_init_local],[unwind-arm])
  ],
  [AC_MSG_RESULT([no])]
)

# Checks for typedefs, structures, and compiler characteristics.

start_cflgs="$CFLAGS"
CFLAGS="-Werror=unknown-warning-option -Weverything"
AC_MSG_CHECKING([-Weverything])
AC_COMPILE_IFELSE(
   [AC_LANG_SOURCE([])],
   [AC_MSG_RESULT([yes])
	start_cflgs="$start_cflgs -Weverything -Werror"],
   [AC_MSG_RESULT([no])]
)
CFLAGS="$start_cflgs"

AS_IF([test x"$cpp" = x"true"],[
AC_LANG([C++])
AC_MSG_CHECKING([for std::filesystem::preferred_separator])
AC_COMPILE_IFELSE([AC_LANG_SOURCE([[
#include <filesystem>
char a=std::filesystem::path::preferred_separator;
]])],
  [
    AC_DEFINE(USE_FS, 1, [use filesystem])
    AC_MSG_RESULT(yes)
  ],
[
	AC_MSG_RESULT(no)
	AC_MSG_CHECKING([for std::__fs::filesystem::preferred_separator])
	AC_COMPILE_IFELSE([AC_LANG_SOURCE([[
	#include <filesystem>
	char a=std::__fs::filesystem::path::preferred_separator;
	]])],
	  [
	  AC_DEFINE(USE__FS, 1, [use __fs])
	  AC_MSG_RESULT(yes)
	  ],
	[
	  AC_MSG_RESULT(no)
	])
])
],[
AC_CHECK_HEADERS(stdbool.h stddef.h)
])

AC_RUN_IFELSE([AC_LANG_SOURCE([
int main(){
return sizeof(long)==sizeof(int);//0 is true for ac_run
}
])], [AC_DEFINE(PLATFORM64, 1, "64")], [])

# Checks for library functions.

AM_INIT_AUTOMAKE

AC_CONFIG_FILES([Makefile s/Makefile])

AC_OUTPUT

#echo -n >"./.${PROJ}info"
#echo ~>./bash_home
