#ifndef GUI_H
#define GUI_H

#include <video/video.h>

struct ctl_driver;

struct ctl {
    struct ctl_driver*  drv;
    struct ctl*         next;
};

struct ctl_driver {
    void (*init)(void);
    void (*deinit)(void);
    void (*create)(struct ctl* ctl);
    void (*destroy)(struct ctl* ctl);
    void (*draw)(struct ctl* ctl);
    size_t size;
};

#define CTL_REGISTER(drv) \
    static const void* __attribute__((section("ctl_drivers"), used)) \
        __ctl_driver_ ## drv = &drv;

void video_init(void);
void video_deinit(void);

void video_draw(void);

video_bitmap_t* video_get_text(const wchar_t* text, uint32_t color,
    uint32_t bgcolor);
void video_free_text(video_bitmap_t* bitmap);

void ctls_init(void);
void ctls_deinit(void);
void ctls_draw(void);
struct ctl* ctl_create(struct ctl_driver* drv);


extern struct ctl_driver ctl_window;
struct ctl_window {
    struct ctl      ctl;
    video_bitmap_t* bmp_title;
};

extern struct ctl_driver ctl_mouse;
struct ctl_mouse {
    struct ctl      ctl;
};


#endif
