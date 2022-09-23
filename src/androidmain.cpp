#ifdef ANDROID

#include "framework/platform/androidwindow.h"
#include <cstdlib>

extern "C" {
int main(int argc, const char* argv[]);
}

void android_main(struct android_app* app) {
    g_androidManager.setAndroidApp(app);
    g_androidWindow.initializeAndroidApp(app);

    bool terminated = false;
    g_window.setOnClose([&] {
        terminated = true;
    });
    while(!g_window.isVisible() && !terminated) {
        g_window.poll(); // poll until EGL is started
    }

    const char* args[] = { "OTClient" };
    main(1, args);
    std::exit(0);
}

#endif