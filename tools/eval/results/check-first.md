# Chat eval: check-first

| metric | value |
|---|---|
| mean key-point score | 93% |
| scenarios | 5 |
| mean reply length | 1169 chars |
| mean time per turn | 250s |
| replies with [n] citations | 1 / 5 |
| replies with a "not in your guides" line | 0 / 5 |

| scenario | score | chars | time | missing |
|---|---|---|---|---|
| bleeding | 100% | 1348 | 279s |  |
| bleach-gallon | 67% | 942 | 238s | unscented |
| kid-fever | 100% | 1114 | 237s |  |
| choking | 100% | 1295 | 271s |  |
| river-hypothermia | 100% | 1148 | 227s |  |

## bleeding

**User:** my friend cut his leg badly and it won't stop bleeding

**Sources:** Stopping Severe Bleeding (ATP 4-02.11 Ch. 4) › Massive Bleeding Control: TIER 1 SKILLS FOR MASSIVE BLEEDING CONTROL | Stopping Severe Bleeding (ATP 4-02.11 Ch. 4) › Massive Bleeding Control: APPLICATION OF DIRECT PRESSURE | Stopping Severe Bleeding (ATP 4-02.11 Ch. 4) › Massive Bleeding Control: IMPROVISED TOURNIQUET

**Score:** 100%

> Call 911 immediately if your friend can’t breathe or is unconscious. If they are conscious and able to speak, follow these steps:
> 
> 1. Keep the person calm and still. Move them only if absolutely necessary.
> 
> 2. Do not touch the wound directly. Carefully remove any clothing around the cut to see the full area of bleeding—this helps you locate the source.
> 
> 3. Apply direct pressure with a clean cloth or gauze over the main bleed, pressing firmly and holding it for at least three minutes without stopping. If possible, use your hand to press continuously on the wound while keeping the pressure constant.
> 
> 4. If the bleeding continues after three minutes of direct pressure, pack the wound with a hemostatic dressing (like a first aid dressing) or clean gauze, then keep pressing.
> 
> 5. Do not use an improvised tourniquet unless no other method works and there is no TQ available. If you must, fold a cloth to about 1½ to 2 inches wide, tie it tightly with something like a stick (windlass rod), and secure it above the wound—only as a last resort.
> 
> 6. Check every few minutes for signs of improvement or worsening bleeding. Watch for signs of shock: pale skin, cold hands, fast breathing, dizziness.
> 
> Next step: If bleeding doesn’t stop after 10 minutes of direct pressure with packing, get emergency help immediately—even if the wound seems minor.

## bleach-gallon

**User:** how much bleach do I add to a gallon of water

**Sources:** How to Make Water Safe in an Emergency › Disinfect: Steps for using bleach to disinfect water | Disaster Medical Operations Part 2: Mass Casualties, Assessment and Public Health (CERT Basic Training, Unit 4) › Water Purification | Keep Food Safe After a Disaster or Emergency › Steps to take after a flood: Steps to take

**Score:** 67% — missing: unscented

> Add 8 drops of bleach per gallon of water for standard cloudy or dirty water.  
> 
> If the water is cloudy, murky, colored, or very cold, use 16 drops per gallon instead.  
> 
> Use a dropper if available; otherwise, measure with milliliters: add 0.5 mL (half a milliliter) for clear water, 1.0 mL for cloudy water.  
> 
> Stir the mixture well and let it stand for at least 30 minutes before drinking.  
> 
> Watch for the smell of bleach—after 30 minutes, if no strong chlorine odor is present, add six more drops and wait another 15 minutes.  
> 
> Do not use any other chemicals like hydrogen peroxide on wounds or food surfaces.  
> 
> If you don’t have a dropper or measuring device, use a teaspoon: for cloudy water, add about ½ teaspoon of bleach to 5 gallons (use ¼ teaspoon per gallon).  
> 
> [1] specifies this ratio and confirms the 30-minute stand time. [2] gives similar ratios but is unreviewed; we rely on [1] as it provides clear, tested measurements.

## kid-fever

**User:** my kid has a fever of 103 and we have no doctor

**Sources:** Should You Give Kids Medicine for Coughs and Colds? (FDA) › When to Call a Doctor | Diarrhea: Symptoms, Dehydration and When to See a Doctor (NIDDK) › When should I seek a doctor’s help?: Additional symptoms for infants and children | Caring for Someone Sick › Caring for someone sick: Emergency Warning Signs of Flu Complications

