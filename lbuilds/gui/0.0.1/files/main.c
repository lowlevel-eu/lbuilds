#include <stdio.h>
#include <stdlib.h>

#include "gui.h"

int main(void)
{
    stdout = NULL;

    video_switch_mode();
    video_draw();

    return 0;
}
