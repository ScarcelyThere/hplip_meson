HPLIP Basic
===========

Why?
----
Do you own an older USB-only Hewlett-Packard all-in-one scanner-copier-printer
you like to use on your favorite UN*X? Do you do all your printing through CUPS?
Do you build HP's HPLIP package with `--enable-hpcups-only-build` and wish it
included SANE support without the network printing, graphical utility, and Wi-Fi setup utilities
you never use?

If you answered "yes," you might like this!

What?
-----
You will be able to scan from your favorite SANE application and print via CUPS.
That's about it. I've only tested this on a DeskJet F4190.

This `meson.build` will compile:

* the `libhpmud` library and its required `models.dat` file,
* the `hp` CUPS backend,
* the `libhpipp` Internet Printing Protocol library and `libhpip`
  image-processing library, required by `libsane-hpaio`,
* the new hpcups CUPS filter, along with its requisite PPD files,
* `libsane-hpaio` for SANE support, and
* a very basic `hplip.conf`.

Dependencies
------------
* SANE
* CUPS
* libjpeg
* libusb 1.0

What You Don't Get
------------------
* Network printing.
* Wi-Fi configuration.
* Graphical utilities or a system tray service.
* Firmware updates on supported devices.

To Do
-----
* Add actual configuration flags.
