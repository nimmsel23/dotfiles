#!/bin/bash
hyprctl workspaces -j > ~/.cache/hypr-session.json
hyprctl clients -j >> ~/.cache/hypr-session.json

