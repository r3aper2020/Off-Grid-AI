# Chat eval: before

| metric | value |
|---|---|
| mean key-point score | 83% |
| scenarios | 34 |
| mean reply length | 535 chars |
| mean time per turn | 117s |
| replies with [n] citations | 25 / 36 |
| replies with a "not in your guides" line | 6 / 34 (recomputed over final replies) |

| scenario | score | chars | time | missing |
|---|---|---|---|---|
| lost-dark-cold | 100% | 641 | 128s |  |
| bleeding | 33% | 648 | 129s | 911, pressure |
| tourniquet-followup | 100% | 665 | 119s |  |
| bleach-gallon | 67% | 453 | 110s | unscented |
| kid-fever | 67% | 472 | 58s | acetaminophen |
| choking | 100% | 642 | 122s |  |
| freezer-3-days | 67% | 580 | 144s | throw |
| snow-shelter | 67% | 611 | 137s | insulat |
| edible-plants | 67% | 772 | 144s | test |
| purify-water | 100% | 555 | 133s |  |
| bug-out-bag | 60% | 761 | 155s | flashlight, radio |
| generator | 100% | 269 | 60s |  |
| jump-start | 100% | 581 | 93s |  |
| river-hypothermia | 50% | 315 | 37s | wet cloth, gentle |
| rattlesnake | 100% | 600 | 143s |  |
| burn-blister | 75% | 622 | 130s | minute |
| earthquake-now | 100% | 445 | 98s |  |
| tornado-mobile-home | 100% | 406 | 82s |  |
| cpr-adult | 100% | 433 | 104s |  |
| fire-no-matches | 100% | 769 | 185s |  |
| battery-bank | 67% | 446 | 119s | days |
| potassium-iodide | 50% | 439 | 110s | thyroid |
| water-storage | 100% | 371 | 95s |  |
| ham-radio | 100% | 515 | 118s |  |
| insulin-no-power | 100% | 613 | 146s |  |
| ankle-sprain | 100% | 414 | 76s |  |
| seizure | 75% | 416 | 85s | nothing in the mouth |
| flooded-road | 100% | 380 | 86s |  |
| deep-cut-clean | 100% | 665 | 119s |  |
| heat-stroke-dad | 67% | 492 | 118s | fan |
| ridge-lightning | 33% | 387 | 100s | descend, 30 |
| find-north | 67% | 868 | 217s | north star |
| fire-then-water | 100% | 548 | 190s |  |
| capital-france | 100% | 271 | 38s |  |

## lost-dark-cold

**User:** I'm lost in the woods, it's getting dark and cold. What do I do first?

