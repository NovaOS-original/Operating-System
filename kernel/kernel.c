#include <stddef.h>
#include <stdint.h>
#include "limine.h"

LIMINE_REQUESTS_START_MARKER
static volatile uint64_t limine_requests_start[] = {
    0xf6b8f4b39de7d1ae, 0xfab91a6940fcb9cf
};

LIMINE_BASE_REVISION(3);

static volatile uint64_t limine_requests_end[] LIMINE_REQUESTS_END_MARKER = {
    0xadc0e0531bb10d03, 0x9572709f31764c62
};

static volatile struct limine_framebuffer_request framebuffer_request LIMINE_REQUEST = {
    .id = { LIMINE_FRAMEBUFFER_REQUEST_ID },
    .revision = 0,
    .response = NULL
};

static inline void outb(uint16_t port, uint8_t value) {
    __asm__ volatile ("outb %0, %1" : : "a"(value), "Nd"(port));
}

static inline uint8_t inb(uint16_t port) {
    uint8_t value;
    __asm__ volatile ("inb %1, %0" : "=a"(value) : "Nd"(port));
    return value;
}

static void serial_init(void) {
    outb(0x3F9, 0x00);
    outb(0x3FB, 0x80);
    outb(0x3F8, 0x01);
    outb(0x3F9, 0x00);
    outb(0x3FB, 0x03);
    outb(0x3FA, 0xC7);
    outb(0x3FC, 0x0B);
}

static void serial_putc(char c) {
    for (uint32_t tries = 0; tries < 100000u; ++tries) {
        if ((inb(0x3FD) & 0x20u) != 0) {
            outb(0x3F8, (uint8_t)c);
            return;
        }
    }
}

static void serial_write(const char *text) {
    while (*text != '\0') {
        if (*text == '\n') serial_putc('\r');
        serial_putc(*text++);
    }
}

static void halt_forever(void) {
    for (;;) __asm__ volatile ("cli; hlt");
}

static void put_pixel(struct limine_framebuffer *fb, uint64_t x, uint64_t y,
                      uint32_t rgb) {
    if (fb == NULL || fb->address == NULL || x >= fb->width || y >= fb->height ||
        fb->bpp != 32) return;
    volatile uint32_t *pixel = (volatile uint32_t *)
        ((uintptr_t) fb->address + y * fb->pitch + x * 4);
    *pixel = rgb;
}

static const uint8_t glyph_N[7] = {17,25,21,19,17,17,17};
static const uint8_t glyph_O[7] = {14,17,17,17,17,17,14};
static const uint8_t glyph_V[7] = {17,17,17,17,17,10,4};
static const uint8_t glyph_A[7] = {14,17,17,31,17,17,17};
static const uint8_t glyph_S[7] = {15,16,16,14,1,1,30};
static const uint8_t glyph_space[7] = {0,0,0,0,0,0,0};
static const uint8_t glyph_star[7] = {0,4,21,14,21,4,0};

static void draw_char(struct limine_framebuffer *fb, uint64_t x, uint64_t y,
                      const uint8_t glyph[7], uint32_t color, uint32_t scale) {
    for (uint64_t row = 0; row < 7; ++row) {
        for (uint64_t col = 0; col < 5; ++col) {
            if ((glyph[row] & (1u << (4u - (unsigned) col))) == 0) continue;
            for (uint32_t sy = 0; sy < scale; ++sy)
                for (uint32_t sx = 0; sx < scale; ++sx)
                    put_pixel(fb, x + col * scale + sx, y + row * scale + sy, color);
        }
    }
}

static void draw_banner(struct limine_framebuffer *fb) {
    const uint8_t *banner[] = {glyph_N, glyph_O, glyph_V, glyph_A, glyph_space,
                               glyph_S, glyph_O, glyph_space, glyph_star};
    const uint64_t count = sizeof(banner) / sizeof(banner[0]);
    uint64_t x = 48;
    const uint64_t y = 48;
    const uint32_t scale = 6;
    for (uint64_t i = 0; i < count; ++i) {
        draw_char(fb, x, y, banner[i], 0x00d7f7ff, scale);
        x += 6 * scale;
    }
    for (uint64_t px = 48; px < 48 + 420; ++px)
        for (uint64_t py = 112; py < 116; ++py)
            put_pixel(fb, px, py, 0x006b8cff);
    for (uint64_t px = 48; px < 48 + 12; ++px)
        for (uint64_t py = 144; py < 156; ++py)
            put_pixel(fb, px, py, 0x0044dd88);
}

void kernel_main(void) {
    serial_init();
    serial_write("NOVA OS: kernel entered\n");
    struct limine_framebuffer_response *response = framebuffer_request.response;
    if (response != NULL && response->framebuffer_count > 0 &&
        response->framebuffers != NULL && response->framebuffers[0] != NULL) {
        struct limine_framebuffer *fb = response->framebuffers[0];
        for (uint64_t y = 0; y < fb->height; ++y)
            for (uint64_t x = 0; x < fb->width; ++x)
                put_pixel(fb, x, y, 0x00101828);
        draw_banner(fb);
        serial_write("NOVA OS: framebuffer ready\n");
    } else {
        serial_write("NOVA OS: framebuffer unavailable\n");
    }
    serial_write("NOVA OS: initialization complete; halted safely\n");
    halt_forever();
}
