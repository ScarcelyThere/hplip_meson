project( 'hplip-basic',
         [ 'c', 'cpp' ],
         version: '3.22',
         default_options: 'cpp_std=c++98' )
pkg = import( 'pkgconfig' )

# TODO: Configurable options would be nice here
confdir = '/etc/hp'
confdir_options = '-DCONFDIR="' + confdir + '"'
version_options = '-DVERSION=' + meson.project_version()
imageprocessor_options = '-DDISABLE_IMAGEPROCESSOR'

# General dependencies outside of our tree
cupsdep = dependency( 'cups' )
usbdep  = dependency( 'libusb-1.0' )

# We won't build SANE support should we be missing it.
build_sane = false
sanedep = dependency( 'sane-backends', required: false )
if sanedep.found( )
  build_sane = true
endif

jpegdep        = dependency( 'libjpeg' )
cupsfiltersdep = dependency( 'libcupsfilters' )

cupsbindir = cupsdep.get_variable( pkgconfig : 'cups_serverbin' )
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
          'abs_datadir'     : get_option( 'prefix' ) /
                              get_option( 'datadir' ),
          'VERSION'         : meson.project_version( ),
          'scan_build'      : build_sane.to_string( ),
          'fax_build'       : 'false',
          'lite_build'      : 'true',
          'cupsfilterdir'   : cupsfilterdir,
          'cupsbackenddir'  : cupsbackenddir } )

hplipconf = configure_file( configuration: hplipconfdata,
                            input: 'hplip.conf.in',
                            install: true,
                            install_dir: confdir,
                            output: 'hplip.conf' )

# hpmud HP USB multiplexing library
#  Depends on models.dat presence.

# We specifically do not build musb_libusb01.c. Someday we'll check
#  for this, but right now, we don't care as this will be run on
#  exactly one system.
hpmudsrc = [ 'io/hpmud/dot4.c', 'io/hpmud/hpmud.c', 'io/hpmud/jd.c',
             'io/hpmud/mlc.c', 'io/hpmud/model.c', 'io/hpmud/musb.c', 
             'io/hpmud/pml.c', 'io/hpmud/pp.c' ]

hpmudlib = library( 'hpmud', hpmudsrc,
                    version: meson.project_version( ),
                    dependencies: usbdep,
                    include_directories: common_includes,
                    c_args: confdir_options,
                    install: true )
install_headers( 'io/hpmud/hpmud.h' )
install_data( 'data/models/models.dat',
              install_dir: get_option( 'datadir' ) + '/hplip/data/models' )
pkg.generate( hpmudlib )

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

  hpiplib = library( 'hpip', hpipsrc, install: true,
                     link_args : '-lm', c_args: confdir_options,
                     include_directories: 'ip' )
  install_headers( 'ip/hpip.h' )
endif

if build_sane
  # hpipp Internet Printing Protocol library
  #  So far, this is only needed by sane_hpaio
  hpippsrc = [ 'protocol/hp_ipp.c', 'common/utils.c' ]

  hpipplib = library( 'hpipp', hpippsrc, install: true,
                      dependencies: cupsdep,
                      version: meson.project_version( ),
                      link_with: hpmudlib,
                      include_directories: common_includes,
                      c_args: confdir_options )
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
                          version: '1', # this apparently has to be 1 or SANE won't find it
                          dependencies: [ sanedep, cupsdep ],
                          link_with: [ hpmudlib, hpipplib, hpiplib ],
                          install: true,
                          include_directories: [ common_includes, 'ip',
                                                 'protocol' ],
                          gnu_symbol_visibility: 'default',
                          c_args: confdir_options,
                          link_args: [ '-lm', '-ldl' ],
                          install_dir: '/usr/lib/sane' )
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

hpcupsexe = executable( 'hpcups', hpcupssrc, install: true,
                        dependencies: [ cupsdep, jpegdep, cupsfiltersdep ],
                        include_directories: common_includes,
                        cpp_args: [ confdir_options, imageprocessor_options ],
                        c_args: [ confdir_options, imageprocessor_options ],
                        link_args: [ '-lm', '-lz', '-ldl' ],
                        install_dir: cupsfilterdir )

# Copy the PPDs in. We built a tool that helps install these, but they appear
#  pre-built so we just copy them.
install_subdir( 'ppd/hpcups',
                install_dir: get_option( 'datadir' ) / 'ppd/HP',
                strip_directory: true )

# Build the HP backend for CUPS.

hpbackendsrc = [ 'prnt/backend/hp.c', 'common/utils.c' ]

hpbackend = executable( 'hp', hpbackendsrc, install: true,
                        link_with: hpmudlib,
                        c_args:  [ confdir_options, version_options ],
                        include_directories: common_includes,
                        install_dir: cupsbackenddir )

