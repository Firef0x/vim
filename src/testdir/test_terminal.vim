" Tests for the terminal window.

if !has('terminal')
  finish
endif

source shared.vim
source screendump.vim

let s:python = PythonProg()

" Open a terminal with a shell, assign the job to g:job and return the buffer
" number.
func Run_shell_in_terminal(options)
  if has('win32')
    let buf = term_start([&shell,'/k'], a:options)
  else
    let buf = term_start(&shell, a:options)
  endif

  let termlist = term_list()
  call assert_equal(1, len(termlist))
  call assert_equal(buf, termlist[0])

  let g:job = term_getjob(buf)
  call assert_equal(v:t_job, type(g:job))

  let string = string({'job': term_getjob(buf)})
  call assert_match("{'job': 'process \\d\\+ run'}", string)

  return buf
endfunc

func Test_terminal_basic()
  au BufWinEnter * if &buftype == 'terminal' | let b:done = 'yes' | endif
  let buf = Run_shell_in_terminal({})

  if has("unix")
    call assert_match('^/dev/', job_info(g:job).tty_out)
    call assert_match('^/dev/', term_gettty(''))
  else
    call assert_match('^\\\\.\\pipe\\', job_info(g:job).tty_out)
    call assert_match('^\\\\.\\pipe\\', term_gettty(''))
  endif
  call assert_equal('t', mode())
  call assert_equal('yes', b:done)
  call assert_match('%aR[^\n]*running]', execute('ls'))
  call assert_match('%aR[^\n]*running]', execute('ls R'))
  call assert_notmatch('%[^\n]*running]', execute('ls F'))
  call assert_notmatch('%[^\n]*running]', execute('ls ?'))

  call Stop_shell_in_terminal(buf)
  call term_wait(buf)
  call assert_equal('n', mode())
  call assert_match('%aF[^\n]*finished]', execute('ls'))
  call assert_match('%aF[^\n]*finished]', execute('ls F'))
  call assert_notmatch('%[^\n]*finished]', execute('ls R'))
  call assert_notmatch('%[^\n]*finished]', execute('ls ?'))

  " closing window wipes out the terminal buffer a with finished job
  close
  call assert_equal("", bufname(buf))

  au! BufWinEnter
  unlet g:job
endfunc

func Test_terminal_make_change()
  let buf = Run_shell_in_terminal({})
  call Stop_shell_in_terminal(buf)
  call term_wait(buf)

  setlocal modifiable
  exe "normal Axxx\<Esc>"
  call assert_fails(buf . 'bwipe', 'E517')
  undo

  exe buf . 'bwipe'
  unlet g:job
endfunc

func Test_terminal_wipe_buffer()
  let buf = Run_shell_in_terminal({})
  call assert_fails(buf . 'bwipe', 'E517')
  exe buf . 'bwipe!'
  call WaitFor('job_status(g:job) == "dead"')
  call assert_equal('dead', job_status(g:job))
  call assert_equal("", bufname(buf))

  unlet g:job
endfunc

func Test_terminal_split_quit()
  let buf = Run_shell_in_terminal({})
  call term_wait(buf)
  split
  quit!
  call term_wait(buf)
  sleep 50m
  call assert_equal('run', job_status(g:job))

  quit!
  call WaitFor('job_status(g:job) == "dead"')
  call assert_equal('dead', job_status(g:job))

  exe buf . 'bwipe'
  unlet g:job
endfunc

func Test_terminal_hide_buffer()
  let buf = Run_shell_in_terminal({})
  setlocal bufhidden=hide
  quit
  for nr in range(1, winnr('$'))
    call assert_notequal(winbufnr(nr), buf)
  endfor
  call assert_true(bufloaded(buf))
  call assert_true(buflisted(buf))

  exe 'split ' . buf . 'buf'
  call Stop_shell_in_terminal(buf)
  exe buf . 'bwipe'

  unlet g:job
endfunc

func! s:Nasty_exit_cb(job, st)
  exe g:buf . 'bwipe!'
  let g:buf = 0
endfunc

func Get_cat_123_cmd()
  if has('win32')
    return 'cmd /c "cls && color 2 && echo 123"'
  else
    call writefile(["\<Esc>[32m123"], 'Xtext')
    return "cat Xtext"
  endif
endfunc

func Test_terminal_nasty_cb()
  let cmd = Get_cat_123_cmd()
  let g:buf = term_start(cmd, {'exit_cb': function('s:Nasty_exit_cb')})
  let g:job = term_getjob(g:buf)

  call WaitFor('job_status(g:job) == "dead"')
  call WaitFor('g:buf == 0')
  unlet g:buf
  unlet g:job
  call delete('Xtext')
endfunc

func Check_123(buf)
  let l = term_scrape(a:buf, 0)
  call assert_true(len(l) == 0)
  let l = term_scrape(a:buf, 999)
  call assert_true(len(l) == 0)
  let l = term_scrape(a:buf, 1)
  call assert_true(len(l) > 0)
  call assert_equal('1', l[0].chars)
  call assert_equal('2', l[1].chars)
  call assert_equal('3', l[2].chars)
  call assert_equal('#00e000', l[0].fg)
  if &background == 'light'
    call assert_equal('#ffffff', l[0].bg)
  else
    call assert_equal('#000000', l[0].bg)
  endif

  let l = term_getline(a:buf, -1)
  call assert_equal('', l)
  let l = term_getline(a:buf, 0)
  call assert_equal('', l)
  let l = term_getline(a:buf, 999)
  call assert_equal('', l)
  let l = term_getline(a:buf, 1)
  call assert_equal('123', l)
endfunc

func Test_terminal_scrape_123()
  let cmd = Get_cat_123_cmd()
  let buf = term_start(cmd)

  let termlist = term_list()
  call assert_equal(1, len(termlist))
  call assert_equal(buf, termlist[0])

  " Nothing happens with invalid buffer number
  call term_wait(1234)

  call term_wait(buf)
  " On MS-Windows we first get a startup message of two lines, wait for the
  " "cls" to happen, after that we have one line with three characters.
  call WaitFor({-> len(term_scrape(buf, 1)) == 3})
  call Check_123(buf)

  " Must still work after the job ended.
  let job = term_getjob(buf)
  call WaitFor({-> job_status(job) == "dead"})
  call term_wait(buf)
  call Check_123(buf)

  exe buf . 'bwipe'
  call delete('Xtext')
