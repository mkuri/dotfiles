#!/usr/bin/bash
# GNOME settings for Ubuntu 26.04. Safe to run again.

# Papers (PDF viewer): open maximized, two pages side by side. Papers writes
# its last used view back to these keys, so they only set the starting point.
gsettings set org.gnome.Papers.Default window-maximized true
gsettings set org.gnome.Papers.Default dual-page true
gsettings set org.gnome.Papers.Default sizing-mode 'automatic'
