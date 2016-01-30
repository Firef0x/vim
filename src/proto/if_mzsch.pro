/* if_mzsch.c */
int mzscheme_enabled(int verbose);
void mzvim_check_threads(void);
void mzvim_reset_timer(void);
void mzscheme_end(void);
int mzscheme_main(int argc, char **argv);
void mzscheme_buffer_free(buf_T *buf);
void mzscheme_window_free(win_T *win);
void ex_mzscheme(exarg_T *eap);
void ex_mzfile(exarg_T *eap);
void do_mzeval(char_u *str, typval_T *rettv);
void raise_vim_exn(const char *add_info);
void raise_if_error(void);
buf_T *get_valid_buffer(void *obj);
win_T *get_valid_window(void *obj);
int mzthreads_allowed(void);
/* vim: set ft=c : */
