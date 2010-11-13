#include <stdlib.h>

#include "gui.h"

extern struct ctl_driver* __start_ctl_drivers;
extern struct ctl_driver* __stop_ctl_drivers;

static struct ctl* first_ctl = NULL;

void ctls_init(void)
{
    struct ctl_driver** pdrv;
    struct ctl_driver* drv;

    /* Alle in dieser Binary verfuegbaren Steuerelemente initialisieren */
    pdrv = &__start_ctl_drivers;
    while (pdrv < &__stop_ctl_drivers) {
        drv = *pdrv;
        drv->init();
        pdrv++;
    }
}

void ctls_deinit(void)
{
    struct ctl_driver** pdrv;
    struct ctl_driver* drv;
    struct ctl* p;

    /* Alle Objekte zerstoeren */
    for (p = first_ctl; p; p = p->next) {
        p->drv->destroy(p);
    }

    /* Alle in dieser Binary verfuegbaren Steuerelemente initialisieren */
    pdrv = &__start_ctl_drivers;
    while (pdrv < &__stop_ctl_drivers) {
        drv = *pdrv;
        drv->deinit();
        pdrv++;
    }
}

struct ctl* ctl_create(struct ctl* parent, struct ctl_driver* drv)
{
    struct ctl* obj;

    obj = calloc(1, drv->size);
    obj->drv = drv;

    if (parent == NULL) {
        obj->next = first_ctl;
        first_ctl = obj;
    } else {
        obj->next = parent->children;
        parent->children = obj;
    }

    drv->create(obj);

    return obj;
}

static void ctl_draw(struct ctl* ctl)
{
    struct ctl* p;

    ctl->drv->draw(ctl);

    for (p = ctl->children; p; p = p->next) {
        ctl_draw(p);
    }
}

void ctls_draw(void)
{
    struct ctl* p;

    for (p = first_ctl; p; p = p->next) {
        ctl_draw(p);
    }
}
