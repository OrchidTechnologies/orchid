// Cycc/Cympile - Shared Build Scripts for Make
// Copyright (C) 2013-2020  Jay Freeman (saurik)

// Zero Clause BSD license {{{
//
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
// }}}


#include <stdio.h>

int main(int argc, const char *argv[]) {
    const char *name = argv[1];
    FILE *file = fopen(argv[2], "rb");
    if (file == NULL) return 1;
    printf("const unsigned char %s_data[] =\n", name);
    size_t size = 0;
    for (;;) {
        unsigned char data[1024];
        size_t writ = fread(data, 1, sizeof(data), file);
        if (writ == 0) break;
        size += writ;
        char line[writ*4+3];
        line[0] = '"';
        for (size_t i = 0; i != writ; ++i) {
            line[i*4+1] = '\\';
            line[i*4+2] = 'x';
            line[i*4+3] = "0123456789abcdef"[data[i]/16];
            line[i*4+4] = "0123456789abcdef"[data[i]%16];
        }
        line[sizeof(line)-2] = '"';
        line[sizeof(line)-1] = '\n';
        fwrite(line, 1, sizeof(line), stdout);
    }
    printf(";\n");
    printf("const unsigned int %s_size = %zu;\n", name, size);
    return 0;
}
