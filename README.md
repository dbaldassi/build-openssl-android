# Build openssl for Android

This script is intended to build openssl as a static library
for android, for all the following architectures :

* arm
* arm64
* x86
* x86_64

To use, just run ``./build.sh -n /path_to/android_ndk`` with the path
to your ndk installation.

Obviously, you need to download and install the [android ndk](https://developer.android.com/ndk/) first.

For more info, open the help with ``./build.sh -h``, to set parameters like
the openssl version, the android api ...