endfunc

func Test_terminal_scrape_multibyte()
  if !has('multi_byte')
    return
  endif
  call writefile(["léttまrs"], 'Xtext')
  if has('win32')
    " Run cmd with UTF-8 codepage to make the type command print the expected
    " multibyte characters.
    let buf = term_start("cmd /K chcp 65001")
    call term_sendkeys(buf, "type Xtext\<CR>")
    call term_sendkeys(buf, "exit\<CR>")
    let line = 4
  else
    let buf = term_start("cat Xtext")
    let line = 1
  endif

  call WaitFor({-> len(term_scrape(buf, line)) >= 7 && term_scrape(buf, line)[0].chars == "l"})
  let l = term_scrape(buf, line)
  call assert_true(len(l) >= 7)
  call assert_equal('l', l[0].chars)
  call assert_equal('é', l[1].chars)
  call assert_equal(1, l[1].width)
  call assert_equal('t', l[2].chars)
  call assert_equal('t', l[3].chars)
  call assert_equal('ま', l[4].chars)
  call assert_equal(2, l[4].width)
  call assert_equal('r', l[5].chars)
  call assert_equal('s', l[6].chars)

  let job = term_getjob(buf)
  call WaitFor({-> job_status(job) == "dead"})
  call term_wait(buf)

  exe buf . 'bwipe'
  call delete('Xtext')
endfunc

func Test_terminal_scroll()
  call writefile(range(1, 200), 'Xtext')
  if has('win32')
    let cmd = 'cmd /c "type Xtext"'
  else
    let cmd = "cat Xtext"
  endif
  let buf = term_start(cmd)

  let job = term_getjob(buf)
  call WaitFor({-> job_status(job) == "dead"})
  call term_wait(buf)
  if has('win32')
    " TODO: this should not be needed
    sleep 100m
  endif

  let scrolled = term_getscrolled(buf)
  call assert_equal('1', getline(1))
  call assert_equal('1', term_getline(buf, 1 - scrolled))
  call assert_equal('49', getline(49))
  call assert_equal('49', term_getline(buf, 49 - scrolled))
  call assert_equal('200', getline(200))
  call assert_equal('200', term_getline(buf, 200 - scrolled))

  exe buf . 'bwipe'
  call delete('Xtext')
endfunc

func Test_terminal_scrollback()
  let buf = Run_shell_in_terminal({})
  set termwinscroll=100
  call writefile(range(150), 'Xtext')
  if has('win32')
    call term_sendkeys(buf, "type Xtext\<CR>")
  else
    call term_sendkeys(buf, "cat Xtext\<CR>")
  endif
  let rows = term_getsize(buf)[0]
  " On MS-Windows there is an empty line, check both last line and above it.
  call WaitFor({-> term_getline(buf, rows - 1) . term_getline(buf, rows - 2) =~ '149'})
  let lines = line('$')
  call assert_inrange(91, 100, lines)

  call Stop_shell_in_terminal(buf)
  call term_wait(buf)
  exe buf . 'bwipe'
  set termwinscroll&
endfunc

func Test_terminal_size()
  let cmd = Get_cat_123_cmd()

  exe 'terminal ++rows=5 ' . cmd
  let size = term_getsize('')
  bwipe!
  call assert_equal(5, size[0])

  call term_start(cmd, {'term_rows': 6})
  let size = term_getsize('')
  bwipe!
  call assert_equal(6, size[0])

  vsplit
  exe 'terminal ++rows=5 ++cols=33 ' . cmd
  call assert_equal([5, 33], term_getsize(''))

  call term_setsize('', 6, 0)
  call assert_equal([6, 33], term_getsize(''))

  call term_setsize('', 0, 35)
  call assert_equal([6, 35], term_getsize(''))

  call term_setsize('', 7, 30)
  call assert_equal([7, 30], term_getsize(''))

  bwipe!
  call assert_fails("call term_setsize('', 7, 30)", "E955:")

  call term_start(cmd, {'term_rows': 6, 'term_cols': 36})
  let size = term_getsize('')
  bwipe!
  call assert_equal([6, 36], size)

  exe 'vertical terminal ++cols=20 ' . cmd
  let size = term_getsize('')
  bwipe!
  call assert_equal(20, size[1])

  call term_start(cmd, {'vertical': 1, 'term_cols': 26})
  let size = term_getsize('')
  bwipe!
  call assert_equal(26, size[1])

  split
  exe 'vertical terminal ++rows=6 ++cols=20 ' . cmd
  let size = term_getsize('')
  bwipe!
  call assert_equal([6, 20], size)

  call term_start(cmd, {'vertical': 1, 'term_rows': 7, 'term_cols': 27})
  let size = term_getsize('')
  bwipe!
  call assert_equal([7, 27], size)

  call delete('Xtext')
endfunc

func Test_terminal_curwin()
  let cmd = Get_cat_123_cmd()
  call assert_equal(1, winnr('$'))

  split dummy
  exe 'terminal ++curwin ' . cmd
  call assert_equal(2, winnr('$'))
  bwipe!

  split dummy
  call term_start(cmd, {'curwin': 1})
  call assert_equal(2, winnr('$'))
  bwipe!

  split dummy
  call setline(1, 'change')
  call assert_fails('terminal ++curwin ' . cmd, 'E37:')
  call assert_equal(2, winnr('$'))
  exe 'terminal! ++curwin ' . cmd
  call assert_equal(2, winnr('$'))
  bwipe!

  split dummy
  call setline(1, 'change')
  call assert_fails("call term_start(cmd, {'curwin': 1})", 'E37:')
  call assert_equal(2, winnr('$'))
  bwipe!

  split dummy
  bwipe!
  call delete('Xtext')
endfunc

