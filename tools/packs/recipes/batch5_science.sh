#!/usr/bin/env bash
# Batch 5 (science): one new pack.
#   content/24-practical-science (id practical-science) — OpenStax "College
#     Physics 2e" (temperature, heat and heat transfer, fluids, electric
#     current / Ohm's law / power / hazards, circuits and electrical safety,
#     power and simple machines) and OpenStax "Chemistry 2e" (solution
#     concentration, reaction types incl. combustion/redox, gas pressure,
#     acids/bases and pH, batteries and corrosion).
#
# Usage: tools/packs/recipes/batch5_science.sh <source-dir> [--fetch]
#   --fetch downloads every source below into <source-dir> first
#   (curl -sL -A "Mozilla/5.0" --retry 3). All sources answered HTTP 200 on
#   2026-10-30. Run from the project root; then build the pack with
#   python3 tools/packs/build_pack.py content/24-practical-science
#
# LICENSE — READ THIS. OpenStax re-licensed its textbooks: the live web book
# (openstax.org/books/...) and the PDFs re-issued in 2026 now say
#   "© 1999-2026, Rice University. Except where otherwise noted, textbooks on
#    this site are licensed under a Creative Commons
#    Attribution-NonCommercial-ShareAlike 4.0 (CC BY NC-SA) license."
# and add "This book may not be used in the training of large language models
# or otherwise be ingested into large language models or generative AI
# offerings without OpenStax's prior written permission." That text is NOT
# used here. CC BY 4.0 is irrevocable for the versions released under it
# (CC BY 4.0 §6(a) / §2(a)(1)), so this recipe takes the text from the
# 2023 content versions that OpenStax still serves from its own archive, whose
# book metadata states the licence of that version:
#   College Physics 2e  a31df062-930a-4f46-8953-605711e6d204@ccb5581
#     (revised 2023-07-27) "license": {"url":
#     "http://creativecommons.org/licenses/by/4.0/", "name": "Creative
#     Commons Attribution License"}
#   Chemistry 2e        7fccc9cf-9b71-44f6-800b-f9457fd64335@b40bd2c
#     (revised 2023-06-28) same licence block.
#   (version hashes = openstax/rex-web src/config.books.json at commit
#   5f357c2, 2023-08-29; archive 20230620.181811 from config.archive-url.json)
# Corroborated by the copyright pages of the PDFs OpenStax still serves:
#   https://assets.openstax.org/oscms-prodcms/media/documents/College_Physics_2e-WEB.pdf
#     (Last-Modified 2022-07-13, p.2): "©2022 Rice University. Textbook
#     content produced by OpenStax is licensed under a Creative Commons
#     Attribution 4.0 International License (CC BY 4.0). ... If you
#     redistribute part of this textbook, then you must retain in every
#     digital format page view ... the following attribution: 'Access for free
#     at openstax.org.'"
#   https://assets.openstax.org/oscms-prodcms/media/documents/Chemistry2e-OP.pdf
#     (Last-Modified 2019-02-22, p.2): "©2019 Rice University. Textbook
#     content produced by OpenStax is licensed under a Creative Commons
#     Attribution 4.0 International License (CC BY 4.0). ... 'Download for
#     free at https://openstax.org/details/books/chemistry-2e.'"
# The required attribution is carried in pack.json ("Access for free at
# openstax.org", title, OpenStax/Rice University, CC BY 4.0, "excerpted and
# re-sectioned") and every document's Source line. OpenStax/Rice names and
# logos are trademarks, not licensed: no logos or covers are used. Images
# (some are third-party CC/credited photos) are not used.
# OWNER TO RULE: whether relying on the irrevocable 2023 CC BY 4.0 versions is
# acceptable given OpenStax's later NC-SA relicensing and AI clause.
#
# EXCLUDED (and why):
#   - Siphons: College Physics 2e has no siphon section (only end-of-chapter
#     problems); not covered.
#   - 13.2–13.6 (thermal expansion, ideal gas law, kinetic theory, phase
#     diagrams, humidity), 11.8–11.9, 12.4–12.7, 20.7 (ECG), 21.3 (Kirchhoff),
#     21.5–21.6, 23.1–23.7/23.9+, 9.1–9.4/9.6, 7.1–7.6/7.8–7.9, chem 3.1–3.2,
#     4.1/4.3–4.5, 9.2–9.6, 14.3–14.7, 17.2–17.4/17.7: not in the brief.
#   - "Concepts of Biology" microbiology chapter: not taken (time; the brief
#     made it optional).
#   - Per page: learning objectives, figures and captions (and their image
#     credits), Check Your Understanding / Check Your Learning exercises and
#     answers, PhET / Link to Learning boxes, "Career Connection",
#     "Connections: Limits to Knowledge", "How Sciences Interconnect",
#     footnotes, equation numbers, glossary links — see extract_openstax.py.
#   - Section 20.1 "Drift Velocity" and the "Things Great and Small" box in
#     21.2 (atomic-scale theory, no practical use); 20.5 "Why Use AC for
#     Power Distribution?" is kept.
#
# Text is verbatim. MathML equations are linearised to plain text by
# tools/packs/extract_openstax.py (V = IR, (12.0 V)/(2.50 A), 10^(−5), R_1);
# "Strategy / Solution / Discussion" labels inside worked examples are
# dropped as structure. Tables are one line per row with " | " between
# cells (checked by eye: thermal conductivities, resistivities, latent
# heats, pH table).
set -euo pipefail
SRC="${1:?usage: $0 <source-dir> [--fetch]}"
XO="python3 tools/packs/extract_openstax.py"
V=2026.10.30.1

