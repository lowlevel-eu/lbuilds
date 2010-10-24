#include <video/video.h>

#include "gui.h"

static video_bitmap_t* bmp_mouse_cursor;

void ctl_mouse_init(void)
{
    /* Mauszeiger */
#define W 0xffffffff,
#define _ 0x00000000,
    static uint32_t raw_mouse[14 * 14] = {
        _ _ _ _ _ _ _ _ _ _ _ _ _ _
        _ _ _ _ _ _ _ _ _ _ _ _ _ _
        _ _ W W W W W W W W W W W _
        _ _ W W W W W W W W W W _ _
        _ _ W W W W W W W W W _ _ _
        _ _ W W W W W W W W _ _ _ _
        _ _ W W W W W W W W _ _ _ _
        _ _ W W W W W W W W W _ _ _
        _ _ W W W W W W W W W W _ _
        _ _ W W W W W W W W W W W _
        _ _ W W W _ _ W W W W W _ _
        _ _ W W _ _ _ _ W W W _ _ _
        _ _ W _ _ _ _ _ _ W _ _ _ _
        _ _ _ _ _ _ _ _ _ _ _ _ _ _
    };
#undef W
#undef _
    bmp_mouse_cursor = libvideo_create_bitmap(14, 14, 4 * 14 * 14, raw_mouse);
    libvideo_upload_bitmap(bmp_mouse_cursor);
    libvideo_do_command_buffer();
}

static struct ctl_mouse* from_ctl(struct ctl* ctl)
{
    if (ctl->drv != &ctl_mouse) {
        return NULL;
    }

    return (struct ctl_mouse*) ctl;
}

void ctl_mouse_deinit(void) {
    libvideo_destroy_bitmap(bmp_mouse_cursor);
}

void ctl_mouse_create(struct ctl* ctl)
{
}

void ctl_mouse_destroy(struct ctl* ctl)
{
}

void ctl_mouse_draw(struct ctl* ctl)
{
    struct ctl_mouse* c = from_ctl(ctl);
    (void) c;

    static int x = 10;
    libvideo_draw_bitmap(bmp_mouse_cursor, x++, 200);
}

struct ctl_driver ctl_mouse = {
    .init       = ctl_mouse_init,
    .deinit     = ctl_mouse_deinit,


    .create     = ctl_mouse_create,
    .destroy    = ctl_mouse_destroy,
    .draw       = ctl_mouse_draw,

    .size       = sizeof(struct ctl_mouse),
};

CTL_REGISTER(ctl_mouse)
