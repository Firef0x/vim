:: command to build big Vim with Python and Lua
@echo off
setlocal
nmake -f Make_mvc.mak GUI=yes MBYTE=yes IME=yes GIME=yes CSCOPE=yes DEBUG=no PYTHON=C:\Python27 DYNAMIC_PYTHON=yes PYTHON_VER=27 PYTHON3=C:\Python34 DYNAMIC_PYTHON=yes PYTHON3_VER=34 LUA="D:\codes\C++\lib\lua\src" DYNAMIC_LUA=yes LUA_VER=52 CPUNR=i686 WINVER=0x0500 XPM="D:\codes\C++\fork\vim\src\xpm\x86" USERNAME=F USERDOMAIN=F %*
endlocal
