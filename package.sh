#!/bin/bash

cmake -B build --toolchain toolchain_mingw.cmake
make -C build

mkdir -p package
cp build/*.exe package

export DLLS=`peldd package/*.exe -t --ignore-errors`
for DLL in $DLLS
    do cp "$DLL" package
done

mkdir -p package/share/{themes,gtk-3.0,glib-2.0}
cp -r $GTK_INSTALL_PATH/share/glib-2.0/schemas package/share/glib-2.0/
cp -r $GTK_INSTALL_PATH/share/icons package/share/icons

cat <<-EOF > package/share/gtk-3.0/settings.ini
[Settings]
gtk-font-name = Segoe UI 10
gtk-xft-rgba = rgb
gtk-xft-antialias = 1
EOF

find package -maxdepth 1 -type f -exec mingw-strip {} +