**Score:** 100%

> Call 911 if the child is under 12 weeks old, because any fever in infants younger than 12 weeks is a red flag and requires immediate medical care.  
> 
> If your child is older than 12 weeks:  
> 1. Give them oral rehydration solution (like Pedialyte) or water frequently—about 1–2 ounces every 15 minutes if they can drink. Watch for signs of dehydration: no wet diapers in 8 hours, dry mouth, no tears when crying.  
> 2. Use a fever reducer like acetaminophen (Tylenol), but only if you have it and know the dose—use the age/weight chart in your medicine guide or follow the label. Do not give aspirin.  
> 3. Keep them hydrated with small sips of water, electrolyte solution, or breastmilk/formula if applicable. Avoid sugary drinks.  
> 4. Monitor breathing: if they’re breathing fast, have a cough that worsens, show blue lips, or seem unresponsive, call 911 immediately.  
> 
> If the fever lasts more than 2 days without improvement, or if the child becomes lethargic, refuses food or drink, has trouble breathing, or shows signs of dehydration—call 911 now.  
> 
> You said your kid has a fever of 103. How old is your child?

## choking

**User:** someone is choking and can't breathe

**Sources:** Opening and Protecting the Airway (ATP 4-02.11 Ch. 5) › Airway Control: OPENING THE OBSTRUCTED AIRWAY – CASUALTY LYING DOWN OR UNRESPONSIVE (part 1) | Opening and Protecting the Airway (ATP 4-02.11 Ch. 5) › Airway Control: Complete Airway Obstruction

**Score:** 100%

> Call 911 immediately if they can’t breathe and are unconscious.
> 
> If they are conscious and choking:
> 
> - Ask them if they can breathe, speak, or cough.
> - If they can’t, perform back blows and chest thrusts.  
>   - Stand behind them, support their shoulders with one hand, and use the heel of your other hand to give quick, firm back blows between the shoulder blades (5 times).  
>   - Then deliver 5 abdominal thrusts: place one hand just below the ribcage, above the navel; grasp it with your other hand, press quickly upward and inward. Repeat until they start coughing or breathe.
> 
> If they are unconscious:
> 
> - Place them on their back.
> - Open the airway by tilting the head back and lifting the chin (no finger sweep unless you see visible blockage).
> - Check for breathing: if no breaths, begin rescue breathing — cover their mouth with yours, give slow, steady breaths into their mouth until chest rises.  
> - If not breathing, perform 5 abdominal thrusts as above.  
> - Repeat cycles of chest compressions (if no response) and ventilation until help arrives.
> 
> Do not use finger sweeps unless you see an object in the mouth. Stop if they start coughing or breathe — this means the blockage is moving.
> 
> When do you know to stop? When medical help arrives, or when they begin breathing on their own.

## river-hypothermia

**User:** my buddy fell in the river and now he's shivering hard and confused

**Sources:** Cold-Related Illness & Injury › Hypothermia | Survival Medicine (ATP 3-50.21 Ch. 2) › Survival Medicine: Hypothermia | Preventing Hypothermia in the Injured (ATP 4-02.11 Ch. 8) › Hypothermia Control: Chapter 8

**Score:** 100%

> Call 911 immediately if you can.  
> 
> While waiting for help:  
> 1. Get your buddy out of the cold water as quickly as possible. Move him to a warm, dry place.  
> 2. Remove any wet clothing and replace it with dry clothes—especially a dry hat.  
> 3. Wrap him in blankets or any available insulation to keep him from losing heat.  
> 4. Do not give him anything to drink unless he is conscious and able to swallow safely—shivering and confusion mean he may be in severe hypothermia.  
> 5. If he’s shivering, do not try to stop it—this is the body trying to generate heat. Instead, keep him warm with gentle touch or bare skin-on-skin contact if possible (like two people huddled together).  
> 
> Do **not** use heat packs directly on his skin. Do **not** jostle or move him violently.  
> He’s confused and shivering—this is a sign of moderate to severe hypothermia. He may lose consciousness soon.  
> 
> Stay with him, keep him warm, and monitor breathing and pulse. If he stops breathing or loses consciousness, begin CPR if trained—but only if you are certain it’s safe and necessary.  
> 
> When? Wait for 911 responders. They know how to manage hypothermia safely.


