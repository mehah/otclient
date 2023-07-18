#if (__ANDROID_API__ > 19)
#include <android/api-level.h>
#include <android/log.h>
#include <signal.h>
#include <dlfcn.h>

extern "C" {
	typedef __sighandler_t(*bsd_signal_func_t)(int, __sighandler_t);
	bsd_signal_func_t bsd_signal_func = NULL;

	__sighandler_t bsd_signal(int s, __sighandler_t f)
	{
		if (bsd_signal_func == NULL) {
			// For now (up to Android 7.0) this is always available 
			bsd_signal_func = (bsd_signal_func_t)dlsym(RTLD_DEFAULT, "bsd_signal");

			if (bsd_signal_func == NULL) {
				// You may try dlsym(RTLD_DEFAULT, "signal") or dlsym(RTLD_NEXT, "signal") here
				// Make sure you add a comment here in StackOverflow
				// if you find a device that doesn't have "bsd_signal" in its libc.so!!!

				__android_log_assert("", "bsd_signal_wrapper", "bsd_signal symbol not found!");
			}
		}

		return bsd_signal_func(s, f);
	}
}
#endif