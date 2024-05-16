project ('hplip-basic',
         [ 'c', 'cpp' ],
         version : '3.22')
pkg = import('pkgconfig')

# TODO: Configurable options would be nice here
confdir = '/etc/hp'
confdir_options = '-DCONFDIR="' + confdir + '"'
version_options = '-DVERSION=' + meson.project_version()
imageprocessor_options = '-DDISABLE_IMAGEPROCESSOR'

# General dependencies outside of our tree
cupsdep = dependency('cups')
usbdep  = dependency('libusb-1.0')

# We won't build SANE support should we be missing it.
build_sane = false
sanedep = dependency('sane-backends', required: false)
if sanedep.found()
  build_sane = true
endif

jpegdep        = dependency('libjpeg')
cupsfiltersdep = dependency('libcupsfilters')

cupsbindir = cupsdep.get_variable(pkgconfig : 'cups_serverbin' )
cupsfilterdir  = cupsbindir / 'filter'
cupsbackenddir = cupsbindir / 'backend'

# For future consideration:
# hpdiscoverysrc = [ 'protocol/discovery/avahiDiscover.c' ]
# hpdiscovery depends on Avahi and dbus
# It lets us set HAVE_LIBAVAHI in libsane and hpmud
# It's built when --enable-network-build is turned on.
# This also defines HAVE_AVAHI=1 in confdefs.h, but nothing we
#  build seems to need that.

# Include directories. Most of what we're building needs the utilities in common/ and
#  hpmud is very frequently used, so it might as well be here.
common_includes = [ 'common', 'io/hpmud', 'prnt/hpijs' ]

# hpmud depends on hplip.conf, which we will generate from a template
hplipconfdata = configuration_data(
        { 'configure_input' : 'hplip_meson build of HPLIP',
          'abs_datadir'     : get_option('prefix') /
                              get_option('datadir'),
          'VERSION'         : meson.project_version(),
          'scan_build'      : build_sane.to_string(),
          'fax_build'       : 'false',
          'lite_build'      : 'true',
          'cupsfilterdir'   : cupsfilterdir,
          'cupsbackenddir'  : cupsbackenddir })

hplipconf = configure_file(configuration : hplipconfdata,
                           input : 'hplip.conf.in',
                           install : true,
                           install_dir : confdir,
                           output : 'hplip.conf')

# hpmud HP USB multiplexing library
#  Depends on models.dat presence.

# We specifically do not build musb_libusb01.c. Someday we'll check
#  for this, but right now, we don't care as this will be run on
#  exactly one system.
hpmudsrc = [ 'io/hpmud/dot4.c', 'io/hpmud/hpmud.c', 'io/hpmud/jd.c',
             'io/hpmud/mlc.c', 'io/hpmud/model.c', 'io/hpmud/musb.c', 
             'io/hpmud/pml.c', 'io/hpmud/pp.c' ]

hpmudlib = library('hpmud', hpmudsrc,
                   version : meson.project_version(),
                   dependencies : usbdep,
                   include_directories: common_includes,
                   c_args : confdir_options,
                   install : true)
install_headers('io/hpmud/hpmud.h')
install_data('data/models/models.dat',
             install_dir : get_option('datadir') + '/hplip/data/models')
pkg.generate(hpmudlib)

# hpip image processing library
#  Needed by sane_hpaio
if build_sane
  hpipsrc = [ 'ip/ipmain.c', 'ip/xbi2gray.c', 'ip/xchgbpp.c', 'ip/xcolrspc.c',
              'ip/xconvolve.c', 'ip/xcrop.c', 'ip/xfakemono.c', 'ip/xfax.c',
              'ip/xgamma.c', 'ip/xgray2bi.c', 'ip/xgrayout.c', 'ip/xinvert.c',
              'ip/xjpg_dct.c', 'ip/xjpg_dec.c', 'ip/xjpg_enc.c', 'ip/xjpg_fix.c', 
              'ip/xjpg_huf.c', 'ip/xmatrix.c', 'ip/xpad.c', 'ip/xpcx.c', 'ip/xpnm.c',
              'ip/xrotate.c', 'ip/xsaturation.c', 'ip/xscale.c', 'ip/xskel.c',
              'ip/xtable.c', 'ip/xthumb.c', 'ip/xtiff.c', 'ip/xtonemap.c',
              'ip/xyxtract.c' ]

  hpiplib = library('hpip', hpipsrc, install : true,
                    link_args : '-lm', c_args: confdir_options,
                    include_directories : 'ip')
  install_headers('ip/hpip.h')
endif

if build_sane
  # hpipp Internet Printing Protocol library
  #  So far, this is only needed by sane_hpaio
  hpippsrc = [ 'protocol/hp_ipp.c', 'common/utils.c' ]

  hpipplib = library('hpipp', hpippsrc, install : true,
                     dependencies : cupsdep,
                     version : meson.project_version(),
                     link_with: hpmudlib,
                     include_directories : common_includes,
                     c_args : confdir_options)
  install_headers('protocol/hp_ipp.h')
endif