func s:get_sleep_cmd()
  if s:python != ''
    let cmd = s:python . " test_short_sleep.py"
    let waittime = 500
  else
    echo 'This will take five seconds...'
    let waittime = 2000
    if has('win32')
      let cmd = $windir . '\system32\timeout.exe 1'
    else
      let cmd = 'sleep 1'
    endif
  endif
  return [cmd, waittime]
endfunc

func Test_terminal_finish_open_close()
  call assert_equal(1, winnr('$'))

  let [cmd, waittime] = s:get_sleep_cmd()

  " shell terminal closes automatically
  terminal
  let buf = bufnr('%')
  call assert_equal(2, winnr('$'))
  " Wait for the shell to display a prompt
  call WaitFor({-> term_getline(buf, 1) != ""})
  call Stop_shell_in_terminal(buf)
  call WaitFor("winnr('$') == 1", waittime)

  " shell terminal that does not close automatically
  terminal ++noclose
  let buf = bufnr('%')
  call assert_equal(2, winnr('$'))
  " Wait for the shell to display a prompt
  call WaitFor({-> term_getline(buf, 1) != ""})
  call Stop_shell_in_terminal(buf)
  call assert_equal(2, winnr('$'))
  quit
  call assert_equal(1, winnr('$'))

  exe 'terminal ++close ' . cmd
  call assert_equal(2, winnr('$'))
  wincmd p
  call WaitFor("winnr('$') == 1", waittime)

  call term_start(cmd, {'term_finish': 'close'})
  call assert_equal(2, winnr('$'))
  wincmd p
  call WaitFor("winnr('$') == 1", waittime)
  call assert_equal(1, winnr('$'))

  exe 'terminal ++open ' . cmd
  close!
  call WaitFor("winnr('$') == 2", waittime)
  call assert_equal(2, winnr('$'))
  bwipe

  call term_start(cmd, {'term_finish': 'open'})
  close!
  call WaitFor("winnr('$') == 2", waittime)
  call assert_equal(2, winnr('$'))
  bwipe

  exe 'terminal ++hidden ++open ' . cmd
  call assert_equal(1, winnr('$'))
  call WaitFor("winnr('$') == 2", waittime)
  call assert_equal(2, winnr('$'))
  bwipe

  call term_start(cmd, {'term_finish': 'open', 'hidden': 1})
  call assert_equal(1, winnr('$'))
  call WaitFor("winnr('$') == 2", waittime)
  call assert_equal(2, winnr('$'))
  bwipe

  call assert_fails("call term_start(cmd, {'term_opencmd': 'open'})", 'E475:')
  call assert_fails("call term_start(cmd, {'term_opencmd': 'split %x'})", 'E475:')
  call assert_fails("call term_start(cmd, {'term_opencmd': 'split %d and %s'})", 'E475:')
  call assert_fails("call term_start(cmd, {'term_opencmd': 'split % and %d'})", 'E475:')

  call term_start(cmd, {'term_finish': 'open', 'term_opencmd': '4split | buffer %d'})
  close!
  call WaitFor("winnr('$') == 2", waittime)
  call assert_equal(2, winnr('$'))
  call assert_equal(4, winheight(0))
  bwipe
endfunc

func Test_terminal_cwd()
  if !executable('pwd')
    return
  endif
  call mkdir('Xdir')
  let buf = term_start('pwd', {'cwd': 'Xdir'})
  call WaitFor('"Xdir" == fnamemodify(getline(1), ":t")')
  call assert_equal('Xdir', fnamemodify(getline(1), ":t"))

  exe buf . 'bwipe'
  call delete('Xdir', 'rf')
endfunc

func Test_terminal_servername()
  if !has('clientserver')
    return
  endif
  let buf = Run_shell_in_terminal({})
  " Wait for the shell to display a prompt
  call WaitFor({-> term_getline(buf, 1) != ""})
  if has('win32')
    call term_sendkeys(buf, "echo %VIM_SERVERNAME%\r")
  else
    call term_sendkeys(buf, "echo $VIM_SERVERNAME\r")
  endif
  call term_wait(buf)
  call Stop_shell_in_terminal(buf)
  call WaitFor('getline(2) == v:servername')
  call assert_equal(v:servername, getline(2))

  exe buf . 'bwipe'
  unlet buf
endfunc

func Test_terminal_env()
  let buf = Run_shell_in_terminal({'env': {'TESTENV': 'correct'}})
  " Wait for the shell to display a prompt
  call WaitFor({-> term_getline(buf, 1) != ""})
  if has('win32')
    call term_sendkeys(buf, "echo %TESTENV%\r")
  else
    call term_sendkeys(buf, "echo $TESTENV\r")
  endif
  call term_wait(buf)
  call Stop_shell_in_terminal(buf)
  call WaitFor('getline(2) == "correct"')
  call assert_equal('correct', getline(2))

  exe buf . 'bwipe'
endfunc

" must be last, we can't go back from GUI to terminal
func Test_zz_terminal_in_gui()
  if !CanRunGui()
    return
  endif

  " Ignore the "failed to create input context" error.
  call test_ignore_error('E285:')

  gui -f

  call assert_equal(1, winnr('$'))
  let buf = Run_shell_in_terminal({'term_finish': 'close'})
  call Stop_shell_in_terminal(buf)
  call term_wait(buf)

  " closing window wipes out the terminal buffer a with finished job
  call WaitFor("winnr('$') == 1")
  call assert_equal(1, winnr('$'))
  call assert_equal("", bufname(buf))

  unlet g:job
endfunc

func Test_terminal_list_args()
  let buf = term_start([&shell, &shellcmdflag, 'echo "123"'])
  call assert_fails(buf . 'bwipe', 'E517')
  exe buf . 'bwipe!'
  call assert_equal("", bufname(buf))
endfunction

