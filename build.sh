#!/bin/bash

# --- СКРИПТ СБОРКИ SOKOBAN ---

echo "Voleu eliminar la carpeta 'build'? (Si/No)"
read -p "> " answer

if [[ "$answer" == [Ss]* ]]; then
    echo "S'està eliminant la carpeta build..."
    sudo rm -rf build
fi

echo "---"
echo "Per a quina arquitectura voleu construir l'aplicació?"
echo "1) arm64 (Fairphone / moderns)"
echo "2) armhf (mòbils antics)"
echo "3) amd64 (escriptori / desktop)"
echo "4) Tots tres (arm64, armhf, amd64)"
echo "5) Arquitectura 'all' (només QML)"
read -p "Tria una opció (1-5): " arch_choice

case $arch_choice in
    1)
        sudo clickable build --arch arm64
        ;;
    2)
        sudo clickable build --arch armhf
        ;;
    3)
        sudo clickable build --arch amd64
        ;;
    4)
        echo "Construint per a totes les arquitectures..."
        sudo clickable build --arch arm64 && \
        sudo clickable build --arch armhf && \
        sudo clickable build --arch amd64
        ;;
    5)
        sudo clickable build -a all
        ;;
    *)
        echo "Opció no vàlida. Sortint..."
        exit 1
        ;;
esac

echo "---"
echo "Procés finalitzat! ::)"