if build_sane
  sane_hpaiosrc = [ 'scan/sane/bb_ledm.c', 'scan/sane/common.c', 'scan/sane/escl.c',
                    'scan/sane/hpaio.c', 'scan/sane/http.c', 'scan/sane/io.c',
                    'scan/sane/ledm.c', 'scan/sane/marvell.c', 'scan/sane/mfpdtf.c',
                    'scan/sane/orblite.c', 'scan/sane/pml.c', 'scan/sane/sanei_init_debug.c',
                    'scan/sane/scl.c', 'scan/sane/sclpml.c', 'scan/sane/soap.c',
                    'scan/sane/soapht.c', 'scan/sane/xml.c', 'common/utils.c' ]

  sane_hpaiolib = library('sane-hpaio', sane_hpaiosrc,
                          version : '1', # this apparently has to be 1 or SANE won't find it
                          dependencies : [ sanedep, cupsdep ],
                          link_with: [ hpmudlib, hpipplib, hpiplib ],
                          install : true,
                          include_directories : [ common_includes, 'ip',
                                                  'protocol' ],
                          gnu_symbol_visibility : 'default',
                          c_args : confdir_options,
                          link_args : [ '-lm', '-ldl' ],
                          install_dir : '/usr/lib/sane')
endif

hpcupssrc = [ 'prnt/hpcups/jccolor.c', 'prnt/hpcups/jdatadbf.c',
              'prnt/hpcups/Utils.cpp', 'prnt/hpcups/SystemServices.cpp',
              'prnt/hpcups/Scaler.cpp', 'prnt/hpcups/RunLenEncoding.cpp',
              'prnt/hpcups/RasterSender.cpp', 'prnt/hpcups/QuickConnect.cpp',
              'prnt/hpcups/Processor.cpp', 'prnt/hpcups/Pipeline.cpp',
              'prnt/hpcups/Pcl3Gui.cpp', 'prnt/hpcups/Pcl3Gui2.cpp', 'prnt/hpcups/Pcl3.cpp',
              'prnt/hpcups/ModeJpeg.cpp', 'prnt/hpcups/ModeJbig.cpp',
              'prnt/hpcups/ModeDeltaPlus.cpp', 'prnt/hpcups/Mode9.cpp',
              'prnt/hpcups/Mode3.cpp', 'prnt/hpcups/Mode2.cpp', 'prnt/hpcups/Mode10.cpp',
              'prnt/hpcups/LJZxStream.cpp', 'prnt/hpcups/LJZjStream.cpp',
              'prnt/hpcups/LJMono.cpp', 'prnt/hpcups/LJJetReady.cpp',
              'prnt/hpcups/LJFastRaster.cpp', 'prnt/hpcups/LJColor.cpp',
              'prnt/hpcups/Lidil.cpp', 'prnt/hpcups/LidilCompress.cpp',
              'prnt/hpcups/Job.cpp', 'prnt/hpcups/HPCupsFilter.cpp',
              'prnt/hpcups/Hbpl1_Wrapper.cpp', 'prnt/hpcups/Hbpl1.cpp',
              'prnt/hpcups/Halftoner.cpp', 'prnt/hpcups/genPCLm.cpp',
              'prnt/hpcups/genJPEGStrips.cpp', 'prnt/hpcups/ErnieFilter.cpp',
              'prnt/hpcups/EncapsulatorFactory.cpp', 'prnt/hpcups/Encapsulator.cpp',
              'prnt/hpcups/dj970ColorMaps.cpp', 'prnt/hpcups/dj8xxColorMaps.cpp',
              'prnt/hpcups/dj600ColorMaps.cpp', 'prnt/hpcups/dj4100ColorMaps.cpp',
              'prnt/hpcups/dj400ColorMaps.cpp', 'prnt/hpcups/dj3600ColorMaps.cpp',
              'prnt/hpcups/dj3320ColorMaps.cpp', 'prnt/hpcups/dbuscomm.cpp',
              'prnt/hpcups/Compressor.cpp', 'prnt/hpcups/ColorMatcher.cpp',
              'prnt/hpcups/BreakTables.cpp', 'common/utils.c' ]

hpcupsexe = executable('hpcups', hpcupssrc, install : true,
                       dependencies : [ cupsdep, jpegdep, cupsfiltersdep ],
                       include_directories : common_includes,
                       cpp_args : [ confdir_options, imageprocessor_options ],
                       c_args : [ confdir_options, imageprocessor_options ],
                       link_args : [ '-lm', '-lz', '-ldl' ],
                       install_dir : cupsfilterdir)

# Copy the PPDs in. We built a tool that helps install these, but they appear
#  pre-built so we just copy them.
install_subdir('ppd/hpcups',
               install_dir : get_option('datadir') / 'ppd/HP',
               strip_directory : true)

# Build the HP backend for CUPS.

hpbackendsrc = [ 'prnt/backend/hp.c', 'common/utils.c' ]
hpbackend = executable('hp', hpbackendsrc, install : true,
                       link_with : hpmudlib,
                       c_args :  [ confdir_options, version_options ],
                       include_directories : common_includes,
                       install_dir : cupsbackenddir)
