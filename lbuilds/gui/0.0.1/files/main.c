#include <stdio.h>
#include <stdlib.h>

#include "gui.h"

int main(void)
{
    stdout = NULL;

    video_init();
    ctls_init();

    while (1) {
        video_draw();
    }

    video_deinit();
    ctls_deinit();

    return 0;
}
