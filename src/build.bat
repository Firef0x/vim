:: Commands to build big Vim

REM ----------------------------------------------------------------------
REM PREREQUISITES:
REM * a local clone of the Vim repository (here: ./vim)
REM   --> http://code.google.com/p/vim/source/checkout
REM * Visual Studio 2010 (Express would work)
REM * ActivePerl, ActiveTcl, Lua for Windows, Python2, and Python3.
REM   I recommend to set the paths so that you find them faster, e.g.
REM   C:\Perl_x86 and C:\Perl_x64. Remember to set the paths in all four
REM   nmake calls correctly.
REM * Starting from ActivePerl 5.18, you might have to fix Perl's config
REM   file (CORE/config.h). See here:
REM   https://groups.google.com/d/msg/vim_dev/YWnfI9wFFoA/rZdp5k1hdeAJ
REM   https://github.com/vim-jp/issues/issues/575#issuecomment-45405886
REM * Also you'll need to grab Ruby 2.x (the MSVC version, not the MinGW
REM   version). You'll probably have to compile it from scratch. This is a
REM   bit tricky. See here:
REM   https://groups.google.com/d/msg/vim_dev/P8l30hk9hyE/cG8wYjh3paMJ
REM ----------------------------------------------------------------------

@echo off

REM set library versions ...
REM ------------------------------------
set LIBPERLVER=522
set LIBPYTHON2=27
set LIBPYTHON3=36
set LIBTCLSHRT=86
set LIBTCLLONG=8.6
set LIBRBYSHRT=22
set LIBRBYLONG=2.2.0
set LIBLUAVER=51

setlocal
REM nmake -f Make_mvc.mak GUI=yes MBYTE=yes IME=yes GIME=yes COLOR_EMOJI=no CSCOPE=yes DIRECTX=yes DEBUG=no PERL=C:\Perl DYNAMIC_PERL=yes PERL_VER=%LIBPERLVER% PYTHON=C:\Python27 DYNAMIC_PYTHON=yes PYTHON_VER=%LIBPYTHON2% PYTHON3=C:\Python35 DYNAMIC_PYTHON3=yes PYTHON3_VER=%LIBPYTHON3% RUBY=C:\Ruby22 DYNAMIC_RUBY=yes RUBY_VER=%LIBRBYSHRT% RUBY_VER_LONG=%LIBRBYLONG% RUBY_MSVCRT_NAME=msvcrt LUA="D:\codes\C++\fork\luajit\src" DYNAMIC_LUA=yes LUA_VER=%LIBLUAVER% CPU=AMD64 WINVER=0x0600 XPM="D:\codes\C++\fork\vim\src\xpm\x64" USERNAME=Firef0x USERDOMAIN=github.com %*
nmake -f Make_mvc.mak GUI=yes MBYTE=yes IME=yes GIME=yes COLOR_EMOJI=no CSCOPE=yes DIRECTX=yes DEBUG=no PERL=C:\Perl DYNAMIC_PERL=yes PERL_VER=%LIBPERLVER% PYTHON=C:\Python27 DYNAMIC_PYTHON=yes PYTHON_VER=%LIBPYTHON2% PYTHON3="C:\Program Files\Python36" DYNAMIC_PYTHON3=yes PYTHON3_VER=%LIBPYTHON3% LUA="D:\codes\C++\fork\luajit\src" DYNAMIC_LUA=yes LUA_VER=%LIBLUAVER% CPU=AMD64 WINVER=0x0600 XPM="D:\codes\C++\fork\vim\src\xpm\x64" USERNAME=Firef0x USERDOMAIN=github.com %*
endlocal