ARCHIVE=https://openstax.org/apps/archive/20230620.181811/contents
CP_ID=a31df062-930a-4f46-8953-605711e6d204; CP_VER=ccb5581
CH_ID=7fccc9cf-9b71-44f6-800b-f9457fd64335; CH_VER=b40bd2c
CP_URL=https://openstax.org/books/college-physics-2e/pages
CH_URL=https://openstax.org/books/chemistry-2e/pages

CP_PAGES="13-1-temperature 14-1-heat 14-2-temperature-change-and-heat-capacity
  14-3-phase-change-and-latent-heat 14-4-heat-transfer-methods 14-5-conduction
  14-6-convection 14-7-radiation 11-1-what-is-a-fluid 11-2-density 11-3-pressure
  11-4-variation-of-pressure-with-depth-in-a-fluid 11-5-pascals-principle
  11-6-gauge-pressure-absolute-pressure-and-pressure-measurement
  11-7-archimedes-principle 12-1-flow-rate-and-its-relation-to-velocity
  12-2-bernoullis-equation 12-3-the-most-general-applications-of-bernoullis-equation
  20-1-current 20-2-ohms-law-resistance-and-simple-circuits
  20-3-resistance-and-resistivity 20-4-electric-power-and-energy
  20-5-alternating-current-versus-direct-current 20-6-electric-hazards-and-the-human-body
  21-1-resistors-in-series-and-parallel 21-2-electromotive-force-terminal-voltage
  21-4-dc-voltmeters-and-ammeters 23-8-electrical-safety-systems-and-devices
  9-5-simple-machines 7-7-power"
CH_PAGES="3-3-molarity 3-4-other-units-for-solution-concentrations
  4-2-classifying-chemical-reactions 9-1-gas-pressure
  14-1-bronsted-lowry-acids-and-bases 14-2-ph-and-poh
  17-1-review-of-redox-chemistry 17-5-batteries-and-fuel-cells 17-6-corrosion"

if [[ "${2:-}" == "--fetch" ]]; then
  mkdir -p "$SRC"
  dl() { curl -sL -A "Mozilla/5.0" --retry 3 -o "$SRC/$1" "$2"; }
  # Book JSON: licence of this content version + page tree (slug -> page id).
  dl cp2e-book-$CP_VER.json "$ARCHIVE/$CP_ID@$CP_VER.json"
  dl chem2e-book-$CH_VER.json "$ARCHIVE/$CH_ID@$CH_VER.json"
  pageid() { python3 - "$SRC/$1" "$2" <<'PY'
import json, sys
def walk(n):
    for c in n.get("contents", []):
        if "contents" in c: yield from walk(c)
        else: yield c["slug"], c["id"].split("@")[0]
print(dict(walk(json.load(open(sys.argv[1]))["tree"]))[sys.argv[2]])
PY
  }
  for p in $CP_PAGES; do dl "cp-$p.json" "$ARCHIVE/$CP_ID@$CP_VER:$(pageid cp2e-book-$CP_VER.json $p).json"; done
  for p in $CH_PAGES; do dl "ch-$p.json" "$ARCHIVE/$CH_ID@$CH_VER:$(pageid chem2e-book-$CH_VER.json $p).json"; done
  # Licence evidence only (not extracted): the CC BY 4.0 PDFs' copyright pages.
  dl cp2e-2022.pdf https://assets.openstax.org/oscms-prodcms/media/documents/College_Physics_2e-WEB.pdf
  dl chem2e-op-2019.pdf https://assets.openstax.org/oscms-prodcms/media/documents/Chemistry2e-OP.pdf
  for f in cp2e-book-$CP_VER.json chem2e-book-$CH_VER.json; do
    python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["title"], d["revised"], d["license"])' "$SRC/$f"
  done
