mkdir -p output

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