func Test_terminal_noblock()
  let buf = term_start(&shell)
  if has('mac')
    " The shell or something else has a problem dealing with more than 1000
    " characters at the same time.
    let len = 1000
  else
    let len = 5000
  endif

  for c in ['a','b','c','d','e','f','g','h','i','j','k']
    call term_sendkeys(buf, 'echo ' . repeat(c, len) . "\<cr>")
  endfor
  call term_sendkeys(buf, "echo done\<cr>")

  " On MS-Windows there is an extra empty line below "done".  Find "done" in
  " the last-but-one or the last-but-two line.
  let lnum = term_getsize(buf)[0] - 1
  call WaitFor({-> term_getline(buf, lnum) =~ "done" || term_getline(buf, lnum - 1) =~ "done"}, 10000)
  let line = term_getline(buf, lnum)
  if line !~ 'done'
    let line = term_getline(buf, lnum - 1)
  endif
  call assert_match('done', line)

  let g:job = term_getjob(buf)
  call Stop_shell_in_terminal(buf)
  call term_wait(buf)
  unlet g:job
  bwipe
endfunc

func Test_terminal_write_stdin()
  if !executable('wc')
    throw 'skipped: wc command not available'
  endif
  new
  call setline(1, ['one', 'two', 'three'])
  %term wc
  call WaitFor('getline("$") =~ "3"')
  let nrs = split(getline('$'))
  call assert_equal(['3', '3', '14'], nrs)
  bwipe

  new
  call setline(1, ['one', 'two', 'three', 'four'])
  2,3term wc
  call WaitFor('getline("$") =~ "2"')
  let nrs = split(getline('$'))
  call assert_equal(['2', '2', '10'], nrs)
  bwipe

  if executable('python')
    new
    call setline(1, ['print("hello")'])
    1term ++eof=exit() python
    " MS-Windows echoes the input, Unix doesn't.
    call WaitFor('getline("$") =~ "exit" || getline(1) =~ "hello"')
    if getline(1) =~ 'hello'
      call assert_equal('hello', getline(1))
    else
      call assert_equal('hello', getline(line('$') - 1))
    endif
    bwipe

    if has('win32')
      new
      call setline(1, ['print("hello")'])
      1term ++eof=<C-Z> python
      call WaitFor('getline("$") =~ "Z"')
      call assert_equal('hello', getline(line('$') - 1))
      bwipe
    endif
  endif

  bwipe!
endfunc

func Test_terminal_no_cmd()
  " Todo: make this work in the GUI
  if !has('gui_running')
    return
  endif
  let buf = term_start('NONE', {})
  call assert_notequal(0, buf)

  let pty = job_info(term_getjob(buf))['tty_out']
  call assert_notequal('', pty)
  if has('win32')
    silent exe '!start cmd /c "echo look here > ' . pty . '"'
  else
    call system('echo "look here" > ' . pty)
  endif
  call WaitFor({-> term_getline(buf, 1) =~ "look here"})

  call assert_match('look here', term_getline(buf, 1))
  bwipe!
endfunc

func Test_terminal_special_chars()
  " this file name only works on Unix
  if !has('unix')
    return
  endif
  call mkdir('Xdir with spaces')
  call writefile(['x'], 'Xdir with spaces/quoted"file')
  term ls Xdir\ with\ spaces/quoted\"file
  call WaitFor('term_getline("", 1) =~ "quoted"')
  call assert_match('quoted"file', term_getline('', 1))
  call term_wait('')

  call delete('Xdir with spaces', 'rf')
  bwipe
endfunc

func Test_terminal_wrong_options()
  call assert_fails('call term_start(&shell, {
	\ "in_io": "file",
	\ "in_name": "xxx",
	\ "out_io": "file",
	\ "out_name": "xxx",
	\ "err_io": "file",
	\ "err_name": "xxx"
	\ })', 'E474:')
  call assert_fails('call term_start(&shell, {
	\ "out_buf": bufnr("%")
	\ })', 'E474:')
  call assert_fails('call term_start(&shell, {
	\ "err_buf": bufnr("%")
	\ })', 'E474:')
endfunc

func Test_terminal_redir_file()
  " TODO: this should work on MS-Window
  if has('unix')
    let cmd = Get_cat_123_cmd()
    let buf = term_start(cmd, {'out_io': 'file', 'out_name': 'Xfile'})
    call term_wait(buf)
    call WaitFor('len(readfile("Xfile")) > 0')
    call assert_match('123', readfile('Xfile')[0])
    let g:job = term_getjob(buf)
    call WaitFor('job_status(g:job) == "dead"')
    call delete('Xfile')
    bwipe
  endif

  if has('unix')
    call writefile(['one line'], 'Xfile')
    let buf = term_start('cat', {'in_io': 'file', 'in_name': 'Xfile'})
    call term_wait(buf)
    call WaitFor('term_getline(' . buf . ', 1) == "one line"')
    call assert_equal('one line', term_getline(buf, 1))
    let g:job = term_getjob(buf)
    call WaitFor('job_status(g:job) == "dead"')
    bwipe
    call delete('Xfile')
  endif
endfunc

func TerminalTmap(remap)
  let buf = Run_shell_in_terminal({})
  call assert_equal('t', mode())

  if a:remap
    tmap 123 456
  else
    tnoremap 123 456
  endif
  " don't use abcde, it's an existing command
  tmap 456 abxde
  call assert_equal('456', maparg('123', 't'))
  call assert_equal('abxde', maparg('456', 't'))
  call feedkeys("123", 'tx')
  call WaitFor({-> term_getline(buf, term_getcursor(buf)[0]) =~ 'abxde\|456'})
  let lnum = term_getcursor(buf)[0]
  if a:remap
    call assert_match('abxde', term_getline(buf, lnum))
  else
    call assert_match('456', term_getline(buf, lnum))
  endif

  call term_sendkeys(buf, "\r")
  call Stop_shell_in_terminal(buf)
  call term_wait(buf)

  tunmap 123
  tunmap 456
  call assert_equal('', maparg('123', 't'))
  close
  unlet g:job
endfunc

func Test_terminal_tmap()
  call TerminalTmap(1)
  call TerminalTmap(0)
endfunc

func Test_terminal_wall()
  let buf = Run_shell_in_terminal({})
  wall
  call Stop_shell_in_terminal(buf)
  call term_wait(buf)
  exe buf . 'bwipe'
  unlet g:job
