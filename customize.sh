SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=true

# Print to Magisk installer UI
ui_print "Starting Minecraft Font Module installation"

# Module paths
TTF_SRC="$MODPATH/Minecraft.ttf"
FONTDIR="$MODPATH/system/fonts"

# Check if Minecraft.ttf exists
if [ ! -f "$TTF_SRC" ]; then
  ui_print "Error: Minecraft.ttf not found in module root"
  exit 1
fi

# Create fonts directory
mkdir -p "$FONTDIR"
ui_print "Created fonts directory at $FONTDIR"

# Function to detect default font family from fonts.xml
get_default_font() {
  FONTS_XML="/system/etc/fonts.xml"
  if [ -f "$FONTS_XML" ]; then
    # Extract the first family name (usually default sans-serif)
    DEFAULT_FAMILY=$(grep -m 1 '<family name="' "$FONTS_XML" | sed 's/.*name="\([^"]*\)".*/\1/')
    if [ -z "$DEFAULT_FAMILY" ]; then
      DEFAULT_FAMILY="sans-serif"
      ui_print "No family name found in fonts.xml, assuming sans-serif"
    else
      ui_print "Detected font family: $DEFAULT_FAMILY"
    fi
  else
    DEFAULT_FAMILY="sans-serif"
    ui_print "fonts.xml not found, assuming sans-serif"
  fi
}

# Function to find the primary TTF file for the default font
get_default_ttf() {
  FONTS_XML="/system/etc/fonts.xml"
  if [ -f "$FONTS_XML" ]; then
    # Look for the first TTF file for the default family (typically Regular)
    DEFAULT_TTF=$(awk "/<family name=\"$DEFAULT_FAMILY\"/,/<\/family>/" "$FONTS_XML" | grep '<font ' | grep -m 1 -E 'weight="400" style="normal"' | sed 's/.*>\([^<]*\)<\/font>.*/\1/' | cut -d'>' -f2)
    if [ -z "$DEFAULT_TTF" ]; then
      # Fallback to any TTF in the family
      DEFAULT_TTF=$(awk "/<family name=\"$DEFAULT_FAMILY\"/,/<\/family>/" "$FONTS_XML" | grep '<font ' | sed 's/.*>\([^<]*\)<\/font>.*/\1/' | head -n 1 | cut -d'>' -f2)
    fi
    if [ -z "$DEFAULT_TTF" ]; then
      DEFAULT_TTF="Roboto-Regular.ttf"
      ui_print "No TTF found for $DEFAULT_FAMILY, falling back to $DEFAULT_TTF"
    else
      ui_print "Detected default TTF: $DEFAULT_TTF"
    fi
  else
    DEFAULT_TTF="Roboto-Regular.ttf"
    ui_print "fonts.xml not found, falling back to $DEFAULT_TTF"
  fi
}

# Function to copy Minecraft.ttf to replace the default font
replace_font() {
  # Copy Minecraft.ttf to FONTDIR with the default TTF name
  cp "$TTF_SRC" "$FONTDIR/$DEFAULT_TTF"
  if [ $? -eq 0 ]; then
    ui_print "Copied Minecraft.ttf to $FONTDIR/$DEFAULT_TTF"
  else
    ui_print "Error: Failed to copy Minecraft.ttf to $FONTDIR/$DEFAULT_TTF"
    exit 1
  fi
}

# Main execution
ui_print "Detecting default system font"

# Detect default font family
get_default_font

# Find the primary TTF file
get_default_ttf

# Replace the default font
replace_font

# Set permissions
ui_print "Setting permissions for font files"
set_perm_recursive "$FONTDIR" 0 0 0755 0644
set_perm "$FONTDIR/$DEFAULT_TTF" 0 0 0644

ui_print "Minecraft Font Module installation complete"
exit 0
