#include <video/video.h>
#include <stdio.h>

#include "gui.h"

static video_bitmap_t* bmp_mouse_cursor;
FILE* kbc_mousedata;

struct mousedata {
    int32_t x;
    int32_t y;
    uint8_t buttons;
    uint8_t btn_down;
    uint8_t btn_up;
    uint8_t padding;
} __attribute__((packed));

static void update(struct ctl_mouse* c)
{
    struct ctl* ctl = &c->ctl;
    struct mousedata in;

    fread(&in, 1, sizeof(in), kbc_mousedata);

    /* FIXME Aufloesung variabel machen */
    ctl->x = MIN(800, MAX(ctl->x + in.x, 0));
    ctl->y = MIN(600, MAX(ctl->y + in.y, 0));

    /* TODO Maustasten */
}

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

    kbc_mousedata = fopen("kbc:/mouse/data", "r");
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
    fclose(kbc_mousedata);
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

    update(c);
    libvideo_draw_bitmap(bmp_mouse_cursor, ctl->x, ctl->y);
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