endfunc

func Test_terminal_wqall()
  let buf = Run_shell_in_terminal({})
  call assert_fails('wqall', 'E948')
  call Stop_shell_in_terminal(buf)
  call term_wait(buf)
  exe buf . 'bwipe'
  unlet g:job
endfunc

func Test_terminal_composing_unicode()
  let save_enc = &encoding
  set encoding=utf-8

  if has('win32')
    let cmd = "cmd /K chcp 65001"
    let lnum = [3, 6, 9]
  else
    let cmd = &shell
    let lnum = [1, 3, 5]
  endif

  enew
  let buf = term_start(cmd, {'curwin': bufnr('')})
  let g:job = term_getjob(buf)
  call term_wait(buf, 50)

  " ascii + composing
  let txt = "a\u0308bc"
  call term_sendkeys(buf, "echo " . txt . "\r")
  call term_wait(buf, 50)
  call assert_match("echo " . txt, term_getline(buf, lnum[0]))
  call assert_equal(txt, term_getline(buf, lnum[0] + 1))
  let l = term_scrape(buf, lnum[0] + 1)
  call assert_equal("a\u0308", l[0].chars)
  call assert_equal("b", l[1].chars)
  call assert_equal("c", l[2].chars)

  " multibyte + composing
  let txt = "\u304b\u3099\u304e\u304f\u3099\u3052\u3053\u3099"
  call term_sendkeys(buf, "echo " . txt . "\r")
  call term_wait(buf, 50)
  call assert_match("echo " . txt, term_getline(buf, lnum[1]))
  call assert_equal(txt, term_getline(buf, lnum[1] + 1))
  let l = term_scrape(buf, lnum[1] + 1)
  call assert_equal("\u304b\u3099", l[0].chars)
  call assert_equal("\u304e", l[1].chars)
  call assert_equal("\u304f\u3099", l[2].chars)
  call assert_equal("\u3052", l[3].chars)
  call assert_equal("\u3053\u3099", l[4].chars)

  " \u00a0 + composing
  let txt = "abc\u00a0\u0308"
  call term_sendkeys(buf, "echo " . txt . "\r")
  call term_wait(buf, 50)
  call assert_match("echo " . txt, term_getline(buf, lnum[2]))
  call assert_equal(txt, term_getline(buf, lnum[2] + 1))
  let l = term_scrape(buf, lnum[2] + 1)
  call assert_equal("\u00a0\u0308", l[3].chars)

  call term_sendkeys(buf, "exit\r")
  call WaitFor('job_status(g:job) == "dead"')
  call assert_equal('dead', job_status(g:job))
  bwipe!
  unlet g:job
  let &encoding = save_enc
endfunc

func Test_terminal_aucmd_on_close()
  fun Nop()
    let s:called = 1
  endfun

  aug repro
      au!
      au BufWinLeave * call Nop()
  aug END

  let [cmd, waittime] = s:get_sleep_cmd()

  call assert_equal(1, winnr('$'))
  new
  call setline(1, ['one', 'two'])
  exe 'term ++close ' . cmd
  wincmd p
  call WaitFor("winnr('$') == 2", waittime)
  call assert_equal(1, s:called)
  bwipe!

  unlet s:called
  au! repro
  delfunc Nop
endfunc

func Test_terminal_term_start_empty_command()
  let cmd = "call term_start('', {'curwin' : 1, 'term_finish' : 'close'})"
  call assert_fails(cmd, 'E474')
  let cmd = "call term_start('', {'curwin' : 1, 'term_finish' : 'close'})"
  call assert_fails(cmd, 'E474')
  let cmd = "call term_start({}, {'curwin' : 1, 'term_finish' : 'close'})"
  call assert_fails(cmd, 'E474')
  let cmd = "call term_start(0, {'curwin' : 1, 'term_finish' : 'close'})"
  call assert_fails(cmd, 'E474')
endfunc

func Test_terminal_response_to_control_sequence()
  if !has('unix')
    return
  endif

  let buf = Run_shell_in_terminal({})
  call WaitFor({-> term_getline(buf, 1) != ''})

  call term_sendkeys(buf, "cat\<CR>")
  call WaitFor({-> term_getline(buf, 1) =~ 'cat'})

  " Request the cursor position.
  call term_sendkeys(buf, "\x1b[6n\<CR>")

  " Wait for output from tty to display, below an empty line.
  call WaitFor({-> term_getline(buf, 4) =~ '3;1R'})

  " End "cat" gently.
  call term_sendkeys(buf, "\<CR>\<C-D>")

  call Stop_shell_in_terminal(buf)
  exe buf . 'bwipe'
  unlet g:job
endfunc

" Run Vim, start a terminal in that Vim with the kill argument,
" :qall works.
func Run_terminal_qall_kill(line1, line2)
  " 1. Open a terminal window and wait for the prompt to appear
  " 2. set kill using term_setkill()
  " 3. make Vim exit, it will kill the shell
  let after = [
	\ a:line1,
	\ 'let buf = bufnr("%")',
	\ 'while term_getline(buf, 1) =~ "^\\s*$"',
	\ '  sleep 10m',
	\ 'endwhile',
	\ a:line2,
	\ 'au VimLeavePre * call writefile(["done"], "Xdone")',
	\ 'qall',
	\ ]
  if !RunVim([], after, '')
    return
  endif
  call assert_equal("done", readfile("Xdone")[0])
  call delete("Xdone")
endfunc

" Run Vim in a terminal, then start a terminal in that Vim with a kill
" argument, check that :qall works.
func Test_terminal_qall_kill_arg()
  call Run_terminal_qall_kill('term ++kill=kill', '')
endfunc

" Run Vim, start a terminal in that Vim, set the kill argument with
" term_setkill(), check that :qall works.
func Test_terminal_qall_kill_func()
  call Run_terminal_qall_kill('term', 'call term_setkill(buf, "kill")')
endfunc

