#!/bin/sh

uncrustify -q -c ./config/uncrustify.cfg ./CZPhotoPickerController/*.h ./CZPhotoPickerController/*.m --replace --no-backup

