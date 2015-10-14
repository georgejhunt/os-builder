# sugar desktop
sugar
sugar-base
sugar-toolkit
sugar-toolkit-gtk3

# sugar control panels
sugar-cp-backup
sugar-cp-datetime
sugar-cp-frame
sugar-cp-language
sugar-cp-modemconfiguration
sugar-cp-network
sugar-cp-power
sugar-cp-updater
sugar-cp-background
sugar-cp-webaccount

# additional sugar packages
dconf
webkitgtk3
espeak
etoys
evince-djvu
gtksourceview2
gvfs
libffi
numpy
csound
csound-python
pygame
python-alsaaudio
squeak-vm

# sugar backgrounds from German Ruiz
# used by sugar-cp-background
sugar-backgrounds

# FIXME: missing dependencies in sugar-cp-modemconfiguration
# won't be fixed in an upstream package until Fedora 21,
# see #12828, SL:#4784, BZ:#1146534
mobile-broadband-provider-info

# Browse
gnash-plugin
totem-mozplugin

# Record, Measure, and Jukebox
gstreamer-python

# Terminal
vte3
python-simplejson

# dependencies for Epub support in Read
python-BeautifulSoup
olpc-library

# for Tuxmath activity
SDL_Pango

# for Physics
pybox2d

# for text-to-speech in Read
gstreamer-plugins-espeak

# explicitly specify dependencies on GNOME's implementation of certain
# components, otherwise the KDE ones will be brought in by default
PolicyKit-gnome
notification-daemon

# standard part of PyGTK, used by some activities (#11053)
pygtk2-libglade

# between Fedora 18 and Fedora 20, the abiword packagers broke out the
# python support into a new package, and Sugar does not depend on it
# (#12809).
#python-abiword
