#include <video/video.h>
#include <stdio.h>
#include <stdlib.h>
#include <png.h>

#include "gui.h"

void ctl_image_init(void)
{
}

static struct ctl_image* from_ctl(struct ctl* ctl)
{
    if (ctl->drv != &ctl_image) {
        return NULL;
    }

    return (struct ctl_image*) ctl;
}

void ctl_image_deinit(void) {
}

void ctl_image_create(struct ctl* ctl)
{
    struct ctl_image* c = from_ctl(ctl);

    FILE*       f;
    png_struct* png;
    png_info*   info;
    uint8_t     buf[8];
    int         width, height;
    png_byte**  row_pointers    = NULL;
    uint8_t*    raw             = NULL;
    int         i;
    int         ret;

    f = fopen("signifant.png", "r");
    if (!f) {
        return;
    }

    /* Header einlesen und pruefen, ob es eine PNG ist */
    ret = fread(buf, 1, 8, f);
    if (ret != 8) {
        goto fail_fopen;
    }

    if (png_sig_cmp(buf, 0, 8)) {
        goto fail_fopen;
    }

    /* PNG oeffnen */
    png = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (png == NULL) {
        goto fail_fopen;
    }

    info = png_create_info_struct(png);
    if (info == NULL) {
        goto fail_png;
    }

    /* Exceptionhandler einrichten */
    if (setjmp(png_jmpbuf(png))) {
        goto fail_png;
    }

    /* Initialisieren */
    png_init_io(png, f);
    png_set_sig_bytes(png, 8);

    png_read_info(png, info);
    width   = png_get_image_width(png, info);
    height  = png_get_image_height(png, info);

    raw = malloc(4 * width * height);
    row_pointers = malloc(height * sizeof(png_byte*));
    for (i = 0; i < height; i++) {
        row_pointers[i] = raw + (4 * width * i);
    }

    png_read_image(png, row_pointers);

    c->bitmap = libvideo_create_bitmap(width, height, 4 * width * height, raw);

    libvideo_upload_bitmap(c->bitmap);
    libvideo_do_command_buffer();

fail_png:
    free(raw);
    free(row_pointers);
    png_destroy_read_struct(&png, info ? &info : NULL, NULL);
fail_fopen:
    fclose(f);
}

void ctl_image_destroy(struct ctl* ctl)
{
}

void ctl_image_draw(struct ctl* ctl)
{
    struct ctl_image* c = from_ctl(ctl);

    libvideo_draw_bitmap(c->bitmap, ctl->x, ctl->y);
}

struct ctl_driver ctl_image = {
    .init       = ctl_image_init,
    .deinit     = ctl_image_deinit,


    .create     = ctl_image_create,
    .destroy    = ctl_image_destroy,
    .draw       = ctl_image_draw,

    .size       = sizeof(struct ctl_image),
};

CTL_REGISTER(ctl_image)
