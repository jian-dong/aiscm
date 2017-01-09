# aiscm (0.9.2-1)

* test/test_ffmpeg.scm: extract pixel value earlier in test
* aiscm/jit.scm: compile code to allocate return values
* support for native constants
* working on tensor expressions


# aiscm (0.9.1-1)

* aiscm/jit.scm: compile code to allocate return values
* support for native constants
* working on tensor expressions


# aiscm (0.8.3-1)

* object rgb and object complex values
* refactored native method calls
* improved docker build


# aiscm (0.8.2-1)

* temporarily match floating point numbers to objects


# aiscm (0.8.1-1)

* refactored type conversions
* type conversions of method arguments


# aiscm (0.7.1-1)

* doc/installation.md: updated installation documentation
* aiscm/aiscm.xpm: added installation documentation
* FFmpeg network stream example
* better test video
* use re-export statements to make modules more independent
* use read-image, read-audio, write-image, and write-audio throughout
* renamed "match" to "native-type"


# aiscm (0.6.2-2)

* Make releases for different distros


# aiscm (0.6.2-1)

* fix package dependencies (do not use aliases)


# aiscm (0.6.1-1)

* Pulse audio input and output using asynchronous API
* ring buffer for first-in first-out (FIFO) buffering of data
* improved documentation


# aiscm (0.5.1-1)

* aiscm/ffmpeg.scm: reading video/audio files using FFmpeg
* aiscm/pulse.c: initialise "error" integer to PA_OK
* aiscm/util.scm: synchronisation method for audio-video-synchronisation
* aiscm/v4l2.c: refactor video capture code a bit
* Dockerfile: Docker build for Debian Jessie/Sid, Ubuntu Trusty/Xenial
* aiscm/xorg.scm: use XVideo as default for single-window videos
* updated documentation


# aiscm (0.4.2-1)

* compose RGB and complex values from arrays
* added some documentation
* aiscm/jit.scm: refactored dispatching code


# aiscm (0.4.1-1)

* refactored jit compiler
* aiscm/jit.scm: tensor implementation (WIP)


# aiscm (0.3.1-1)

* aiscm/asm.scm: support for CMOVcc
* aiscm/jit.scm: major and minor number, =0, !=0, &&, ||
* aiscm/complex.scm: support for complex numbers
* aiscm/magick.scm: loading and saving of images via ImageMagick
* aiscm/pulse.scm: Pulse audio I/O
* n-ary operations &&, ||


# aiscm (0.2.3-1)

* aiscm/jit.scm: refactored code
* aiscm/asm.scm: support for AH, CH, DH, and BH
* aiscm/xorg.scm: display lists of images and videos with multiple channels
* wrap variables in order to support boolean
* integer remainder of division
* RGB operations


# aiscm (0.2.2-1)

* aiscm/xorg.scm: convert array to image before displaying
* aiscm/rgb.scm: support for RGB values
* aiscm/jit.scm: spill predefined registers if they are blocked
* changed garbage collector settings for benchmark


# aiscm (0.2.1-1)

* aiscm/jit.scm: code fragments
* aiscm/op.scm: array operators based on code fragments
* block regions for reserving registers
* integer division
* boolean operations


# aiscm (0.1.8-1)

* IDIV and DIV using blocked registers
* Shortcuts 'seq' and 'arr'
* Boolean operations for arrays
* Added benchmark


# aiscm (0.1.7-1)

* Packaging new version


# aiscm (0.1.6-2)

* Initial release.
* Updated dependencies.