" Run Vim, start a terminal in that Vim without the kill argument,
" check that :qall does not exit, :qall! does.
func Test_terminal_qall_exit()
  let after = [
	\ 'term',
	\ 'let buf = bufnr("%")',
	\ 'while term_getline(buf, 1) =~ "^\\s*$"',
	\ '  sleep 10m',
	\ 'endwhile',
	\ 'set nomore',
	\ 'au VimLeavePre * call writefile(["too early"], "Xdone")',
	\ 'qall',
	\ 'au! VimLeavePre * exe buf . "bwipe!" | call writefile(["done"], "Xdone")',
	\ 'cquit',
	\ ]
  if !RunVim([], after, '')
    return
  endif
  call assert_equal("done", readfile("Xdone")[0])
  call delete("Xdone")
endfunc

" Run Vim in a terminal, then start a terminal in that Vim without a kill
" argument, check that :confirm qall works.
func Test_terminal_qall_prompt()
  if !CanRunVimInTerminal()
    return
  endif
  let buf = RunVimInTerminal('', {})

  " Open a terminal window and wait for the prompt to appear
  call term_sendkeys(buf, ":term\<CR>")
  call WaitFor({-> term_getline(buf, 10) =~ '\[running]'})
  call WaitFor({-> term_getline(buf, 1) !~ '^\s*$'})

  " make Vim exit, it will prompt to kill the shell
  call term_sendkeys(buf, "\<C-W>:confirm qall\<CR>")
  call WaitFor({-> term_getline(buf, 20) =~ 'ancel:'})
  call term_sendkeys(buf, "y")
  call WaitFor({-> term_getstatus(buf) == "finished"})

  " close the terminal window where Vim was running
  quit
endfunc

func Test_terminal_open_autocmd()
  augroup repro
    au!
    au TerminalOpen * let s:called += 1
  augroup END

  let s:called = 0

  " Open a terminal window with :terminal
  terminal
  call assert_equal(1, s:called)
  bwipe!

  " Open a terminal window with term_start()
  call term_start(&shell)
  call assert_equal(2, s:called)
  bwipe!

  " Open a hidden terminal buffer with :terminal
  terminal ++hidden
  call assert_equal(3, s:called)
  for buf in term_list()
    exe buf . "bwipe!"
  endfor

  " Open a hidden terminal buffer with term_start()
  let buf = term_start(&shell, {'hidden': 1})
  call assert_equal(4, s:called)
  exe buf . "bwipe!"

  unlet s:called
  au! repro
endfunction

func Check_dump01(off)
  call assert_equal('one two three four five', trim(getline(a:off + 1)))
  call assert_equal('~           Select Word', trim(getline(a:off + 7)))
  call assert_equal(':popup PopUp', trim(getline(a:off + 20)))
endfunc

func Test_terminal_dumpwrite_composing()
  if !CanRunVimInTerminal()
    return
  endif
  let save_enc = &encoding
  set encoding=utf-8
  call assert_equal(1, winnr('$'))

  let text = " a\u0300 e\u0302 o\u0308"
  call writefile([text], 'Xcomposing')
  let buf = RunVimInTerminal('Xcomposing', {})
  call WaitFor({-> term_getline(buf, 1) =~ text})
  call term_dumpwrite(buf, 'Xdump')
  let dumpline = readfile('Xdump')[0]
  call assert_match('|à| |ê| |ö', dumpline)

  call StopVimInTerminal(buf)
  call delete('Xcomposing')
  call delete('Xdump')
  let &encoding = save_enc
endfunc

" just testing basic functionality.
func Test_terminal_dumpload()
  call assert_equal(1, winnr('$'))
  call term_dumpload('dumps/Test_popup_command_01.dump')
  call assert_equal(2, winnr('$'))
  call assert_equal(20, line('$'))
  call Check_dump01(0)
  quit
endfunc

func Test_terminal_dumpdiff()
  call assert_equal(1, winnr('$'))
  call term_dumpdiff('dumps/Test_popup_command_01.dump', 'dumps/Test_popup_command_02.dump')
  call assert_equal(2, winnr('$'))
  call assert_equal(62, line('$'))
  call Check_dump01(0)
  call Check_dump01(42)
  call assert_equal('           bbbbbbbbbbbbbbbbbb ', getline(26)[0:29])
  quit
endfunc

func Test_terminal_dumpdiff_options()
  set laststatus=0
  call assert_equal(1, winnr('$'))
  let height = winheight(0)
  call term_dumpdiff('dumps/Test_popup_command_01.dump', 'dumps/Test_popup_command_02.dump', {'vertical': 1, 'term_cols': 33})
  call assert_equal(2, winnr('$'))
  call assert_equal(height, winheight(winnr()))
  call assert_equal(33, winwidth(winnr()))
  call assert_equal('dump diff dumps/Test_popup_command_01.dump', bufname('%'))
  quit

  call assert_equal(1, winnr('$'))
  let width = winwidth(0)
  call term_dumpdiff('dumps/Test_popup_command_01.dump', 'dumps/Test_popup_command_02.dump', {'vertical': 0, 'term_rows': 13, 'term_name': 'something else'})
  call assert_equal(2, winnr('$'))
  call assert_equal(width, winwidth(winnr()))
  call assert_equal(13, winheight(winnr()))
  call assert_equal('something else', bufname('%'))
  quit

  call assert_equal(1, winnr('$'))
  call term_dumpdiff('dumps/Test_popup_command_01.dump', 'dumps/Test_popup_command_02.dump', {'curwin': 1})
  call assert_equal(1, winnr('$'))
  bwipe

  set laststatus&
endfunc

func Api_drop_common(options)
  call assert_equal(1, winnr('$'))

  " Use the title termcap entries to output the escape sequence.
  call writefile([
	\ 'set title',
	\ 'exe "set t_ts=\<Esc>]51; t_fs=\x07"',
	\ 'let &titlestring = ''["drop","Xtextfile"' . a:options . ']''',
	\ 'redraw',
	\ "set t_ts=",
	\ ], 'Xscript')
  let buf = RunVimInTerminal('-S Xscript', {})
  call WaitFor({-> bufnr('Xtextfile') > 0})
  call assert_equal('Xtextfile', expand('%:t'))
  call assert_true(winnr('$') >= 3)
  return buf