**Sources:** Boating Safety and Survival Tips: Capsizing, Cold Water, Life Rafts, Severe Weather (USCG Boater's Guide) › Weather | If You Get Lost (USDA Forest Service) › Self-rescue tips:

**Score:** 100%

> You should stop and rest immediately to avoid exhaustion or hypothermia.  
> 1. Find a sheltered spot—something dry and protected from wind and rain.  
> 2. Stay warm by wrapping yourself in any clothing or layers you have; cover your extremities.  
> 3. If possible, signal for help using mirrors, rocks, or bright colors visible at night.  
> 4. Avoid moving if you're already tired or cold—the body needs rest to survive the cold.  
> 
> The offline guides don't cover nighttime survival specifically, but [2] emphasizes resting and hydration when fatigued—critical in cold conditions. Do you have any way to signal for help or a nearby trail marker?

## bleeding

**User:** my friend cut his leg badly and it won't stop bleeding

**Sources:** Stopping Severe Bleeding (ATP 4-02.11 Ch. 4) › Massive Bleeding Control: TOURNIQUETS | Stopping Severe Bleeding (ATP 4-02.11 Ch. 4) › Massive Bleeding Control: OVERVIEW OF MASSIVE BLEEDING CONTROL: Massive Bleeding Control (part 2)

**Score:** 33% — missing: 911, pressure

> You need to apply a tourniquet right away to stop the severe bleeding.  
> 
> 1. Find a tourniquet—use your friend’s first aid kit or any available material if none is there.  
> 2. Place it above the wound, on the upper part of the leg (closer to the hip), not directly over the cut.  
> 3. Tighten it just enough to stop bleeding—don’t squeeze too hard; you’re aiming for a point where blood flow stops.  
> 4. If your friend is conscious, have him help apply it himself if he has one.  
> 5. Check every 10 minutes and re-tighten if the bleeding returns.  
> 
> If the bleeding continues after 10 minutes or your friend can't move, get medical help immediately.

## tourniquet-followup

**User:** my friend cut his leg badly and it won't stop bleeding

**User:** what if I don't have a tourniquet?

**Sources:** Survival Medicine (ATP 3-50.21 Ch. 2) › Survival Medicine: BLEEDING (part 2) | Disaster Medical Operations Part 1: Life-Threatening Conditions (CERT Basic Training, Unit 3) › Controlling Bleeding (part 2)

**Score:** 100%

> If you don’t have a tourniquet, use an improvised one made from a strong, flexible belt or strap—like a webbed belt or luggage strap.  
> 1. Place it as high as possible on the leg, over clothing if needed.  
> 2. Twist and tighten it until bleeding slows significantly (this may be very painful).  
> 3. Secure the end with a buckle or knot.  
> 4. If bleeding doesn’t stop, place a second tourniquet side by side to the first [1].  
> 
> Note: Improvised tourniquets are less reliable but can help slow blood loss until professional help arrives. Always watch for signs of shock—like rapid breathing, capillary refill over 2 seconds, or not responding to simple commands [2].

## bleach-gallon

**User:** how much bleach do I add to a gallon of water

**Sources:** How to Make Water Safe in an Emergency › Disinfect: Steps for using bleach to disinfect water | Disaster Medical Operations Part 2: Mass Casualties, Assessment and Public Health (CERT Basic Training, Unit 4) › Water Purification

**Score:** 67% — missing: unscented

> For a gallon of clear water, use 8 drops of bleach if using a dropper [1].  
> If the water is cloudy or dirty, use 16 drops per gallon [2].  
> Always stir well and let it stand for at least 30 minutes before drinking.  
> 
> Note: The sources differ slightly—[1] gives 8 drops for clear water (with 5–9% bleach concentration), while [2] uses a simpler ratio that may not account for bleach strength. For best results, follow the more detailed guidance in [1].

## kid-fever

**User:** my kid has a fever of 103 and we have no doctor

**Sources:** Should You Give Kids Medicine for Coughs and Colds? (FDA) › When to Call a Doctor

**Score:** 67% — missing: acetaminophen

> You should call a doctor because your child has a fever of 103 degrees Fahrenheit, which is above the threshold for children at any age [1].  
> 
> 1. The fever is high enough to signal possible serious illness.  
> 2. You should seek medical help immediately if you can’t reach a doctor.  
> 3. Keep your child hydrated and monitor breathing or changes in behavior closely.  
> 
> If you're unable to call emergency services, contact local clinics or health departments for guidance.

## choking

**User:** someone is choking and can't breathe

**Sources:** Obstructed Airway › Conscious Victims | Obstructed Airway › Conscious Victims: Treatment for adults and children | Obstructed Airway › Conscious Victims: Obstructed Airway for Infants | First Aid in Chemical, Biological and Radiological Incidents (ATP 4-02.11 Ch. 19) › First Aid in a Chemical, Biological, Radiological, and Nuclear Environment: Self-Aid for Choking Agents

**Score:** 100%

> If the person is choking and can't breathe, first ask them clearly: "Are you choking?"  
> 
> 1. If they can speak or answer, encourage them to cough.  
> 2. If they cannot cough, speak, or breathe, give up to 5 hard blows between their shoulder blades with the heel of your hand.  
> 3. If that doesn’t work and they’re still choking, perform up to five abdominal thrusts: place one fist just below the ribs, wrap your other hand around it, and push upward in quick, sharp movements.  
> 
> Note: Abdominal thrusts should only be used if the person cannot cough, breathe, or speak. If the person loses consciousness, call for emergency help immediately.

## freezer-3-days

**User:** the power's been out 3 days, is the food in my freezer still good

**Sources:** Keep Food Safe After a Disaster or Emergency › Steps to take during a power outage | Food and Water Safety During Power Outages and Floods (FDA) › Power Outages: During and After: When the Power Goes Out . . . | Power Outages › How to Protect Yourself During A Power Outage: Food Storage | Food and Water Safety During Power Outages and Floods (FDA) › Power Outages: During and After: Once Power is Restored . . .

**Score:** 67% — missing: throw

> Yes, the food in your freezer is likely still safe.  
> A full freezer can keep food cold for up to 48 hours if the door stays closed [1].  
> Since the power has been out for 3 days, which is more than 48 hours, the food may have started to warm above safe temperatures.  
> You should check each item: if it still contains ice crystals and the temperature is at or below 40°F, it might be safe to refreeze or cook [4].  
> If there’s no thermometer reading in the freezer, you can’t be sure—use a food thermometer to verify safety.  
> 
> Do you have access to a food thermometer right now?

## snow-shelter

**User:** how do I build a shelter in the snow

**Sources:** Shelter and Clothing (ATP 3-50.21 Ch. 6) › Shelter and Clothing: Snow caves | Food, Water and Living in the Mountains (TC 3-97.61 Ch. 4) › Mountain Subsistence and Sustainment: Snow-Trench Shelter | Food, Water and Living in the Mountains (TC 3-97.61 Ch. 4) › Mountain Subsistence and Sustainment: Snow-Cave Shelter

**Score:** 67% — missing: insulat

> Build a snow cave shelter by finding a drift at least 3 meters (10 feet) deep that you can dig into. Keep the roof arched for strength and to allow melted snow to drain down the sides. Build a sleeping platform higher than the entrance, and separate it from the walls with a small trench or dig a gap to prevent melting snow from wetting your gear. The walls and ceiling should be at least 30 centimeters (1 foot) thick. Block the entrance with a snow block or rucksack and install a ventilation shaft for airflow. If no deep drift is available, pile snow into a mound large enough to dig out as an alternative.

## edible-plants

**User:** which plants can I eat in the woods

**Sources:** Survival Medicine (ATP 3-50.21 Ch. 2) › Survival Medicine: POISONOUS PLANTS

**Score:** 67% — missing: test

> You can eat certain plants in the woods, but only after you’ve positively identified them—mistakes can be dangerous.  
> 
> 1. Young leaves of pokeweed are edible when first growing, but become poisonous as they mature.  
> 2. Ripe fruit of the may apple is safe to eat; green parts and other stages are toxic.  
> 3. Potatoes and tomatoes are edible, but their green parts (like sprouts or leaves) are poisonous.  
> 4. Some plants like jack-in-the-pulpit can be safe only if thinly sliced and thoroughly dried for a year—raw or underdried versions are poisonous.  
> 
> Always watch animals—they may eat safe plants, but not all plants they eat are safe for humans. Boiling doesn’t remove all poisons. Many poisonous plants look like edible ones, so identification is critical.  
> 
> [1]

## purify-water

**User:** how do I purify water

**Sources:** Finding and Purifying Water (ATP 3-50.21 Ch. 3) › Water: PREPARING WATER | Finding and Purifying Water (ATP 3-50.21 Ch. 3) › Water: PURIFICATION | Finding and Purifying Water (ATP 3-50.21 Ch. 3) › Water: CHEMICAL PURIFICATION | Finding and Purifying Water (ATP 3-50.21 Ch. 3) › Water: BOILING METHOD | Finding and Purifying Water (ATP 3-50.21 Ch. 3) › Water: DEW | Disaster Medical Operations Part 2: Mass Casualties, Assessment and Public Health (CERT Basic Training, Unit 4) › Water Purification

**Score:** 100%

> You can purify water by boiling, using chemical disinfectants like bleach, or filtering it through a commercial filter.  
> 
> 1. Boil water for 1 minute at sea level (3 minutes if above 8,000 feet).  
> 2. Use 8 drops of non-perfumed liquid bleach per gallon of water; use 16 drops if the water is cloudy. Let it stand for 30 minutes—add more bleach if no smell appears.  
> 3. Filter water through a commercial filter that removes fine particulates and treats the water chemically.  
> 
> The offline guides don’t cover using solar disinfection or UV light methods.

## bug-out-bag

**User:** what should I pack in a bug out bag

**Sources:** First Aid Kit Contents (ATP 4-02.11 App. A) › First Aid Case and Kits, Authorized Medical Allowance List: UNITED STATES MARINE CORPS COMBAT LIFESAVER BAG | First Aid Kit Contents (ATP 4-02.11 App. A) › First Aid Case and Kits, Authorized Medical Allowance List: ARMY COMBAT LIFESAVER BAG | Food, Water and Living in the Mountains (TC 3-97.61 Ch. 4) › Mountain Subsistence and Sustainment: SQUAD OR TEAM EMERGENCY PACK

**Score:** 60% — missing: flashlight, radio

> A bug-out bag should include essential first aid supplies, water, food, and critical survival gear based on your environment. From military guidelines, the U.S. Marine Corps Combat Lifesaver Bag includes items for bleeding control and pneumothorax relief [1]. The Army CLS bag also has similar medical supplies with current list under UAC 245C [2]. For mountain or remote scenarios, a squad emergency pack includes a sleeping bag, mat, stove, fuel, and litter [3].  
> 
> Pack only what you need—reduce weight (R), ensure mobility (D), plan resupply (O), and keep soldiers accounted for (P).  
> 
> If you're going into cold or high-altitude terrain, add insulation and warm clothing.  
> If in a medical emergency, the CLS bag is essential to stabilize injuries quickly.

## generator

**User:** where should I put my generator

**Sources:** Power Outages › Generator Safety | Winter Weather › Generator Safety | First Aid for Seizures › Extra steps for generalized seizures: Generalized seizures affect both sides of the brain and may cause loss of consciousness. | Carbon Monoxide (CO) Poisoning Basics › Reducing risk: Portable generators

**Score:** 100%

> Put your generator outdoors, at least 20 feet away from any windows, doors, or attached garages.  
> This keeps carbon monoxide from entering your home and prevents electrical shock from wet conditions.  
> Always follow the manufacturer’s instructions for safe use.  
> 
> [1]

## jump-start

**User:** how do I jump start a car

**Sources:** Get Tech Ready (Ready.gov) › Make A Plan | Winter Weather › How to Protect Yourself from Winter Weather: In Case of Emergency

**Score:** 100%

> To jump-start a car, you need another vehicle with working batteries and jumper cables. Connect the red cable from the positive terminal of the dead battery to the positive terminal of the good battery, then attach the black cable to the negative terminal of the good battery and clamp it securely (not touching the engine). Start the running vehicle, let it run for a few minutes, then start your car. The offline guide [2] says to include jumper cables in your emergency kit.
> 
> If you don’t have another car or working batteries, you can’t safely jump-start your car without help.

## river-hypothermia

**User:** my buddy fell in the river and now he's shivering hard and confused

**Sources:** none

**Score:** 50% — missing: wet cloth, gentle

> Call 911 right away if you can.  
> Keep him warm with a blanket or your jacket—shivering means he’s losing body heat.  
> Stay with him, speak calmly to help calm his confusion.  
> Do not give him anything to eat or drink—his condition could be life-threatening.  
> 
> Can you confirm whether he’s breathing and conscious?

## rattlesnake

**User:** I got bit by a rattlesnake

**Sources:** Venomous Snakes at Work › Types: Rattlesnakes | Venomous Snakes at Work › Overview | Woodworking Hand Tools and Sharpening (I. S. Griffith, Essentials of Woodworking, 1908) › 39. The Drill Bit; The Gimlet Bit | Woodworking Hand Tools and Sharpening (I. S. Griffith, Essentials of Woodworking, 1908) › 37. Center Bit | Woodworking Hand Tools and Sharpening (I. S. Griffith, Essentials of Woodworking, 1908) › 38. The Auger Bit

**Score:** 100%

> You were bitten by a rattlesnake.  
> 1. Stay calm and keep the bite area immobilized and below heart level.  
> 2. Do not cut the wound, apply tourniquets, or suck out venom.  
> 3. Seek medical help immediately—antivenom is recommended if there are signs of systemic symptoms or worsening tissue injury [1].  
> 4. If you have access to a hospital, inform them that it’s a rattlesnake bite and bring the snake (if safe to do so) for identification.  
> 
> The offline guides don’t cover first aid after a snakebite—only general information about venomous snakes. You should go to a medical facility right away.

## burn-blister

**User:** I burned my hand on the stove and it's blistering

**Sources:** What to Do During Extreme Cold: Frostbite and Hypothermia (NWS) › Frostbite First Aid | Food, Water and Living in the Mountains (TC 3-97.61 Ch. 4) › Mountain Subsistence and Sustainment: STOVE TYPES | First Aid in Chemical, Biological and Radiological Incidents (ATP 4-02.11 Ch. 19) › First Aid in a Chemical, Biological, Radiological, and Nuclear Environment: First Aid Measures for Blister Agent Poisoning

**Score:** 75% — missing: minute

> You have a burn with blisters, which is a serious injury.  
> 
> 1. Stop further exposure to heat and keep your hand cool but not cold.  
> 2. Do not break any blisters — they are protected by skin and can get infected.  
> 3. Cover the blistered area loosely with a clean field dressing or bandage.  
> 4. If you feel pain, swelling, or if the burn covers a large area, go to a hospital immediately.  
> 5. If you were exposed to any chemical agents or suspect contamination, decontaminate skin with water and follow RSDL steps [3].  
> 
> If you were using a liquid-fuel stove or know it was near chemicals, check for possible exposure.

## earthquake-now

**User:** there's an earthquake happening right now what do I do

**Sources:** Earthquakes › During an Earthquake | Earthquakes › Prepare Before an Earthquake | Earthquakes › During an Earthquake: 3. Hold On | Tsunamis (Ready.gov) › Survive DURING

**Score:** 100%

> Stay calm and protect yourself immediately.  
> If indoors, drop, cover, and hold on—use a sturdy piece of furniture or crouch low with your head covered by your arms.  
> If you're in a car, pull over safely, stop, set the parking brake, and stay inside until shaking stops.  
> If outdoors, move to an open area away from buildings, trees, power lines, and streetlights.  
> Do not run outside—stay put and protect yourself from falling debris.  
> 
> [1]

## tornado-mobile-home

**User:** tornado warning and I live in a mobile home

**Sources:** Tornado Safety: Where to Shelter in Homes, Mobile Homes, Vehicles and Buildings (NOAA Storm Prediction Center) › In a mobile or manufactured home | Tornado Watch, Warning and Emergency: What to Do (NWS) › Tornado watch, warning and emergency | Tornado Safety: Where to Shelter in Homes, Mobile Homes, Vehicles and Buildings (NOAA Storm Prediction Center) › Tornado safety

**Score:** 100%

> If you get a tornado warning and you live in a mobile home, leave immediately. Go to the nearest sturdy building or shelter as soon as possible. Do not wait for the tornado to hit—act quickly to protect yourself from flying debris. Mobile homes are not safe during tornadoes even if tied down. Follow your emergency plan and move to a protected interior room on the lowest floor of a solid structure. 
> 
> [1]

## cpr-adult

**User:** how do I do CPR on an adult

**Sources:** CPR summary › Compressions - begin compressions | Obstructed Airway › Unconscious Victims | CPR summary › Breathing - give breaths | CPR summary › Ambulance - call EMS | CPR summary › Airway - open the airway

**Score:** 100%

> Start with chest compressions. Place the heel of one hand on the center of the chest, lower half of the breastbone, and use two hands if needed. Compress at a rate of at least 100 per minute, pushing at least 2 inches (5 cm) deep. After about 2 minutes (about 5 cycles), check for responsiveness or breathing — if none, continue CPR and call EMS immediately [1]. If you're alone with an adult, call emergency services right away [4].

## fire-no-matches

**User:** how do I start a fire without matches

**Sources:** Fire (ATP 3-50.21 Ch. 5) › Fire: Matches | Fire (ATP 3-50.21 Ch. 5) › Fire: FIRE STARTING TECHNIQUES | Home Fire Escape Plan (Ready.gov) › Conduct a Home Fire Drill

**Score:** 100%

> You can start a fire without matches using methods like flint and steel, a ferro rod, or by using natural materials such as dry leaves and twigs with a heated stone.  
> 
> 1. Use a ferro rod to create sparks—hold it at an angle over tinder and let the spark ignite dry material.  
> 2. If you have flint and steel, strike the steel against the flint to produce sparks that light the tinder.  
> 3. Start from the upwind side to protect your heat source [2].  
> 4. Keep the flame protected from wind by holding it at a slight angle until it grows strong [1].  
> 
> The offline guides don’t cover using a ferro rod or flint specifically, so this information is based on general survival knowledge. Do you have access to any metal tools or natural materials like stone or dry tinder?

## battery-bank

**User:** how do I size a battery bank for my cabin

**Sources:** Lithium Batteries: Thermal Runaway, Spares and Terminal Protection (FAA PackSafe) › Overview (part 1)

**Score:** 67% — missing: days

> The offline guides don't cover how to size a battery bank for a cabin. For that, you’d need information about power consumption (in watts), runtime needs, and system voltage—details not included in the provided excerpts. If you're building or planning a backup power system for your cabin, consider the total load of your devices and desired runtime. Let me know what appliances or systems you’re powering, and I can help with basic sizing steps.

## potassium-iodide

**User:** when should I take potassium iodide

**Sources:** Frequently Asked Questions on Potassium Iodide (KI) (FDA) › 7. For how long should I take potassium iodide (KI)? | Frequently Asked Questions on Potassium Iodide (KI) (FDA) › 6. When should I take potassium iodide (KI)? | Frequently Asked Questions on Potassium Iodide (KI) (FDA) › 8. Who should not take potassium iodide (KI) or should have restricted use? | Frequently Asked Questions on Potassium Iodide (KI) (FDA) › 3. Who really needs to take potassium iodide (KI) after a nuclear radiation release? | Frequently Asked Questions on Potassium Iodide (KI) (FDA) › 12. Should I buy potassium iodide (KI) to keep on hand

**Score:** 50% — missing: thyroid

> You should only take potassium iodide (KI) after a radiological or nuclear event, when local public health or emergency management officials advise it. Do not take it as a preventive measure before exposure. Take it exactly as instructed by local authorities, and do not repeat doses unless specifically advised. The timing is critical—KI works best within 3–4 hours of radiation exposure. Taking more than recommended can cause harm.
> 
> [2]

## water-storage

**User:** how much water should I store for my family

**Sources:** How to Create an Emergency Water Supply › Key points | How to Create an Emergency Water Supply › How much emergency water to store | Principles of Home Canning (USDA Complete Guide, Guide 1) › How much should you can? | How to Create an Emergency Water Supply › Storing the water | How to Create an Emergency Water Supply › Other considerations

**Score:** 100%

> Store at least 1 gallon of water per person per day for 3 days. That’s a total of 3 gallons per person for the emergency supply [1]. If possible, aim for a 2-week supply to cover longer outages [2]. For pregnant women, sick individuals, or in hot climates, store more than this [2]. Always label containers with date and keep them cool, away from sunlight and toxins [4].

## ham-radio

**User:** how do I get started with ham radio

**Sources:** Are You Ready? An In-Depth Guide to Citizen Preparedness (FEMA) › Take Part in Your Community: Donate

**Score:** 100%

> To get started with ham radio, visit the American Radio Relay League website (arrl.org) and look for beginner-friendly resources. You’ll need to pass an exam to earn a license, which is available through local amateur radio clubs or training courses. Start by learning the basics of radio operation, safety, and emergency communication protocols. Consider joining a local ham radio group to practice with others and gain hands-on experience. The exact steps for licensing and study materials are listed on arrl.org.

## insulin-no-power

**User:** how do I keep insulin cold without power

**Sources:** Insulin Storage and Switching Between Products in an Emergency (FDA) › Insulin Storage and Effectiveness: Insulin for Injection

**Score:** 100%

> Keep insulin as cool as possible using cold packs or ice in a sealed container. Avoid freezing insulin — this damages it. Use a thermos or insulated bag with ice to maintain temperatures below 86°F for up to 28 days if the insulin is unopened and stored properly [1]. If insulin has been exposed to extreme heat, throw it away and replace it once power returns. For Awiqli pens, keep them at room temperature below 86°F for no more than 12 weeks total — even when refrigerated [1]. Do not store in direct sunlight or near heat sources.
> 
> Do you have access to a container with insulation or ice that can be sealed?

## ankle-sprain

**User:** I twisted my ankle bad and it's swelling

**Sources:** Survival Medicine (ATP 3-50.21 Ch. 2) › Survival Medicine: Sprains | Rough Framing: Floors, Walls and Stairs (TM 3-34.47 Ch. 6) › Rough Framing: Crawl Spaces

**Score:** 100%

> Follow the RICE steps from guide [1].  
> 1. Rest the ankle and avoid putting weight on it.  
> 2. Apply ice intermittently for up to 48 hours—use cold compresses or improvised ice packs.  
> 3. Wrap the area with a compression bandage to stabilize it, but don’t tighten if circulation is affected.  
> 4. Elevate the foot above heart level to reduce swelling.  
> 
> If you can't move or feel your toes, call 911 immediately.

## seizure

**User:** someone is having a seizure

**Sources:** Seizures › Introduction | First Aid for Seizures › How to keep someone safe during a seizure: Steps to keeping a person safe during a seizure | Seizures › Recognition | First Aid for Seizures › KEY POINTS | First Aid for Seizures › Recognizing a seizure: Seizures may not look like you'd expect.

**Score:** 75% — missing: nothing in the mouth

> Stay calm and keep the person safe.  
> - Remove any nearby objects that could hurt them.  
> - Gently turn them onto their side so air can flow freely.  
> - Watch how long the seizure lasts—if it’s over 5 minutes, call 911 right away.  
> - After the seizure ends, help them sit safely and stay with them until they’re alert.  
> 
> If you don’t know if they have a medical bracelet or condition, check for one before helping.

## flooded-road

**User:** my road is flooded, can I drive through it

**Sources:** Floods › During a Flood | Off-Road and Winter Driving (TC 21-305-20 Ch. 16) › Off-Road and Winter Driving: Low Limbs | Off-Road and Winter Driving (TC 21-305-20 Ch. 16) › Off-Road and Winter Driving: SAND | Floods › If you are under a flood warning | Off-Road and Winter Driving (TC 21-305-20 Ch. 16) › Off-Road and Winter Driving: OFF-ROAD DRIVING

**Score:** 100%

> No, you cannot drive through flooded roads. Moving water can sweep your vehicle away. Just six inches of moving water can knock you down, and one foot can carry a car. Stay off bridges over fast-moving water. If trapped, get to the highest level in your building or stay inside your car if it's stuck. Do not walk, swim, or drive through flood waters—Turn Around, Don’t Drown! [1]

## deep-cut-clean

**User:** how do I clean a deep cut without a doctor

**Sources:** Sanitation and Surviving Without Doctors (NWSS Ch. 12–13) › Chapter 13 Surviving Without Doctors: BENIGN NEGLECT (part 2) | Sanitation and Surviving Without Doctors (NWSS Ch. 12–13) › Chapter 13 Surviving Without Doctors: RADIATION SICKNESS (part 2) | Sanitation and Surviving Without Doctors (NWSS Ch. 12–13) › Chapter 13 Surviving Without Doctors: A TEMPORARY RETURN TO SELF-HELP | Sanitation and Surviving Without Doctors (NWSS Ch. 12–13) › Chapter 13 Surviving Without Doctors: PREVENTION OF THYROID DAMAGE FROM RADIOACTIVE IODINES (part 2)

**Score:** 100%

> The offline guides don't cover cleaning a deep cut without a doctor.  
> 
> 1. Wash your hands thoroughly with water and soap before handling the wound.  
> 2. Rinse the cut under clean running water to remove dirt and debris.  
> 3. Gently apply pressure with a clean cloth or gauze to stop bleeding.  
> 4. If available, use a small amount of saline solution or clean water mixed with baking soda (a mild antiseptic) to disinfect.  
> 5. Cover the wound with a sterile bandage or clean cloth and keep it dry.  
> 
> If you can’t access clean water or have no supplies, wait for help—deep cuts need proper medical attention if they are bleeding heavily or show signs of infection.

## heat-stroke-dad

**User:** my dad is confused and stopped sweating in the heat

**Sources:** Heat-related Illnesses › Heat stroke: Symptoms | Heat-Related Illness & Injury › Heat Exhaustion: Symptoms of Heat Exhaustion | Survival Medicine (ATP 3-50.21 Ch. 2) › Survival Medicine: HEAT INJURIES | Heat-Related Illness & Injury › Heat Stroke: Symptoms of Heat Stroke

**Score:** 67% — missing: fan

> Your dad is showing symptoms of heat stroke.  
> 1. He has confusion and has stopped sweating — this is a medical emergency.  
> 2. Heat stroke can lead to coma, seizures, or death if not treated quickly.  
> 3. You must cool him down immediately: douse his clothes with cool water, especially on the groin, armpits, neck, and back.  
> 4. If he is conscious, have him sip one quart of water slowly.  
> 5. Call 911 right away — even if he seems to be improving, heat stroke is life-threatening.  
> 
> [3]

## ridge-lightning

**User:** I'm caught in a thunderstorm on a ridge

**Sources:** Mountain and Cold Weather Environments (ATP 3-90.97 Ch. 1) › The Environment: Thunderstorms | Thunderstorms & Lightning (Ready.gov) › Stay Safe After Thunderstorms & Lightning | The Mountain Environment (TC 3-97.61 Ch. 1) › Mountain Environment: SECTION IV – MOUNTAIN WEATHER | Thunderstorms & Lightning (Ready.gov) › Stay Safe During Thunderstorms & Lightning | Thunderstorms & Lightning (Ready.gov) › Overview

**Score:** 33% — missing: descend, 30

> Get to a safe indoor building or vehicle immediately. Avoid ridges, peaks, water, and metal objects. Lightning strikes are most likely on exposed ridges during summer storms [1]. Stay away from trees, power lines, or antennas. If you can't reach shelter, crouch low with feet together and keep your head down.  
> 
> If you're in a vehicle, stay inside and avoid contact with metal surfaces.

## find-north

**User:** how do I find north without a compass

**Sources:** Movement and Navigation (ATP 3-50.21 Ch. 7) › Movement and Navigation: Using a Compass | Movement and Navigation (ATP 3-50.21 Ch. 7) › Movement and Navigation: Floating Needle or Leaf Compass

**Score:** 67% — missing: north star

> You can find north without a compass using natural signs or simple tools.  
> 
> 1. Use the sun’s position: In the morning, the sun is east; by midday it's near overhead; in the afternoon it's west. When the sun is directly south (around noon in the Northern Hemisphere), shadows point north.  
> 2. Use a watch method: Hold your watch horizontally and point the hour hand at the sun. In the Northern Hemisphere, bisect the angle between the hour hand and 12 o’clock to find south; north is opposite.  
> 3. Find north with a magnetized needle or natural object: Magnetize a sewing needle (stroke it in one direction), float it on water or on cork/leaf—when aligned, it will point north-south [2].  
> 
> If you're in the Southern Hemisphere, the sun’s path and shadow method still works but south is near noon.  
> 
> Do you know your location in the Northern or Southern Hemisphere?

## fire-then-water

**User:** I'm in the middle of nowhere how do I start a fire

**User:** how do I make sure my water is clean to drink

**Sources:** How to Make Water Safe in an Emergency › Disinfect: Steps for using bleach to disinfect water | How to Make Water Safe in an Emergency › Overview

**Score:** 100%

> To make your water safe to drink in an emergency:  
> 
> 1. If the water is cloudy or murky, filter it through a clean cloth, paper towel, or coffee filter first [1].  
> 2. Let the clear water settle for a few minutes before using it.  
> 3. Add bleach (5–9% sodium hypochlorite) as follows:  
>    - For 1 gallon of water: add 8 drops or ½ mL of bleach [1].  
> 4. Stir well and let the mixture stand for at least 30 minutes before drinking [1].  
> 
> If you don’t have bleach, boiling the water is a safe alternative—bring it to a boil for at least one minute.

## capital-france

**User:** what is the capital of France

**Sources:** none

**Score:** 100%

> The capital of France is Paris.  
> 1. Paris is the political, cultural, and historical center of France.  
> 2. It’s located in the northern part of the country on the Seine River.  
> 3. The city has been a capital for centuries and remains the seat of the French government.


