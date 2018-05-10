#!/bin/bash

# convenience script to add release information to appstream data
# in case upstream forgets to / does not want to update it

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 VERSION YYYY-MM-DD"
  exit 1
fi

APPSTREAM_FILE=$FLATPAK_DEST/share/metainfo/$FLATPAK_ID.appdata.xml
APPDATA_FILE=$FLATPAK_DEST/share/appdata/$FLATPAK_ID.appdata.xml

if [ ! -f $APPSTREAM_FILE ]; then
  if [ -f $APPDATA_FILE ]; then
    $APPSTREAM_FILE=$APPDATA_FILE
  else
    echo "$0 error: no appstream data found in $FLATPAK_DEST/share!"
    exit 1
  fi
fi

# in case more than one release is missing the history would be incomplete, so delete everything
sed -i '/<releases/,/\/releases>/d' $APPSTREAM_FILE

sed -i "s:</component>:<releases>\n<release version=\"$1\" date=\"$2\"/>\n</releases>\n</component>:" $APPSTREAM_FILE
