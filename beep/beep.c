
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/kd.h>
#include <unistd.h>

#ifndef CLOCK_TICK_RATE
#define CLOCK_TICK_RATE 1193180
#endif

/* Meaningful Defaults */
#define DEFAULT_FREQ       440.0 /* Middle A */
#define DEFAULT_LENGTH     200   /* milliseconds */
#define DEFAULT_REPS       10
#define DEFAULT_DELAY      1000   /* milliseconds */

typedef struct beep_parms_t {
  float freq;     /* tone frequency (Hz)      */
  int length;     /* tone length    (ms)      */
  int reps;       /* # of repetitions         */
  int delay;      /* delay between reps  (ms) */
} beep_parms_t;

int console_fd = -1;

void play_beep(beep_parms_t parms) {
  int i; /* loop counter */
  
  /* try to snag the console */
  if((console_fd = open("/dev/console", O_WRONLY)) == -1) {
    fprintf(stderr, "Could not open /dev/console for writing.\n");
    printf("\a");  /* Output the only beep we can, in an effort to fall back on usefulness */
    perror("open");
    exit(1);
  }

  /* Beep */
  for (i = 0; i < parms.reps; i++) {                    /* start beep */
    if(ioctl(console_fd, KIOCSOUND, (int)(CLOCK_TICK_RATE/parms.freq)) < 0) {
      printf("\a");  /* Output the only beep we can, in an effort to fall back on usefulness */
      perror("ioctl");
    }
    usleep(1000*parms.length);                          /* wait...    */
    ioctl(console_fd, KIOCSOUND, 0);                    /* stop beep  */
    usleep(1000*parms.delay);                           /* wait...    */
  }                                                     /* repeat.    */

  close(console_fd);
}


int main() {
  beep_parms_t *parms = (beep_parms_t *)malloc(sizeof(beep_parms_t));
  parms->freq       = DEFAULT_FREQ;
  parms->length     = DEFAULT_LENGTH;
  parms->reps       = DEFAULT_REPS;
  parms->delay      = DEFAULT_DELAY;

  printf("Going to beep!\n");
  play_beep(*parms);
  
  free(parms);

  return 0;
}
