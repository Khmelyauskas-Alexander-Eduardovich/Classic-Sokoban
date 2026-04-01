QT += qml svg gui core sql quick

CONFIG += c++11

# Оставляем ресурсы и исходники как есть
RESOURCES += qml.qrc
SOURCES += main.cpp

# --- ПРАВИЛЬНЫЕ ПУТИ УСТАНОВКИ ---

# 1. Забираем ВСЮ папку assets целиком (это надежнее, чем перечислять файлы)
assets_data.files = assets/*
assets_data.path = /assets

# 2. Файлы QML
qml_files.path = /qml
qml_files.files = qml/main.qml qml/levels.js

# 3. Системные файлы Ubuntu Touch
desktop.path = /
desktop.files = sokoban-classic.desktop

manifest.path = /
manifest.files = manifest.json

apparmor.path = /
apparmor.files = sokoban-classic.apparmor

# 4. Исполняемый файл (бинарник)
target.path = /

# --- ФИНАЛЬНЫЙ СПИСОК (БЕЗ ОПЕЧАТОК) ---
INSTALLS += target desktop manifest apparmor assets_data qml_files
