#!/bin/bash
set -e

# Setup directories
mkdir -p output/gerbers output/bom output/pdf

build_panel() {
    echo "==> Generating Panel with KiKit..."
    docker run --rm \
      --user $(id -u):$(id -g) \
      -v $(pwd):/work \
      -w /work \
      yaqwsx/kikit \
      panelize \
        --layout 'grid; rows: 2; cols: 7; space: 0mm; rotation: 180deg; alternation: rows;' \
        --cuts 'type: vcuts;' \
        --framing 'type: railstb; width: 5mm;' \
        --tooling 'type: 4hole; hoffset: 5mm; voffset: 2.5mm; size: 2mm;' \
        --fiducials 'type: 3fid; hoffset: 12mm; voffset: 2.5mm; coppersize: 1mm; opening: 2mm;' \
        --post 'copperfill: true;' \
        BlampKnob.kicad_pcb output/BlampKnobPanel.kicad_pcb
}

build_pdf() {
    echo "==> Exporting Schematic PDF..."
    kicad-cli sch export pdf --output output/pdf/BlampKnob-schematic.pdf BlampKnob.kicad_sch
}

build_bom() {
    echo "==> Exporting BOM..."
    kicad-cli sch export bom --output output/bom/BlampKnob-BOM.csv BlampKnob.kicad_sch
}

build_gerbers() {
    echo "==> Exporting Panel Gerbers & Drills..."
    kicad-cli pcb export gerbers --output output/gerbers/ output/BlampKnobPanel.kicad_pcb
    kicad-cli pcb export drill --output output/gerbers/ output/BlampKnobPanel.kicad_pcb

    echo "==> Zipping Gerber Package..."
    cd output/gerbers && zip -r ../BlampKnobPanel-Gerbers.zip . && cd ../..
}

clean() {
    echo "==> Cleaning output directory..."
    rm -rf output/*
}

# Command Routing
case "$1" in
    panel)      build_panel ;;
    pdf)        build_pdf ;;
    bom)        build_bom ;;
    gerbers)    build_panel; build_gerbers ;; # Gerbers require panel to exist
    clean)      clean ;;
    all|"")
        clean
        mkdir -p output/gerbers output/bom output/pdf
        build_panel
        build_pdf
        build_bom
        build_gerbers
        echo "==> Success! All build artifacts compiled in output/"
        ;;
    *)
        echo "Usage: $0 {panel|pdf|bom|gerbers|clean|all}"
        exit 1
        ;;
esac
