# SPDX-License-Identifier: GPL-2.0-or-later
%global dkms_name openrazer-driver
%if 0%{?suse_version}
%global dbus_python dbus-1-python3
%global group_tools shadow
%else
%global dbus_python python3-dbus
%global group_tools shadow-utils
%endif
%if 0%{?mageia}
%global gobject_python python3-gobject3
%global dkms_flags --rpm_safe_upgrade
%else
%global gobject_python python3-gobject
%endif

Name:           openrazer-meta
Version:        3.12.4.20261120
Release:        1%{?dist}
Summary:        OpenRazer Basilisk V4 Pro test build
License:        GPL-2.0-or-later
URL:            https://github.com/ashrynsilkstone-ui/openrazer-basilisk-v4-pro
Source0:        openrazer-%{version}.tar.xz
BuildArch:      noarch
BuildRequires:  make
BuildRequires:  python3-devel
BuildRequires:  python3-setuptools
Requires:       openrazer-kernel-modules-dkms = %{version}-%{release}
Requires:       openrazer-daemon = %{version}-%{release}
Requires:       python3-openrazer = %{version}-%{release}

%description
Installs the driver, daemon and Python client for the OpenRazer Basilisk V4 Pro test build.

%package -n openrazer-kernel-modules-dkms
Summary:        DKMS module sources for the OpenRazer Basilisk V4 Pro test build
Provides:       openrazer-driver-dkms = %{version}-%{release}
Conflicts:      openrazer-driver-dkms < %{version}-%{release}
Requires:       dkms
Requires:       make
Requires:       udev
Requires(pre):  %{group_tools}
Requires(preun): dkms
Requires(posttrans): dkms

%description -n openrazer-kernel-modules-dkms
Builds the OpenRazer kernel modules against the installed kernel headers via DKMS.

%package -n openrazer-daemon
Summary:        D-Bus daemon for the OpenRazer Basilisk V4 Pro test build
Requires:       openrazer-kernel-modules-dkms = %{version}-%{release}
Requires:       %{dbus_python}
Requires:       %{gobject_python}
Requires:       python3-daemonize
Requires:       python3-pyudev
Requires:       python3-setproctitle
Requires:       xautomation
%if 0%{?suse_version}
Requires:       typelib(Gdk) = 3.0
%endif

%description -n openrazer-daemon
Provides the OpenRazer D-Bus interface for configuration and device status.

%package -n python3-openrazer
Summary:        Python client for the OpenRazer Basilisk V4 Pro test build
Requires:       openrazer-daemon = %{version}-%{release}
Requires:       %{dbus_python}
Requires:       %{gobject_python}
Requires:       python3-numpy

%description -n python3-openrazer
Python bindings for the OpenRazer daemon.

%prep
%setup -q -n openrazer-%{version}

%build

%install
make DESTDIR="%{buildroot}" setup_dkms udev_install appstream_install
make -C daemon DESTDIR="%{buildroot}" install-resources install-systemd manpages
for project in daemon pylib; do
    (
        cd "$project"
        %{__python3} setup.py install --root="%{buildroot}" --prefix="%{_prefix}" \
            --install-lib="%{python3_sitelib}" --no-compile
    )
done

%pre -n openrazer-kernel-modules-dkms
getent group plugdev >/dev/null || groupadd -r plugdev

%posttrans -n openrazer-kernel-modules-dkms
# Register even on a system whose running kernel is different from the installed kernel.
if [ -z "$(dkms status -m %{dkms_name} -v %{version})" ]; then
    dkms add -m %{dkms_name} -v %{version} %{?dkms_flags} || exit $?
fi
for tree in /lib/modules/*; do
    [ -d "$tree/build" ] || continue
    dkms install -m %{dkms_name} -v %{version} -k "${tree##*/}" %{?dkms_flags} || exit $?
done
echo 'Add your desktop user to the plugdev group and log in again.'

%preun -n openrazer-kernel-modules-dkms
if [ -n "$(dkms status -m %{dkms_name} -v %{version})" ]; then
    dkms remove -m %{dkms_name} -v %{version} --all %{?dkms_flags}
fi

%files
%license LICENSES/GPL-2.0-or-later.txt

%files -n openrazer-kernel-modules-dkms
%license LICENSES/GPL-2.0-or-later.txt
%{_prefix}/src/%{dkms_name}-%{version}/
%{_prefix}/lib/udev/razer_mount
%{_prefix}/lib/udev/rules.d/99-razer.rules

%files -n openrazer-daemon
%license LICENSES/GPL-2.0-or-later.txt
%{_bindir}/openrazer-daemon
%{python3_sitelib}/openrazer_daemon/
%{python3_sitelib}/openrazer_daemon-*.egg-info/
%{_datadir}/dbus-1/services/org.razer.service
%{_datadir}/metainfo/io.github.openrazer.openrazer.metainfo.xml
%{_datadir}/openrazer/
%{_prefix}/lib/systemd/user/openrazer-daemon.service
%{_mandir}/man5/razer.conf.5*
%{_mandir}/man8/openrazer-daemon.8*

%files -n python3-openrazer
%license LICENSES/GPL-2.0-or-later.txt
%{python3_sitelib}/openrazer/
%{python3_sitelib}/openrazer-*.egg-info/
