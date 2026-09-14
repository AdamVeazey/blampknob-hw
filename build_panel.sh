#!/bin/bash
set -e

PRO_FILE=(*.kicad_pro)
if [ ! -f "${PRO_FILE[0]}" ]; then
    echo "Error: No .kicad_pro file found in $(pwd)"
    exit 1
fi

PROJECT_NAME="${PRO_FILE[0]%.kicad_pro}"
PANEL_NAME="${PROJECT_NAME}-Panel"
OUT_DIR="output_panel"

echo "==> Building Panel for ${PROJECT_NAME}..."

# Setup clean directories
rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}/gerbers" "${OUT_DIR}/assembly"

# 1. Generate the Panel via KiKit
echo "==> Generating Panel (${PANEL_NAME}) with KiKit..."
docker run --rm \
  --user $(id -u):$(id -g) \
  -v $(pwd):/work \
  -w /work \
  yaqwsx/kikit \
  panelize \
    -p panel.json \
    "${PROJECT_NAME}.kicad_pcb" "${OUT_DIR}/${PANEL_NAME}.kicad_pcb"

# 2. Export Panel Gerbers & Drills
echo "==> Exporting Panel Gerbers & Drills..."
kicad-cli pcb export gerbers --output "${OUT_DIR}/gerbers/" "${OUT_DIR}/${PANEL_NAME}.kicad_pcb"
kicad-cli pcb export drill --output "${OUT_DIR}/gerbers/" "${OUT_DIR}/${PANEL_NAME}.kicad_pcb"

# 3. Export Pick & Place (Centroid/POS) for Assembly
echo "==> Exporting Assembly Positions (POS)..."
kicad-cli pcb export pos \
  --output "${OUT_DIR}/assembly/${PANEL_NAME}-POS.csv" \
  --format csv \
  --units mm \
  --side both \
  --use-drill-file-origin \
  "${OUT_DIR}/${PANEL_NAME}.kicad_pcb"

# 4. Export BOM
# Note: Most fabs want a SINGLE board BOM even for panels (they multiply it on their end).
echo "==> Exporting BOM..."
kicad-cli sch export bom \
  --output "${OUT_DIR}/assembly/${PROJECT_NAME}-BOM.csv" \
  --fields "QUANTITY,Reference,Value,Footprint,MFG PN,Description" \
  --labels "Qty,Designators,Value,Footprint,MPN,Description" \
  --group-by "Value,Footprint,MFG PN" \
  --exclude-dnp \
  "${PROJECT_NAME}.kicad_sch"

# 5. Zip it all up
echo "==> Zipping Panel Manufacturing Package..."
(cd "${OUT_DIR}" && zip -r "${PANEL_NAME}-Fab-Package.zip" gerbers assembly > /dev/null)

echo "==> Success! Panel package ready in ${OUT_DIR}/"