endfunc

func Test_terminal_api_drop_newwin()
  if !CanRunVimInTerminal()
    return
  endif
  let buf = Api_drop_common('')
  call assert_equal(0, &bin)
  call assert_equal('', &fenc)

  call StopVimInTerminal(buf)
  call delete('Xscript')
  bwipe Xtextfile
endfunc

func Test_terminal_api_drop_newwin_bin()
  if !CanRunVimInTerminal()
    return
  endif
  let buf = Api_drop_common(',{"bin":1}')
  call assert_equal(1, &bin)

  call StopVimInTerminal(buf)
  call delete('Xscript')
  bwipe Xtextfile
endfunc

func Test_terminal_api_drop_newwin_binary()
  if !CanRunVimInTerminal()
    return
  endif
  let buf = Api_drop_common(',{"binary":1}')
  call assert_equal(1, &bin)

  call StopVimInTerminal(buf)
  call delete('Xscript')
  bwipe Xtextfile
endfunc

func Test_terminal_api_drop_newwin_nobin()
  if !CanRunVimInTerminal()
    return
  endif
  set binary
  let buf = Api_drop_common(',{"nobin":1}')
  call assert_equal(0, &bin)

  call StopVimInTerminal(buf)
  call delete('Xscript')
  bwipe Xtextfile
  set nobinary
endfunc

func Test_terminal_api_drop_newwin_nobinary()
  if !CanRunVimInTerminal()
    return
  endif
  set binary
  let buf = Api_drop_common(',{"nobinary":1}')
  call assert_equal(0, &bin)

  call StopVimInTerminal(buf)
  call delete('Xscript')
  bwipe Xtextfile
  set nobinary
endfunc

func Test_terminal_api_drop_newwin_ff()
  if !CanRunVimInTerminal()
    return
  endif
  let buf = Api_drop_common(',{"ff":"dos"}')
  call assert_equal("dos", &ff)

  call StopVimInTerminal(buf)
  call delete('Xscript')
  bwipe Xtextfile
endfunc

func Test_terminal_api_drop_newwin_fileformat()
  if !CanRunVimInTerminal()
    return
  endif
  let buf = Api_drop_common(',{"fileformat":"dos"}')
  call assert_equal("dos", &ff)

  call StopVimInTerminal(buf)
  call delete('Xscript')
  bwipe Xtextfile
endfunc

func Test_terminal_api_drop_newwin_enc()
  if !CanRunVimInTerminal()
    return
  endif
  let buf = Api_drop_common(',{"enc":"utf-16"}')
  call assert_equal("utf-16", &fenc)

  call StopVimInTerminal(buf)
  call delete('Xscript')
  bwipe Xtextfile
endfunc

func Test_terminal_api_drop_newwin_encoding()
  if !CanRunVimInTerminal()
    return
  endif
  let buf = Api_drop_common(',{"encoding":"utf-16"}')
  call assert_equal("utf-16", &fenc)

  call StopVimInTerminal(buf)
  call delete('Xscript')
  bwipe Xtextfile
endfunc

func Test_terminal_api_drop_oldwin()
  if !CanRunVimInTerminal()
    return
  endif
  let firstwinid = win_getid()
  split Xtextfile
  let textfile_winid = win_getid()
  call assert_equal(2, winnr('$'))
  call win_gotoid(firstwinid)

  " Use the title termcap entries to output the escape sequence.
  call writefile([
	\ 'set title',
	\ 'exe "set t_ts=\<Esc>]51; t_fs=\x07"',
	\ 'let &titlestring = ''["drop","Xtextfile"]''',
	\ 'redraw',
	\ "set t_ts=",
	\ ], 'Xscript')
  let buf = RunVimInTerminal('-S Xscript', {'rows': 10})
  call WaitFor({-> expand('%:t') =='Xtextfile'})
  call assert_equal(textfile_winid, win_getid())

  call StopVimInTerminal(buf)
  call delete('Xscript')
  bwipe Xtextfile
endfunc

func Tapi_TryThis(bufnum, arg)
  let g:called_bufnum = a:bufnum
  let g:called_arg = a:arg
endfunc

func WriteApiCall(funcname)
  " Use the title termcap entries to output the escape sequence.
  call writefile([
	\ 'set title',
	\ 'exe "set t_ts=\<Esc>]51; t_fs=\x07"',
	\ 'let &titlestring = ''["call","' . a:funcname . '",["hello",123]]''',
	\ 'redraw',
	\ "set t_ts=",
	\ ], 'Xscript')
endfunc

func Test_terminal_api_call()
  if !CanRunVimInTerminal()
    return
  endif

  call WriteApiCall('Tapi_TryThis')
  let buf = RunVimInTerminal('-S Xscript', {})
  call WaitFor({-> exists('g:called_bufnum')})
  call assert_equal(buf, g:called_bufnum)
  call assert_equal(['hello', 123], g:called_arg)

  call StopVimInTerminal(buf)
  call delete('Xscript')
  unlet g:called_bufnum
  unlet g:called_arg
endfunc

func Test_terminal_api_call_fails()
  if !CanRunVimInTerminal()
    return
  endif

  call WriteApiCall('TryThis')
  call ch_logfile('Xlog', 'w')
  let buf = RunVimInTerminal('-S Xscript', {})
  call WaitFor({-> string(readfile('Xlog')) =~ 'Invalid function name: TryThis'})

  call StopVimInTerminal(buf)
  call delete('Xscript')
  call ch_logfile('', '')
  call delete('Xlog')
endfunc

let s:caught_e937 = 0

func Tapi_Delete(bufnum, arg)
  try
    execute 'bdelete!' a:bufnum
  catch /E937:/
    let s:caught_e937 = 1
  endtry
endfunc

