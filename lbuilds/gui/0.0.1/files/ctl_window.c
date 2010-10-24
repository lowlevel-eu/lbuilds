#include <video/video.h>

#include "gui.h"

static video_bitmap_t* bmp_win_close;

void ctl_window_init(void)
{
    /* Bitmap fuer Schliessen */
#define W 0xffffffff,
#define _ 0x00003300,
    static uint32_t raw_win_close[14 * 14] = {
        _ _ _ _ _ _ _ _ _ _ _ _ _ _
        _ _ _ _ _ _ _ _ _ _ _ _ _ _
        _ _ _ W _ _ _ _ _ _ W _ _ _
        _ _ W W W _ _ _ _ W W W _ _
        _ _ _ W W W _ _ W W W _ _ _
        _ _ _ _ W W W W W W _ _ _ _
        _ _ _ _ _ W W W W _ _ _ _ _
        _ _ _ _ _ W W W W _ _ _ _ _
        _ _ _ _ W W W W W W _ _ _ _
        _ _ _ W W W _ _ W W W _ _ _
        _ _ W W W _ _ _ _ W W W _ _
        _ _ _ W _ _ _ _ _ _ W _ _ _
        _ _ _ _ _ _ _ _ _ _ _ _ _ _
        _ _ _ _ _ _ _ _ _ _ _ _ _ _
    };
#undef W
#undef _
    bmp_win_close = libvideo_create_bitmap(14, 14, 4 * 14 * 14, raw_win_close);
    libvideo_upload_bitmap(bmp_win_close);
    libvideo_do_command_buffer();
}

static struct ctl_window* from_ctl(struct ctl* ctl)
{
    if (ctl->drv != &ctl_window) {
        return NULL;
    }

    return (struct ctl_window*) ctl;
}

void ctl_window_deinit(void) {
    libvideo_destroy_bitmap(bmp_win_close);
}

void ctl_window_create(struct ctl* ctl)
{
    struct ctl_window* c = from_ctl(ctl);

    c->bmp_title = video_get_text(L"Allar GUI ykkar eru í eigu okkar!",
        0x00ffffff, 0x00660000);
}

void ctl_window_destroy(struct ctl* ctl)
{
    struct ctl_window* c = from_ctl(ctl);

    video_free_text(c->bmp_title);
}

void ctl_window_draw(struct ctl* ctl)
{
    struct ctl_window* c = from_ctl(ctl);

    int x = 100;
    int y = 100;
    int w = 400;
    int h = 450;

    /* Fenster zeichnen */
    libvideo_change_color(0xff, 0xff, 0xff, 0xff);
    libvideo_draw_rectangle(x, y, w, h);

    libvideo_change_color(0xff, 0x00, 0x66, 0x00);
    libvideo_draw_rectangle(x + 1, y + 1, w - 2, 20);

    libvideo_draw_bitmap(c->bmp_title, x + 5, y + 3);

    libvideo_draw_bitmap(bmp_win_close, x + w - 18, y + 4);

}

struct ctl_driver ctl_window = {
    .init       = ctl_window_init,
    .deinit     = ctl_window_deinit,


    .create     = ctl_window_create,
    .destroy    = ctl_window_destroy,
    .draw       = ctl_window_draw,

    .size       = sizeof(struct ctl_window),
};

CTL_REGISTER(ctl_window)
