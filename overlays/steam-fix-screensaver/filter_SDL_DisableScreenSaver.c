/* SPDX-License-Identifier: MIT */

/*
  Remainder of file originally created by github user InfoTeddy and shared under MIT license
  Original post: https://gist.github.com/InfoTeddy/4d41a5b5b5fc39f52666923a12cfce1e
*/

/*
 * On Linux, Steam periodically calls SDL_DisableScreenSaver() so your
 * screensaver doesn't work with the Steam client open even if you aren't
 * playing a game, as described in
 * https://github.com/ValveSoftware/steam-for-linux/issues/5607 .
 *
 * To fix this, LD_PRELOAD a library that replaces SDL_DisableScreenSaver()
 * with a no-op if the executable calling it is Steam, but otherwise let it
 * through for other applications. (And print some messages for debugging.)
 *
 * Compile this file with
 *     gcc -shared -fPIC -ldl -m32 -o fix_steam_screensaver_lib.so fix_steam_screensaver.c
 *     gcc -shared -fPIC -ldl -m64 -o fix_steam_screensaver_lib64.so fix_steam_screensaver.c
 *
 * and launch Steam with
 *     LD_PRELOAD="fix_steam_screensaver_\$LIB.so"
 * .
 */

#define _GNU_SOURCE /* RTLD_NEXT is a GNU extension. */
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#ifndef __linux__
#error Platform not supported.
#endif

#ifdef __i386__
#define ARCH "i386"
#elif defined(__amd64__)
#define ARCH "amd64"
#else
#error Architecture not supported.
#endif

static char exe_name[1024];
static void (*real_function)(void);

static void vlog(const char* text)
{
  //fprintf(stderr, "[" ARCH "] %s: %s\n", exe_name, text);
}

static void call_real_function(void)
{
    if (real_function == NULL) {
        /* Thankfully SDL_DisableScreenSaver() only exists since SDL
         * 2.0, else I'd have to detect the SDL version. */
        real_function = dlvsym(RTLD_NEXT, "SDL_DisableScreenSaver", "libSDL2-2.0.so.0");

        if (real_function == NULL)
            real_function = dlsym(RTLD_NEXT, "SDL_DisableScreenSaver");

        /* Oh god I hope it works, I don't want to implement more
         * libTAS logic... */

        if (real_function != NULL)
            vlog("Successfully linked SDL_DisableScreenSaver().");
    }

    if (real_function != NULL) {
        vlog("Allowing SDL_DisableScreenSaver().");
        real_function();
    } else
        vlog("Could not link SDL_DisableScreenSaver().");
}

static int is_steam(void)
{
    static int inited;
    static int retval;

    if (inited)
        return retval;
    inited = 1;

    {
        const char* last_slash = strrchr(exe_name, '/');
        const char* name;

        if (last_slash == NULL)
            /* Uh, just use the whole string then. */
            name = exe_name;
        else
            name = last_slash + 1;

        retval = strcmp(name, "steam") == 0;
    }

    return retval;
}

void SDL_DisableScreenSaver(void)
{
    if (exe_name[0] == '\0') {
        ssize_t len = readlink("/proc/self/exe", exe_name, sizeof(exe_name) - 1);

        if (len == -1)
            strcpy(exe_name, "(unknown)");
        else
            exe_name[len] = '\0';
    }

    if (is_steam())
        vlog("Prevented SDL_DisableScreenSaver().");
    else
        call_real_function();
}
