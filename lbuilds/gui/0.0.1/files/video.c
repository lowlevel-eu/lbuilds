#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <video/video.h>

#include <ft2build.h>
#include FT_FREETYPE_H

#include "gui.h"

#define RES_X   800
#define RES_Y   600
#define RES_BPP  24

static video_bitmap_t* fb_bitmap;
static uint8_t* fb;

static FT_Library freetype_lib;
static FT_Face font;

static int init_ft(void)
{
    int ret;

    ret = FT_Init_FreeType(&freetype_lib);
    if (ret) {
        fprintf(stderr, "FT_Init_FreeType = %d\n", ret);
        return -1;
    }

    ret = FT_New_Face(freetype_lib, "console8x16.pcf.gz", 0, &font);
//    ret = FT_New_Face(freetype_lib, "file:/DejaVuSansMono.ttf", 0, &font);
    if (ret) {
        fprintf(stderr, "Schriftart kann nicht geladen werden\n");
        return -1;
    }

    ret = FT_Set_Pixel_Sizes(font, 16, 16);
    if (ret) {
        fprintf(stderr, "Schriftgröße kann nicht gesetzt werden\n");
        return -1;
    }

    return 0;
}

void video_switch_mode(void)
{
    driver_context_t* ctx;
    size_t fb_size;
    int ret;

    ret = init_ft();
    if (ret) {
        fprintf(stderr, "Freetype kann nicht initialisiert werden\n");
        exit(1);
    }

    ctx = libvideo_create_driver_context("vesa");
    if (ctx == NULL) {
        fprintf(stderr, "Konnte Kontext nicht anlegen\n");
        exit(1);
    }

    libvideo_use_driver_context(ctx);
    libvideo_get_command_buffer(1024);
    libvideo_change_device(0);
    libvideo_do_command_buffer();

    ret = libvideo_change_display_resolution(0, RES_X, RES_Y, RES_BPP);
    if (ret) {
        fprintf(stderr, "Konnte Grafikmodus nicht wechseln\n");
        exit(1);
    }

    fb_bitmap = libvideo_get_frontbuffer_bitmap(0);
    fb = libvideo_open_upload_buffer(fb_bitmap, &fb_size);
    if (fb_size != RES_X * RES_Y * (RES_BPP / 8)) {
        fprintf(stderr, "Framebuffer hat unerwartete Größe\n");
        exit(1);
    }

    libvideo_request_backbuffers(fb_bitmap, 2);
}

/*
 * Gibt die Breite eines Texts in Pixeln zurueck
 */
static int video_handle_text(const wchar_t* text)
{
    FT_GlyphSlot slot = font->glyph;
    int ret;
    int width = 0;

    while (*text) {
        ret = FT_Load_Char(font, *text, FT_LOAD_MONOCHROME);
        if (ret) {
            return -1;
        }

        width += slot->advance.x / 64;
        text++;
    }

    return width;
}

static void draw_char(FT_GlyphSlot slot, uint8_t* buf, int pitch, int sx,
    uint32_t color, uint32_t bgcolor)
{
    uint8_t* p = buf;
    int x, y;

    for (y = 0; y < slot->bitmap.rows; y++) {
        p = buf + y * pitch + sx;
        for (x = 0; x < slot->bitmap.width; x++) {

            /* Kein Pixel zu setzen? */
            int pixel = 8 * y * slot->bitmap.pitch + x;
            int byte = pixel / 8;
            int bit = 7 - (pixel % 8);
            uint32_t c;

            if ((slot->bitmap.buffer[byte] & (1 << bit)) == 0) {
                c = bgcolor;
            } else {
                c = color;
            }

            p[0] = (c >> 24) & 0xFF;
            p[1] = (c >> 16) & 0xFF;
            p[2] = (c >>  8) & 0xFF;
            p[3] = (c >>  0) & 0xFF;

            p += 4;
        }
    }
}

video_bitmap_t* video_get_text(const wchar_t* text, uint32_t color,
    uint32_t bgcolor)
{
    FT_GlyphSlot slot = font->glyph;
    video_bitmap_t* bitmap;
    int width;
    int x;
    int ret;
    uint8_t* buf;

    /* Breite des Texts berechnen */
    width = video_handle_text(text);
    if (width < 0) {
        return NULL;
    }

    /* Bitmap anlegen */
    buf = calloc(sizeof(uint32_t), width * 16);

    /* Text zeichnen */
    x = 0;
    while (*text) {
        ret = FT_Load_Char(font, *text, FT_LOAD_MONOCHROME);
        if (ret) {
            return NULL;
        }

        ret = FT_Render_Glyph(slot, FT_RENDER_MODE_MONO);
        if (ret) {
            return NULL;
        }

        draw_char(slot, buf, 4 * width, x, color, bgcolor);

        x += 4 * slot->advance.x / 64;
        text++;
    }

    /* Bitmap an den Treiber schicken */
    bitmap = libvideo_create_bitmap(width, 16, 4 * width * 16, buf);
    libvideo_upload_bitmap(bitmap);
    libvideo_do_command_buffer();

    /* Und Puffer wieder freigeben */
    free(buf);

    return bitmap;
}

void video_free_text(video_bitmap_t* bitmap)
{
    libvideo_destroy_bitmap(bitmap);
}

void video_draw(void)
{
    /* Hintergrund zeichnen */
    libvideo_change_target(fb_bitmap);
    libvideo_change_color(0, 0, 16, 0);
    libvideo_draw_rectangle(0, 0, RES_X, RES_Y);
    libvideo_do_command_buffer();

    /* Ein Fenster */
    ctls_draw();
    libvideo_do_command_buffer();

    libvideo_flip_buffers(fb_bitmap);
    libvideo_do_command_buffer();
}

void video_init(void)
{
    struct ctl* ctl;

    video_switch_mode();
    ctl_create(&ctl_mouse);

    ctl = ctl_create(&ctl_image);
    ctl->x = 120;
    ctl->y = 140;

    ctl = ctl_create(&ctl_window);
    ctl->x = 100;
    ctl->y = 100;
}

void video_deinit(void)
{
    /* TODO Modus zuruecksetzen */
}
