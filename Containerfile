ARG CORE_BRANCH=main
ARG SUFFIX=
ARG DESKTOP=nogui

FROM ghcr.io/commonarch/system-base${SUFFIX}-${DESKTOP}:main

ARG CORE_BRANCH=main
ARG VARIANT=general
ARG DESKTOP=nogui

# Include blendOS packages

RUN <<EOF
cat >>/etc/pacman.conf <<EOT

[breakfast]
SigLevel = Never
Server = https://pkg-repo.blendos.co/archive/2025-04-24-15-00-08/
EOT
EOF

RUN if [ "$VARIANT" = 'waydroid' ] || [ "$VARIANT" = 'nvidia-waydroid' ]; then install-packages-build waydroid waydroid-image; yes | pacman -Scc; fi

RUN install-packages-build openssh curl wget git blend blend-settings blendos-wallpapers ptyxis; yes | pacman -Scc

RUN systemctl --global enable blend-files

# DE tweaks

RUN <<EOF
if [ "$DESKTOP" = gnome ]; then
    pacman -Rcns --noconfirm gnome-console gnome-tour

    find /usr/share/metainfo \
        ! -name "org.freedesktop.appstream.cli.metainfo.xml" \
        ! -name "org.freedesktop.appstream.compose.metainfo.xml" \
        ! -name "org.gnome.Software.Plugin.Flatpak.metainfo.xml" \
        ! -name "org.gnome.Software.Plugin.Fwupd.metainfo.xml" -type f -exec rm -f {} +
elif [ "$DESKTOP" = plasma ]; then
    pacman -Rcns --noconfirm konsole yakuake
    pacman -Rcns --noconfirm plasma-welcome

    install-packages-build spectacle
fi

rm -f /usr/share/applications/stoken-gui.desktop
rm -f /usr/share/applications/stoken-gui-small.desktop
rm -f /usr/share/applications/qvidcap.desktop
rm -f /usr/share/applications/qv4l2.desktop
rm -f /usr/share/applications/bvnc.desktop
rm -f /usr/share/applications/electron*.desktop
rm -f /usr/share/applications/avahi-discover.desktop
rm -f /usr/share/applications/bssh.desktop
rm -f /usr/share/applications/Waydroid.desktop
rm -f /usr/share/applications/waydroid*.desktop

gtk-update-icon-cache

if [ "$VARIANT" = nvidia ]; then
    install-packages-build nvidia-settings nvidia-prime

    echo >> /etc/default/grub
    echo 'GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} nvidia_drm.modeset=1"' >> /etc/default/grub

    mkdir -p /etc/modprobe.d
    echo 'options nvidia "NVreg_PreserveVideoMemoryAllocations=1"' > /etc/modprobe.d/nvidia.conf

    systemctl enable nvidia-suspend nvidia-hibernate nvidia-resume
fi

yes | pacman -Scc
EOF

COPY overlays/common overlay[s]/${DESKTOP} /

RUN glib-compile-schemas /usr/share/glib-2.0/schemas || true

RUN rm -f /.gitkeep