fi

phys() {  # phys <out.md> <title> <aliases> <slug...>   (College Physics 2e)
  local o=$1 t=$2 al=$3; shift 3; local first=$1 files=()
  for p in "$@"; do files+=("$SRC/cp-$p.json"); done
  $XO "${files[@]}" --title "$t" --source-url "$CP_URL/$first" --aliases "$al" -o "$o" ${EXTRA[@]+"${EXTRA[@]}"}
}
chem() {  # chem <out.md> <title> <aliases> <slug...>   (Chemistry 2e)
  local o=$1 t=$2 al=$3; shift 3; local first=$1 files=()
  for p in "$@"; do files+=("$SRC/ch-$p.json"); done
  $XO "${files[@]}" --title "$t" --source-url "$CH_URL/$first" --aliases "$al" -o "$o" ${EXTRA[@]+"${EXTRA[@]}"}
}
EXTRA=()

D=content/24-practical-science; mkdir -p $D; rm -f $D/*.md

phys $D/01-temperature.md "Temperature, Thermometers and Temperature Scales (OpenStax College Physics 2e, 2023)" \
  "how do thermometers work, convert celsius to fahrenheit, fahrenheit to celsius formula, what is absolute zero, kelvin scale explained, what temperature does water boil, what temperature does water freeze, how a bimetallic strip thermostat works, why does a thermometer need time to settle, body temperature in celsius, zeroth law of thermodynamics" \
  13-1-temperature

phys $D/02-heat.md "Heat, Heat Capacity, Phase Change and Latent Heat (OpenStax College Physics 2e, 2023)" \
  "what is heat vs temperature, how much energy to boil water, why does water take so long to heat, specific heat of water, calories to joules, why does ice melt slowly, latent heat of melting ice, why sweating cools you, evaporation cooling explained, why steam burns are worse, how much heat to melt ice, why does the sea stay cooler than land, cooling with ice how long" \
  14-1-heat 14-2-temperature-change-and-heat-capacity 14-3-phase-change-and-latent-heat

phys $D/03-heat-transfer.md "Heat Transfer: Conduction, Convection and Radiation (OpenStax College Physics 2e, 2023)" \
  "why does metal feel cold, conduction convection radiation explained, how does insulation work, best insulating materials, why fiberglass and down keep you warm, why wind makes you colder, how a house loses heat, double pane window heat loss, why dark clothes get hot in the sun, radiant heat from a fire, how convection moves warm air, why warm air rises, why do you lose heat through the roof, emergency blanket reflect heat, thermal conductivity of wood vs metal, how to stay warm physics" \
  14-4-heat-transfer-methods 14-5-conduction 14-6-convection 14-7-radiation

phys $D/04-fluids-pressure.md "Fluids: Density, Pressure, Pascal's Principle and Buoyancy (OpenStax College Physics 2e, 2023)" \
  "what is water pressure at depth, how does a hydraulic jack work, pascals principle explained, gauge pressure vs absolute pressure, what is psi, atmospheric pressure in psi, why does a boat float, archimedes principle explained, specific gravity of a liquid, how much weight can a raft hold, density of water, pressure head of water tank, how a barometer works, how high can you lift water with a pump, how does a tire gauge work, why dams are thicker at the bottom, blood pressure cuff how it works" \
  11-1-what-is-a-fluid 11-2-density 11-3-pressure 11-4-variation-of-pressure-with-depth-in-a-fluid \
  11-5-pascals-principle 11-6-gauge-pressure-absolute-pressure-and-pressure-measurement 11-7-archimedes-principle

phys $D/05-fluid-flow.md "Fluid Flow: Flow Rate, Bernoulli's Equation and Its Applications (OpenStax College Physics 2e, 2023)" \
  "how to calculate flow rate of a pipe, gallons per minute from pipe size, why does water speed up in a narrow hose, bernoulli principle explained, how a venturi works, why a roof lifts off in high wind, how does a carburetor or sprayer work, water flow from a tank, pipe diameter and flow, how fast does water leave a hole in a tank, toricelli theorem, garden hose nozzle pressure" \
  12-1-flow-rate-and-its-relation-to-velocity 12-2-bernoullis-equation 12-3-the-most-general-applications-of-bernoullis-equation

EXTRA=(--drop-section "^Drift Velocity")
phys $D/06-electricity-basics.md "Electric Current, Ohm's Law, Resistance, Power and Electric Hazards (OpenStax College Physics 2e, 2023)" \
  "ohms law explained, what is an amp a volt and a watt, how to calculate watts from volts and amps, volts times amps equals watts, what is resistance in a circuit, why do wires get hot, resistivity of copper vs aluminum, wire resistance and length, how much current is dangerous, what is a fuse for, how does electricity kill, electric shock how many amps, ac vs dc difference, 120 volts ac explained, kilowatt hour cost of electricity, how to calculate power bill, why does a bulb burn out when switched on, what is a short circuit, microshock and macroshock, wet skin electric shock risk, how much power does an appliance use" \
  20-1-current 20-2-ohms-law-resistance-and-simple-circuits 20-3-resistance-and-resistivity \
  20-4-electric-power-and-energy 20-5-alternating-current-versus-direct-current 20-6-electric-hazards-and-the-human-body
EXTRA=()

EXTRA=(--drop-note "Things Great and Small")
phys $D/07-circuits-safety.md "Circuits: Series and Parallel, Batteries, Meters and Electrical Safety (OpenStax College Physics 2e, 2023)" \
  "series vs parallel circuits, how to wire batteries in series or parallel, why does battery voltage drop under load, internal resistance of a battery, why do old batteries go flat, why does a flashlight dim, how to use a voltmeter, how to use an ammeter, how to measure voltage with a multimeter, what does a ground wire do, three prong plug ground, what is a gfci outlet, how a circuit breaker works, why do lights dim when an appliance turns on, resistors in parallel total resistance, double insulated tools, electrical safety at home, why grounding matters, generator grounding" \
  21-1-resistors-in-series-and-parallel 21-2-electromotive-force-terminal-voltage 21-4-dc-voltmeters-and-ammeters \
  23-8-electrical-safety-systems-and-devices
EXTRA=()

phys $D/08-power-simple-machines.md "Power, Horsepower and Simple Machines: Levers, Pulleys, Inclined Planes (OpenStax College Physics 2e, 2023)" \
  "lever mechanical advantage, how does a lever work, how to lift a heavy object with a lever, pulley mechanical advantage, block and tackle explained, wheelbarrow as a lever, crowbar physics, nail puller leverage, inclined plane ramp force, what is horsepower in watts, how much power is a kilowatt, how to move heavy rocks alone, how do simple machines multiply force, power output of a human, how many watts is a horsepower, how long to lift a load with a winch" \
  7-7-power 9-5-simple-machines

chem $D/09-solutions-concentration.md "Solutions and Concentration: Molarity, Percent, ppm and Dilution (OpenStax Chemistry 2e, 2023)" \
  "how to mix a percent solution, how to make a 10 percent solution, mass percent vs volume percent, what does ppm mean, parts per million explained, how to dilute a concentrated solution, dilution formula c1v1 c2v2, what is molarity, moles per liter explained, how much bleach is 7 percent sodium hypochlorite, how to make a weaker solution from a strong one, mg per liter to ppm, 70 percent rubbing alcohol how much alcohol, salt water concentration grams per liter, how to calculate concentration" \
  3-3-molarity 3-4-other-units-for-solution-concentrations

chem $D/10-chemical-reactions.md "Chemical Reactions: Precipitation, Acid-Base, Oxidation-Reduction and Combustion (OpenStax Chemistry 2e, 2023)" \
  "what is combustion, what happens when something burns, what is oxidation, what is rust chemically, oxidation reduction explained, redox reaction examples, why does iron rust, acid base neutralization, what is a precipitate, what happens when you mix an acid and a base, baking soda and vinegar reaction, hydrogen fuel burning reaction, oxidation number rules, half reaction explained, why does fire need oxygen, what is a salt chemically, solubility rules for compounds" \
  4-2-classifying-chemical-reactions 17-1-review-of-redox-chemistry

chem $D/11-gas-pressure.md "Gas Pressure: Barometers, Manometers and Pressure Units (OpenStax Chemistry 2e, 2023)" \
  "what is gas pressure, how does a barometer work, what is atmospheric pressure, convert psi to kpa, convert atm to psi, mm hg to psi, how a manometer works, why does air pressure drop with altitude, what is a torr, what is a pascal unit, what is a bar pressure unit, why does pressure matter for weather, how altitude affects boiling, blood pressure units mm hg, tire pressure units" \
  9-1-gas-pressure

chem $D/12-acids-bases-ph.md "Acids and Bases: Bronsted-Lowry Definitions, pH and pOH (OpenStax Chemistry 2e, 2023)" \
  "what is ph, ph scale explained, what ph is acidic, what ph is neutral, is lemon juice an acid, what is an acid and a base, what is a base chemically, what ph is bleach, what ph is stomach acid, how to calculate ph, ph of pure water, what is a hydronium ion, what is amphoteric, ph of common foods and household products, acid rain ph, what is poh, why ph 7 is neutral, ph of vinegar, ph of blood" \
  14-1-bronsted-lowry-acids-and-bases 14-2-ph-and-poh

chem $D/13-batteries-corrosion.md "Batteries, Fuel Cells and Corrosion (OpenStax Chemistry 2e, 2023)" \
  "how does a battery work, how a lead acid battery works, car battery chemistry, why cant you recharge alkaline batteries, lithium ion battery explained, nickel metal hydride vs lithium, what is a dry cell battery, why do batteries die, how a fuel cell works, why does iron rust, how to stop rust, galvanized steel why zinc, sacrificial anode explained, cathodic protection of a tank, why does salt speed up rusting, why does aluminum not rust, why does copper turn green, battery voltage by type, primary vs secondary battery" \
  17-5-batteries-and-fuel-cells 17-6-corrosion

cat > $D/pack.json <<JSON
{
 "id": "practical-science",
 "title": "Practical Science: Electricity, Heat, Fluids, Simple Machines and Chemistry (OpenStax)",
 "category": "guide",
 "version": "$V",
 "review": "verified",
 "publisher": "OpenStax, Rice University",
 "license": "Creative Commons Attribution 4.0 International (CC BY 4.0) — text taken from the 2023 content versions of College Physics 2e (a31df062@ccb5581) and Chemistry 2e (7fccc9cf@b40bd2c) published by OpenStax under CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/); later OpenStax editions carry a different licence",
 "attribution": "Access for free at openstax.org. Excerpted from \"College Physics 2e\" (authors Paul Peter Urone and Roger Hinrichs; OpenStax, Rice University, 2022; https://openstax.org/books/college-physics-2e/pages/1-introduction-to-science-and-the-realm-of-physics-physical-quantities-and-units) and \"Chemistry 2e\" (authors Paul Flowers, Klaus Theopold, Richard Langley and William R. Robinson; OpenStax, Rice University, 2019; https://openstax.org/books/chemistry-2e/pages/1-introduction), licensed under CC BY 4.0. The text has been excerpted and re-sectioned: selected sections only, equations rendered as plain text, figures, exercises, interactive links and footnotes omitted. OpenStax and Rice University names and logos are trademarks and are not covered by the licence. Use does not imply endorsement by OpenStax or Rice University.",
 "description": "How things work when you have to do it yourself: temperature and heat, insulation and heat loss, water pressure, pumps and flow, Ohm's law, electrical power and shock hazards, batteries and circuits, levers and pulleys, mixing percent solutions, pH, combustion and rust, gas pressure."
}
JSON
echo "done: content/24-practical-science"
