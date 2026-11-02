# Chat eval: phone-replay-2

| metric | value |
|---|---|
| mean key-point score | 67% |
| scenarios | 3 |
| mean reply length | 1255 chars |
| mean time per turn | 247s |
| replies with [n] citations | 1 / 3 |
| replies with a "not in your guides" line | 0 / 3 |

| scenario | score | chars | time | missing |
|---|---|---|---|---|
| lost-dark-cold | 75% | 1246 | 244s | shelter |
| fire-dark-cold | 100% | 1266 | 233s |  |
| lost-no-service | 25% | 1254 | 267s | shelter, insulat, signal ⚠ avoid |

## lost-dark-cold

**User:** I'm lost in the woods, it's getting dark and cold. What do I do first?

**Sources:** If You Get Lost (USDA Forest Service) › If you get lost: plan, stop, think, observe, plan | Outdoor Emergency Plan: If You Get Lost or Injured (National Park Service) › 4. Go to a Ranger Station | Outdoor Emergency Plan: If You Get Lost or Injured (National Park Service) › 2. Keep warm and dry

**Score:** 75% — missing: shelter

> Stop immediately and stay put. Do not move unless you have a clear reason to. Panic increases exhaustion and makes it harder to think clearly.
> 
> Stay calm and assess your situation. You are getting cold and it’s nightfall—this means you need to prioritize warmth and safety. Keep yourself dry and warm right now.
> 
> Put on all extra layers of clothing, button or zip them tightly. Tuck your pants into your socks. Wear a hat or pull up the hood of your jacket. If you have a blanket, wrap yourself in it. Keep your body heat in by minimizing movement and exposure to wind.
> 
> Check if you have a compass or map—use it to determine direction without moving. Stay on any trail markers or signs you can see. If there’s no trail, do not wander; instead, stay where you are until conditions improve.
> 
> If you have a flashlight or headlamp, turn it on and keep it on. Use your matches or light source to signal for help if you see someone later.
> 
> Do not try to find your way back by walking—wait. When the next daylight comes, reevaluate. If you still can’t find your route, go to the nearest ranger station or visible sign.  
> 
> When should I move? Only after you’ve confirmed that staying in place is safe and you have a clear plan for when it’s time to act.

## fire-dark-cold

**User:** I'm in the middle of nowhere and I need to start a fire it's getting dark and cold

**Sources:** Fire (ATP 3-50.21 Ch. 5) › Fire: FIRE STARTING TECHNIQUES | Fire (ATP 3-50.21 Ch. 5) › Fire: PRIMITIVE METHODS OF FIRE BUILDING | Best Wood-Burning Practices (EPA Burn Wise) › Building a Fire

**Score:** 100%

> Start by finding dry, split wood that sounds hollow when struck together—this means it’s well-seasoned and has less than 20% moisture. If you don’t have a moisture meter, use your hand: if the wood feels damp or heavy, avoid it. Use only dry, seasoned wood to build an efficient, hot fire.
> 
> Next, gather small kindling like twigs or dry leaves that are fine enough to ignite easily. Place this in a tight bundle near the center of where you'll build the fire pit. Start with a tinder pack—newspaper, dry grass, or natural fibers—to create a flame at the base.
> 
> Position your tinder and kindling on the upwind side of the fire zone so that wind carries air toward it, helping to sustain the flames. Keep your fire small and manageable; avoid building too large too fast.
> 
> If you have no tools, use natural materials: rub two sticks together (friction method) or create a bow drill if possible—this is a primitive technique but requires patience and skill [2].
> 
> Once the flame starts, maintain it with constant airflow. Watch for smoke color—if it turns black or thick, the fire may be smoldering or not burning well.
> 
> Wait until you see a steady, blue-white flame before adding larger logs.
> 
> What do you have nearby—like dry leaves, sticks, or tools—to help start it?

## lost-no-service

**User:** it's getting dark I'm lost in the woods what do I do first. I have no cell service either

**Sources:** If You Get Lost (USDA Forest Service) › If you get lost: plan, stop, think, observe, plan | Outdoor Emergency Plan: If You Get Lost or Injured (National Park Service) › 4. Go to a Ranger Station | Outdoor Emergency Plan: If You Get Lost or Injured (National Park Service) › 1. Hug-A-Tree

**Score:** 25% — missing: shelter, insulat, signal

> Stop moving immediately and stay put. Panic increases exhaustion and makes it harder to think clearly.  
> 
> 1. Find a tree, rock, or large object and hug it tightly—this is your anchor point. If there's no large structure, sit in one place and keep still. Do not walk aimlessly or follow random paths.  
> 2. Use any compass you have (if available) to check directions while staying put. Look for landmarks like tall trees, rivers, or roads that might help you remember where you were going.  
> 3. Stay calm and conserve energy. Do not search or move unless you see a clear sign of a trail, road, or visible human structure.  
> 4. If you can see a path or drainage stream, follow it downhill only as a last resort—this may lead to a trail or road but can be dangerous.  
> 
> Wait until morning or until you spot signs of human activity. Do not try to go further into the woods.  
> 
> If you see lights, hear vehicles, or notice someone nearby, move toward them slowly and quietly. If no help is visible in the next hour, stay put and wait for daylight.  
> 
> When it's light again, if you're still lost, head to the nearest ranger station—the best chance of getting help without moving further into the woods.  
> 
> Do you see any signs of a trail, road, or lights nearby?