# Build the HPIJS GhostScript driver, should the user want it.
if get_option( 'hpijs' ).enabled( )
  hpijssrc = [ 'common/utils.c',
               'prnt/hpijs/apollo21xx.cpp', 'prnt/hpijs/apollo2560.cpp', 
               'prnt/hpijs/apollo2xxx.cpp', 'prnt/hpijs/breaks_open.cpp', 
               'prnt/hpijs/capture.cpp', 'prnt/hpijs/colormatch.cpp', 
               'prnt/hpijs/colormatcher_open.cpp', 'prnt/hpijs/compression.cpp', 
               'prnt/hpijs/context2.cpp', 'prnt/hpijs/create_so.cpp', 
               'prnt/hpijs/creator.cpp', 'prnt/hpijs/dj3320.cpp', 
               'prnt/hpijs/dj3320_cmap.cpp', 'prnt/hpijs/dj350.cpp', 
               'prnt/hpijs/dj3600.cpp', 'prnt/hpijs/dj3600_cmap.cpp', 
               'prnt/hpijs/dj4100_cmap.cpp', 'prnt/hpijs/dj540.cpp', 
               'prnt/hpijs/dj600.cpp', 'prnt/hpijs/dj600_maps.cpp', 
               'prnt/hpijs/dj630.cpp', 'prnt/hpijs/dj660.cpp', 
               'prnt/hpijs/dj660_maps.cpp', 'prnt/hpijs/dj690.cpp', 
               'prnt/hpijs/dj690_maps.cpp', 'prnt/hpijs/dj6xx.cpp', 
               'prnt/hpijs/dj850.cpp', 'prnt/hpijs/dj850_maps.cpp', 
               'prnt/hpijs/dj890.cpp', 'prnt/hpijs/dj895_maps.cpp', 
               'prnt/hpijs/dj895_maps2.cpp', 'prnt/hpijs/dj8x5.cpp', 
               'prnt/hpijs/dj8xx.cpp', 'prnt/hpijs/dj970_maps.cpp', 
               'prnt/hpijs/dj970_maps2.cpp', 'prnt/hpijs/dj970_maps3.cpp', 
               'prnt/hpijs/dj9xx.cpp', 'prnt/hpijs/dj9xxvip.cpp', 
               'prnt/hpijs/djgenericvip.cpp', 'prnt/hpijs/filterhpa.cpp', 
               'prnt/hpijs/globals.cpp', 'prnt/hpijs/halftoner.cpp', 
               'prnt/hpijs/halftoner_open.cpp', 'prnt/hpijs/header2.cpp', 
               'prnt/hpijs/hpijs.cpp', 'prnt/hpijs/hpiom.c', 
               'prnt/hpijs/htmtxhi.cpp', 'prnt/hpijs/ijs.c', 
               'prnt/hpijs/ijs_server.c', 'prnt/hpijs/jccolor.c', 
               'prnt/hpijs/jdatadbf.c', 'prnt/hpijs/job.cpp', 
               'prnt/hpijs/ljcolor.cpp', 'prnt/hpijs/ljfastraster.cpp', 
               'prnt/hpijs/ljjetready.cpp', 'prnt/hpijs/ljm1005.cpp', 
               'prnt/hpijs/ljmono.cpp', 'prnt/hpijs/ljzjs.cpp', 
               'prnt/hpijs/ljzjscolor.cpp', 'prnt/hpijs/ljzjsmono.cpp', 
               'prnt/hpijs/models.cpp', 'prnt/hpijs/phobos_cmaps.cpp', 
               'prnt/hpijs/pmselect.cpp', 'prnt/hpijs/printer.cpp', 
               'prnt/hpijs/printerfactory.cpp', 'prnt/hpijs/printerproxy.cpp', 
               'prnt/hpijs/psp100.cpp', 'prnt/hpijs/quickconnect.cpp', 
               'prnt/hpijs/registry.cpp', 'prnt/hpijs/scaler.cpp', 
               'prnt/hpijs/scaler_open.cpp', 'prnt/hpijs/script.cpp', 
               'prnt/hpijs/services.cpp', 'prnt/hpijs/systemservices.cpp', 
               'prnt/hpijs/translator.cpp', 'prnt/hpijs/version.cpp', 
               'prnt/hpijs/versioncode.cpp',
             ]
  # These are for faxing, I'm guessing.
  #             'prnt/hpijs/hpcupsfax.cpp',
  #             'prnt/hpijs/hpijsfax.cpp' ]

  apdk_options = [ '-DAPDK_AUTODUPLEX', '-DAPDK_EXTENDED_MEDIASIZE',
                   '-DHAVE_STDINT_H', '-DAPDK_AUTO_INCLUDE',
                   '-DVERSION=' + meson.project_version( ) ]
  hpijsexe = executable( 'hpijs', hpijssrc, install: true,
                         dependencies: [ cupsdep, jpegdep, cupsfiltersdep ],
                         include_directories: common_includes,
                         cpp_args: [ confdir_options, apdk_options ],
                         c_args: [ confdir_options ],
                         link_args: [ '-lm', '-lz', '-ldl' ],
                         install_dir: cupsfilterdir )
endif
