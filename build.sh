#!/bin/bash
set -e

# Auto-detect KiCad project name from .kicad_pro file
PRO_FILE=(*.kicad_pro)

if [ ! -f "${PRO_FILE[0]}" ]; then
    echo "Error: No .kicad_pro file found in $(pwd)"
    exit 1
fi

PROJECT_NAME="${PRO_FILE[0]%.kicad_pro}"

echo "==> Building Single Board: ${PROJECT_NAME}..."

# Setup directories
mkdir -p output/gerbers output/assembly output/pdf

build_pdf() {
    echo "==> Exporting Schematic PDF..."
    kicad-cli sch export pdf --output "output/pdf/${PROJECT_NAME}-schematic.pdf" "${PROJECT_NAME}.kicad_sch"
}

build_bom() {
    echo "==> Exporting BOM..."
    kicad-cli sch export bom \
      --output "output/assembly/${PROJECT_NAME}-BOM.csv" \
      --fields "QUANTITY,Reference,Value,Footprint,MFG PN,Description" \
      --labels "Qty,Designators,Value,Footprint,MPN,Description" \
      --group-by "Value,Footprint,MFG PN" \
      --ref-delimiter ", " \
      --ref-range-delimiter "-" \
      --exclude-dnp \
      "${PROJECT_NAME}.kicad_sch"
}

build_pos() {
    echo "==> Exporting Assembly Positions (POS)..."
    kicad-cli pcb export pos \
      --output "output/assembly/${PROJECT_NAME}-POS.csv" \
      --format csv \
      --units mm \
      --side both \
      --use-drill-file-origin \
      "${PROJECT_NAME}.kicad_pcb"
}

build_gerbers() {
    echo "==> Exporting Gerbers & Drills..."
    kicad-cli pcb export gerbers --output output/gerbers/ "${PROJECT_NAME}.kicad_pcb"
    kicad-cli pcb export drill --output output/gerbers/ "${PROJECT_NAME}.kicad_pcb"

    echo "==> Zipping Gerber Package..."
    (cd output/gerbers && zip -r "../${PROJECT_NAME}-Gerbers.zip" . > /dev/null)
}

clean() {
    echo "==> Cleaning output directory..."
    rm -rf output/*
}

# Command Routing
case "$1" in
    pdf)        build_pdf ;;
    bom)        build_bom ;;
    pos)        build_pos ;;
    gerbers)    build_gerbers ;;
    clean)      clean ;;
    all|"")
        clean
        mkdir -p output/gerbers output/assembly output/pdf

        build_pdf
        build_bom
        build_pos
        build_gerbers

        echo "==> Zipping Assembly Package..."
        (cd output/assembly && zip -r "../${PROJECT_NAME}-Assembly.zip" . > /dev/null)

        echo "==> Success! All build artifacts compiled in output/"
        ;;
    *)
        echo "Usage: $0 {pdf|bom|pos|gerbers|clean|all}"
        exit 1
        ;;
esac
