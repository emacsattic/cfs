# Process this file with autoconf to produce a configure script.

AC_INIT(cfs-el, 0.5.0, bug-cfs-el@gnu.org)
AM_INIT_AUTOMAKE(cfs-el, 0.5.0)

AC_PATH_PROG([CATTACH], [cattach], [not_found], [$PATH])
if test $CATTACH = not_found ; then
  AC_MSG_ERROR([Cannot find needed program cattach; exiting.], [1])
fi

AC_PATH_PROG([CDETACH], [cdetach], [not_found], [$PATH])
if test $CDETACH = not_found ; then
  AC_MSG_ERROR([Cannot find needed program cdetach; exiting.], [1])
fi

AC_PATH_PROG([CMKDIR], [cmkdir], [not_found], [$PATH])
if test $CMKDIR = not_found ; then
  AC_MSG_ERROR([Cannot find needed program cmkdir; exiting.], [1])
fi

AM_PATH_LISPDIR

AC_CONFIG_FILES([Makefile src/Makefile doc/Makefile doc/version.texinfo])
AC_OUTPUT
