# Chat eval: phone-replay

| metric | value |
|---|---|
| mean key-point score | 83% |
| scenarios | 3 |
| mean reply length | 1100 chars |
| mean time per turn | 240s |
| replies with [n] citations | 0 / 4 |
| replies with a "not in your guides" line | 0 / 4 |

| scenario | score | chars | time | missing |
|---|---|---|---|---|
| fire-dark-cold | 100% | 1403 | 275s |  ⚠ avoid |
| lost-no-service | 50% | 1232 | 200s | shelter, insulat ⚠ avoid |
| bleach-1pct | 100% | 653 | 199s |  |

## fire-dark-cold

**User:** I'm in the middle of nowhere and I need to start a fire it's getting dark and cold

**Sources:** Mountain and Cold Weather Environments (ATP 3-90.97 Ch. 1) › The Environment: OBSERVATION AND FIELDS OF FIRE | Tips for a Better Burn (EPA Burn Wise) › Prepping the Fire | Food, Water and Living in the Mountains (TC 3-97.61 Ch. 4) › Mountain Subsistence and Sustainment: Lighter and Fire Starter

**Score:** 100%

> Call 911 if you can. If not, stay calm and take these steps:
> 
> 1. Find dry tinder—small twigs, bark, or grass—and place them in a small pile. Use natural fire-starters like a heat tab or candle, or rub a strip of sandpaper on the end of a match.
> 
> 2. Store your matches in a waterproof container with a damp cloth over it to keep them safe. If you have no matches, use a fire starter stick with flammable material.
> 
> 3. Create a cone shape with dry kindling (small sticks), leaving space between pieces so air can flow. Place the tinder at the bottom and build up the kindling in layers.
> 
> 4. Keep the stove door open for 2–5 minutes if using a stove, to let it draft and warm up. If no stove, place your fire in a depression or valley of rocks to catch heat.
> 
> 5. Light the tinder with a match or lighter. Once you see smoke, use a long-handled lighter or torch to ignite the kindling. Do not leave the area unattended.
> 
> 6. Watch for smoke rising steadily—this means it's burning well. If no flame appears in 10 minutes, move to a different spot and try again with fresh materials.
> 
> 7. Stay near your fire until it’s fully burning. Do not go outside after lighting unless you’re sure it’s safe and visible from the inside.
> 
> If the wind is strong or visibility drops, stop and wait. When it’s dark and cold, stay warm by keeping close to the fire and avoid moving far from it. If you need help, call 911 now.

## lost-no-service

**User:** it's getting dark I'm lost in the woods what do I do first. I have no cell service either

**Sources:** Outdoor Emergency Plan: If You Get Lost or Injured (National Park Service) › 4. Go to a Ranger Station | Outdoor Emergency Plan: If You Get Lost or Injured (National Park Service) › If someone in your group gets injured | Outdoor Emergency Plan: If You Get Lost or Injured (National Park Service) › 3. Call 911 if you have cell phone service

**Score:** 50% — missing: shelter, insulat

> Call 911 if you can — but you said no cell service, so that’s not possible. First action: stay calm and stop moving. The most important thing is to preserve your energy and avoid getting worse.
> 
> 1. Sit down in a safe place, ideally near a tree or rock where you can see the sky for direction. Stay still to prevent exhaustion.  
> 2. If you have any way to signal (like a mirror, flashlight, or whistle), use it every 5 minutes to make noise — point it at the sky during daylight or flash in short bursts when you think someone might see it. Do this even if no one comes.  
> 3. Use any natural landmarks you can see: note directions with trees, hills, or rivers — write them down if you have paper and a pen.  
> 4. If you have water, drink slowly. Don’t eat unless you know what’s safe.  
> 5. Do not walk in circles or search for a path without knowing where you started.  
> 
> Next: try to move toward the nearest known trail or ranger station using your memory of landmarks. Look for signs like roads, buildings, or vehicles. If you see one, go there immediately — go to the nearest ranger station or visitor center.
> 
> If you can’t find it, wait until morning and keep watching for signs of help. What direction do you think you’re headed?

## bleach-1pct

**User:** I'm trying to figure out how much bleach I need to add to my water

**User:** I think it's 1%

**Sources:** Solutions and Concentration: Molarity, Percent, ppm and Dilution (OpenStax Chemistry 2e, 2023) › Dilution of Solutions: Example: Volume of a Concentrated Solution Needed for Dilution | How to Make Water Safe in an Emergency › Disinfect: Steps for using bleach to disinfect water

**Score:** 100%

> If your bleach is 1% sodium hypochlorite, follow these steps for 1 gallon (about 3.8 liters) of water:
> 
> - Add 40 drops of bleach or  
> - Add 2.5 mL of bleach (½ mL is half a milliliter) or  
> - Add about ½ teaspoon of bleach.
> 
> If your water is cloudy, murky, colored, or very cold, double the amount: use 80 drops, 5 mL, or 1 teaspoon.
> 
> Stir well and let the mixture stand for at least 30 minutes before drinking.  
> 
> Store disinfected water in clean, sealed containers.  
> 
> Make sure you have a way to measure small amounts—drops or milliliters work best if you don’t have spoons.  
> 
> What size container of water are you treating? (e.g., 1 quart, 1 gallon)