func Test_terminal_api_call_fail_delete()
  if !CanRunVimInTerminal()
    return
  endif

  call WriteApiCall('Tapi_Delete')
  let buf = RunVimInTerminal('-S Xscript', {})
  call WaitFor({-> s:caught_e937 == 1})

  call StopVimInTerminal(buf)
  call delete('Xscript')
  call ch_logfile('', '')
endfunc

func Test_terminal_ansicolors_default()
  let colors = [
	\ '#000000', '#e00000',
	\ '#00e000', '#e0e000',
	\ '#0000e0', '#e000e0',
	\ '#00e0e0', '#e0e0e0',
	\ '#808080', '#ff4040',
	\ '#40ff40', '#ffff40',
	\ '#4040ff', '#ff40ff',
	\ '#40ffff', '#ffffff',
	\]

  let buf = Run_shell_in_terminal({})
  call assert_equal(colors, term_getansicolors(buf))
  call Stop_shell_in_terminal(buf)
  call term_wait(buf)

  exe buf . 'bwipe'
endfunc

let s:test_colors = [
	\ '#616e64', '#0d0a79',
	\ '#6d610d', '#0a7373',
	\ '#690d0a', '#6d696e',
	\ '#0d0a6f', '#616e0d',
	\ '#0a6479', '#6d0d0a',
	\ '#617373', '#0d0a69',
	\ '#6d690d', '#0a6e6f',
	\ '#610d0a', '#6e6479',
	\]

func Test_terminal_ansicolors_global()
  let g:terminal_ansi_colors = reverse(copy(s:test_colors))
  let buf = Run_shell_in_terminal({})
  call assert_equal(g:terminal_ansi_colors, term_getansicolors(buf))
  call Stop_shell_in_terminal(buf)
  call term_wait(buf)

  exe buf . 'bwipe'
  unlet g:terminal_ansi_colors
endfunc

func Test_terminal_ansicolors_func()
  let g:terminal_ansi_colors = reverse(copy(s:test_colors))
  let buf = Run_shell_in_terminal({'ansi_colors': s:test_colors})
  call assert_equal(s:test_colors, term_getansicolors(buf))

  call term_setansicolors(buf, g:terminal_ansi_colors)
  call assert_equal(g:terminal_ansi_colors, term_getansicolors(buf))

  let colors = [
	\ 'ivory', 'AliceBlue',
	\ 'grey67', 'dark goldenrod',
	\ 'SteelBlue3', 'PaleVioletRed4',
	\ 'MediumPurple2', 'yellow2',
	\ 'RosyBrown3', 'OrangeRed2',
	\ 'white smoke', 'navy blue',
	\ 'grey47', 'gray97',
	\ 'MistyRose2', 'DodgerBlue4',
	\]
  call term_setansicolors(buf, colors)

  let colors[4] = 'Invalid'
  call assert_fails('call term_setansicolors(buf, colors)', 'E474:')

  call Stop_shell_in_terminal(buf)
  call term_wait(buf)
  exe buf . 'bwipe'
endfunc

func Test_terminal_termwinsize_option_fixed()
  if !CanRunVimInTerminal()
    return
  endif
  set termwinsize=6x40
  let text = []
  for n in range(10)
    call add(text, repeat(n, 50))
  endfor
  call writefile(text, 'Xwinsize')
  let buf = RunVimInTerminal('Xwinsize', {})
  let win = bufwinid(buf)
  call assert_equal([6, 40], term_getsize(buf))
  call assert_equal(6, winheight(win))
  call assert_equal(40, winwidth(win))

  " resizing the window doesn't resize the terminal.
  resize 10
  vertical resize 60
  call assert_equal([6, 40], term_getsize(buf))
  call assert_equal(10, winheight(win))
  call assert_equal(60, winwidth(win))

  call StopVimInTerminal(buf)
  call delete('Xwinsize')

  call assert_fails('set termwinsize=40', 'E474')
  call assert_fails('set termwinsize=10+40', 'E474')
  call assert_fails('set termwinsize=abc', 'E474')

  set termwinsize=
endfunc

func Test_terminal_termwinsize_option_zero()
  set termwinsize=0x0
  let buf = Run_shell_in_terminal({})
  let win = bufwinid(buf)
  call assert_equal([winheight(win), winwidth(win)], term_getsize(buf))
  call Stop_shell_in_terminal(buf)
  call term_wait(buf)
  exe buf . 'bwipe'

  set termwinsize=7x0
  let buf = Run_shell_in_terminal({})
  let win = bufwinid(buf)
  call assert_equal([7, winwidth(win)], term_getsize(buf))
  call Stop_shell_in_terminal(buf)
  call term_wait(buf)
  exe buf . 'bwipe'

  set termwinsize=0x33
  let buf = Run_shell_in_terminal({})
  let win = bufwinid(buf)
  call assert_equal([winheight(win), 33], term_getsize(buf))
  call Stop_shell_in_terminal(buf)
  call term_wait(buf)
  exe buf . 'bwipe'

  set termwinsize=
endfunc

func Test_terminal_termwinsize_mininmum()
  set termwinsize=10*50
  vsplit
  let buf = Run_shell_in_terminal({})
  let win = bufwinid(buf)
  call assert_inrange(10, 1000, winheight(win))
  call assert_inrange(50, 1000, winwidth(win))
  call assert_equal([winheight(win), winwidth(win)], term_getsize(buf))

  resize 15
  vertical resize 60
  redraw
  call assert_equal([15, 60], term_getsize(buf))
  call assert_equal(15, winheight(win))
  call assert_equal(60, winwidth(win))

  resize 7
  vertical resize 30
  redraw
  call assert_equal([10, 50], term_getsize(buf))
  call assert_equal(7, winheight(win))
  call assert_equal(30, winwidth(win))

  call Stop_shell_in_terminal(buf)
  call term_wait(buf)
  exe buf . 'bwipe'

  set termwinsize=0*0
  let buf = Run_shell_in_terminal({})
  let win = bufwinid(buf)
  call assert_equal([winheight(win), winwidth(win)], term_getsize(buf))
  call Stop_shell_in_terminal(buf)
  call term_wait(buf)
  exe buf . 'bwipe'

  set termwinsize=
endfunc
