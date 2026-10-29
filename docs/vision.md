# Product vision

**OFFGRID AI is a completely offline, AI-powered survival and
self-sufficiency knowledge system that helps individuals and families
prepare for, respond to, and recover from emergencies — from short-term
disruptions to prolonged loss of infrastructure.**

If someone has a working phone, OFFGRID AI should give them access to as
much practical knowledge as possible to survive, adapt, and become
self-sufficient. No library covers every situation, so coverage is built
systematically and measured.

## Non-negotiable principles

1. **Every core procedure is readable without the AI.** The model enhances
   the library; the library must survive a model failure. (Implemented:
   Library, search and reader work with no model installed.)
2. **Source-backed, verbatim reference text.** Library passages are copied
   word-for-word from authoritative, licensed sources; AI answers cite them.
3. **The AI never approves its own procedures.** Generated text is never
   added to the library; content is human-reviewed.
4. **Hazardous domains get extra care.** Medicine and wild-food
   identification carry explicit limits (below).

## Library taxonomy — 18 primary packs

| # | Pack | Scope (examples) |
|---|---|---|
| 01 | Emergency Medicine & First Aid | CPR, bleeding, burns, fractures, wounds, splints, bites, hypothermia, dehydration, assessment, pediatric emergencies |
| 02 | Medicines & Natural Remedies | medication use/storage/expiry, interactions, contraindications, traditional remedies with evidence and limits |
| 03 | Shelter & Construction | natural/tarp/winter shelters, insulation, weatherproofing, carpentry, structural safety |
| 04 | Water & Sanitation | finding, collecting, filtering, disinfecting, storing water; sewage, handwashing, household sanitation |
| 05 | Food Procurement & Cooking | foraging, fishing, trapping regulations, food handling, outdoor/fireless cooking, nutrition, food safety |
| 06 | Edible & Poisonous Plants | identification, lookalikes, ranges, seasons, edible parts, preparation, poisonous species |
| 07 | Agriculture & Food Production | gardening, seed saving, soil, compost, irrigation, rotation, greenhouses, animal husbandry |
| 08 | Food Preservation & Storage | canning, drying, fermenting, smoking, salting, root cellars, spoilage, pests |
| 09 | Fire, Heat & Cooking Systems | fire starting, fuels, stoves, heating, ventilation, carbon monoxide, fire prevention |
| 10 | Power & Electricity | solar, batteries, inverters, generators, power budgeting, electrical safety |
| 11 | Tools, Repairs & Fabrication | hand tools, plumbing, auto repair, woodworking, knots, mechanical systems, metalworking |
| 12 | Navigation & Geography | maps, compass, offline GPS, terrain, celestial navigation, route planning |
| 13 | Communications & Signaling | ham radio, GMRS, LoRa, antennas, emergency signaling, protocols |
| 14 | Weather & Natural Disasters | hurricanes, tornadoes, wildfires, floods, earthquakes, blizzards, heat, lightning, landslides |
| 15 | Chemical, Biological & Radiological Safety | hazard recognition, radiation protection, sheltering, decontamination, PPE |
| 16 | Wilderness & Environmental Survival | desert, forest, mountain, marine, tropical, arctic, animal and insect hazards, survival psychology |
| 17 | Long-Term Self-Sufficiency | off-grid living, homesteading, community systems, waste, hygiene, long-term planning |
| 18 | Family & Community Preparedness | children, older adults, pets, disability needs, household plans, inventories, evacuation, coordination |

Pack source folders are numbered to match (`content/04-water-sanitation/`).

## Medicine: three layers

- **First aid** — evidence-based procedures for injuries and common emergencies.
- **Medication knowledge** — uses, storage, contraindications, interactions,
  what to do when access is interrupted.
- **Improvised and traditional remedies** — historical methods, supporting
  evidence, known risks, and where effectiveness is not established.
  Improvised pharmaceutical manufacture is never presented as a reliable
  substitute for manufactured medicine.

## Edible plants and mushrooms

A regional species database (images of each plant part, scientific names,
habitats, seasons, toxic lookalikes and distinguishing features, edible
parts, preparation, poisoning symptoms, geographic filtering). An offline
image-recognition aid may suggest candidates, but **AI identification alone
is never sufficient to declare a wild plant or mushroom safe to eat.**

## Scenarios, not just topics

An Emergency Scenario Explorer (72-hour blackout, lost in the wilderness,
long-term infrastructure failure, medical emergency, stranded in winter, …)
combines procedures from several packs. Knowledge is interconnected: a
long-term shelter question also touches construction, ventilation, water,
sanitation, weather, heating and local hazards.

## Survival Coverage Matrix

Each topic has a status — **Verified**, **Partial**, **Missing**, or
**Needs safety review** — and is checked against six questions: what it
accomplishes, required materials, when it's appropriate, step-by-step
procedure, hazards and limitations, and source evidence. Topics are also
rated on whether a non-expert can realistically perform them.

## Knowledge Management System (Python tooling)

Grows from `tools/packs/` into a system that finds coverage gaps, imports
permitted documents, tags topics and scenarios, flags conflicting content,
preserves diagrams, and routes hazardous material to expert review.
Packs may become self-contained SQLite databases with a shared catalog
linking procedures across packs. Text and diagrams first; little video.

## Candidate sources (each needs license + accuracy review)

U.S. Army ATP 3-50.21 *Survival*; FEMA CERT; National Center for Home Food
Preservation; USDA and university extension services; CDC, FDA, NIH;
USGS, NOAA, NPS, U.S. Forest Service. See `docs/decisions.md` for what has
been verified and approved.
