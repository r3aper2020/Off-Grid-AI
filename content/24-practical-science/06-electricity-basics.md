# Electric Current, Ohm's Law, Resistance, Power and Electric Hazards (OpenStax College Physics 2e, 2023)
Source: https://openstax.org/books/college-physics-2e/pages/20-1-current
Aliases: ohms law explained, what is an amp a volt and a watt, how to calculate watts from volts and amps, volts times amps equals watts, what is resistance in a circuit, why do wires get hot, resistivity of copper vs aluminum, wire resistance and length, how much current is dangerous, what is a fuse for, how does electricity kill, electric shock how many amps, ac vs dc difference, 120 volts ac explained, kilowatt hour cost of electricity, how to calculate power bill, why does a bulb burn out when switched on, what is a short circuit, microshock and macroshock, wet skin electric shock risk, how much power does an appliance use

## Electric Current
Electric current is defined to be the rate at which charge flows. A large current, such as that used to start a truck engine, moves a large amount of charge in a small time, whereas a small current, such as that used to operate a hand-held calculator, moves a small amount of charge over a long period of time. In equation form, electric current I is defined to be

I = (Δ Q)/(Δ t),

where Δ Q is the amount of charge passing through a given area in time Δ t. (As in previous chapters, initial time is often taken to be zero, in which case Δ t = t.) (See Figure 20.2.) The SI unit for current is the ampere (A), named for the French physicist André-Marie Ampère (1775–1836). Since I = Δ Q / Δ t, we see that an ampere is one coulomb per second:

1 A = 1 C/s

Not only are fuses and circuit breakers rated in amperes (or amps), so are many electrical appliances.

**Example: Calculating Currents: Current in a Truck Battery and a Handheld Calculator**

(a) What is the current involved when a truck battery sets in motion 720 C of charge in 4.00 s while starting an engine? (b) How long does it take 1.00 C of charge to flow through a handheld calculator if a 0.300-mA current is flowing?

We can use the definition of current in the equation I = Δ Q / Δ t to find the current in part (a), since charge and time are given. In part (b), we rearrange the definition of current and use the given values of charge and current to find the time required.

Entering the given values for charge and time into the definition of current gives

I = (Δ Q)/(Δ t) = (720 C)/(4.00 s) = 180 C/s; = 180 A.

This large value for current illustrates the fact that a large charge is moved in a small amount of time. The currents in these “starter motors” are fairly large because large frictional forces need to be overcome when setting something in motion.

Solving the relationship I = Δ Q / Δ t for time Δ t, and entering the known values for charge and current gives

Δ t = (Δ Q)/I = (1.00 C)/(0.300 × 10^(- 3) C/s); = 3.33 × 10^3 s.

This time is slightly less than an hour. The small current used by the hand-held calculator takes a much longer time to move a smaller charge than the large current of the truck starter. So why can we operate our calculators only seconds after turning them on? It’s because calculators require very little energy. Such small current and energy demands allow handheld calculators to operate from solar cells or to get many hours of use out of small batteries. Remember, calculators do not have moving parts in the same way that a truck engine has with cylinders and pistons, so the technology requires smaller currents.

Figure 20.3 shows a simple circuit and the standard schematic representation of a battery, conducting path, and load (a resistor). Schematics are very useful in visualizing the main features of a circuit. A single schematic can represent a wide variety of situations. The schematic in Figure 20.3 (b), for example, can represent anything from a truck battery connected to a headlight lighting the street in front of the truck to a small battery connected to a penlight lighting a keyhole in a door. Such schematics are useful because the analysis is the same for a wide variety of situations. We need to understand a few schematics to apply the concepts and analysis to many more situations.

Note that the direction of current flow in Figure 20.3 is from positive to negative. The direction of conventional current is the direction that positive charge would flow. Depending on the situation, positive charges, negative charges, or both may move. In metal wires, for example, current is carried by electrons—that is, negative charges move. In ionic solutions, such as salt water, both positive and negative charges move. This is also true in nerve cells. A Van de Graaff generator used for nuclear research can produce a current of pure positive charges, such as protons. Figure 20.4 illustrates the movement of charged particles that compose a current. The fact that conventional current is taken to be in the direction that positive charge would flow can be traced back to American politician and scientist Benjamin Franklin in the 1700s. He named the type of charge associated with electrons negative, long before they were known to carry current in so many situations. Franklin, in fact, was totally unaware of the small-scale structure of electricity.

It is important to realize that there is an electric field in conductors responsible for producing the current, as illustrated in Figure 20.4. Unlike static electricity, where a conductor in equilibrium cannot have an electric field in it, conductors carrying a current have an electric field and are not in static equilibrium. An electric field is needed to supply energy to move the charges.

**Making Connections: Take-Home Investigation—Electric Current Illustration**

Find a straw and little peas that can move freely in the straw. Place the straw flat on a table and fill the straw with peas. When you pop one pea in at one end, a different pea should pop out the other end. This demonstration is an analogy for an electric current. Identify what compares to the electrons and what compares to the supply of energy. What other analogies can you find for an electric current?

Note that the flow of peas is based on the peas physically bumping into each other; electrons flow due to mutually repulsive electrostatic forces.

**Example: Calculating the Number of Electrons that Move through a Calculator**

If the 0.300-mA current through the calculator mentioned in the Example 20.1 example is carried by electrons, how many electrons per second pass through it?

The current calculated in the previous example was defined for the flow of positive charge. For electrons, the magnitude is the same, but the sign is opposite, I_electrons = − 0.300 × 10^−3 C/s.Since each electron (e^(−)) has a charge of –1.60 × 10^(− 19) C, we can convert the current in coulombs per second to electrons per second.

Starting with the definition of current, we have

I_electrons = (Δ Q_electrons)/(Δ t) = (–0.300 × 10^(− 3) C)/s.

We divide this by the charge per electron, so that

(e^(–))/s = (–0.300 × 10^(– 3) C)/s × (1 e^(–))/(–1.60 × 10^(− 19) C); = 1.88 × 10^15 (e^(–))/s.

There are so many charged particles moving, even in small currents, that individual charges are not noticed, just as individual water molecules are not noticed in water flow. Even more amazing is that they do not always keep moving forward like soldiers in a parade. Rather they are like a crowd of people with movement in different directions but a general trend to move forward. There are lots of collisions with atoms in the metal wire and, of course, with other electrons.

## 20.2 Ohm’s Law: Resistance and Simple Circuits
What drives current? We can think of various devices—such as batteries, generators, wall outlets, and so on—which are necessary to maintain a current. All such devices create a potential difference and are loosely referred to as voltage sources. When a voltage source is connected to a conductor, it applies a potential difference V that creates an electric field. The electric field in turn exerts force on charges, causing current.

## Ohm’s Law
The current that flows through most substances is directly proportional to the voltage V applied to it. The German physicist Georg Simon Ohm (1787–1854) was the first to demonstrate experimentally that the current in a metal wire is directly proportional to the voltage applied:

I ∝ V.

This important relationship is known as Ohm’s law. It can be viewed as a cause-and-effect relationship, with voltage the cause and current the effect. This is an empirical law like that for friction—an experimentally observed phenomenon. Such a linear relationship doesn’t always occur.

## Resistance and Simple Circuits
If voltage drives current, what impedes it? The electric property that impedes current (crudely similar to friction and air resistance) is called resistance R. Collisions of moving charges with atoms and molecules in a substance transfer energy to the substance and limit current. Resistance is defined as inversely proportional to current, or

I ∝ 1/R.

Thus, for example, current is cut in half if resistance doubles. Combining the relationships of current to voltage and current to resistance gives

I = V/R.

This relationship is also called Ohm’s law. Ohm’s law in this form really defines resistance for certain materials. Ohm’s law (like Hooke’s law) is not universally valid. The many substances for which Ohm’s law holds are called ohmic. These include good conductors like copper and aluminum, and some poor conductors under certain circumstances. Ohmic materials have a resistance R that is independent of voltage V and current I. An object that has simple resistance is called a resistor, even if its resistance is small. The unit for resistance is an ohm and is given the symbol Ω (upper case Greek omega). Rearranging I = V/R gives R = V/I, and so the units of resistance are 1 ohm = 1 volt per ampere:

1 Ω = 1 V/A.

Figure 20.8 shows the schematic for a simple circuit. A simple circuit has a single voltage source and a single resistor. The wires connecting the voltage source to the resistor can be assumed to have negligible resistance, or their resistance can be included in R.

**Example: Calculating Resistance: An Automobile Headlight**

What is the resistance of an automobile headlight through which 2.50 A flows when 12.0 V is applied to it?

We can rearrange Ohm’s law as stated by I = V/R and use it to find the resistance.

Rearranging I = V/R and substituting known values gives

R = V/I = (12.0 V)/(2.50 A) = 4.80 Ω.

This is a relatively small resistance, but it is larger than the cold resistance of the headlight. As we shall see in Resistance and Resistivity, resistance usually increases with temperature, and so the bulb has a lower resistance when it is first switched on and will draw considerably more current during its brief warm-up period.

Resistances range over many orders of magnitude. Some ceramic insulators, such as those used to support power lines, have resistances of 10^12 Ω or more. A dry person may have a hand-to-foot resistance of 10^5 Ω, whereas the resistance of the human heart is about 10^3 Ω. A meter-long piece of large-diameter copper wire may have a resistance of 10^(− 5) Ω, and superconductors have no resistance at all (they are non-ohmic). Resistance is related to the shape of an object and the material of which it is composed, as will be seen in Resistance and Resistivity.

Additional insight is gained by solving I = V/R for V, yielding

V = IR.

This expression for V can be interpreted as the voltage drop across a resistor produced by the flow of current I. The phrase IR drop is often used for this voltage. For instance, the headlight in Example 20.4 has an IR drop of 12.0 V. If voltage is measured at various points in a circuit, it will be seen to increase at the voltage source and decrease at the resistor. Voltage is similar to fluid pressure. The voltage source is like a pump, creating a pressure difference, causing current—the flow of charge. The resistor is like a pipe that reduces pressure and limits flow because of its resistance. Conservation of energy has important consequences here. The voltage source supplies energy (causing an electric field and a current), and the resistor converts it to another form (such as thermal energy). In a simple circuit (one with a single simple resistor), the voltage supplied by the source equals the voltage drop across the resistor, since PE = q Δ V, and the same q flows through each. Thus the energy supplied by the voltage source and the energy converted by the resistor are equal. (See Figure 20.9.)

## Material and Shape Dependence of Resistance
The resistance of an object depends on its shape and the material of which it is composed. The cylindrical resistor in Figure 20.10 is easy to analyze, and, by so doing, we can gain insight into the resistance of more complicated shapes. As you might expect, the cylinder’s electric resistance R is directly proportional to its length L, similar to the resistance of a pipe to fluid flow. The longer the cylinder, the more collisions charges will make with its atoms. The greater the diameter of the cylinder, the more current it can carry (again similar to the flow of fluid through a pipe). In fact, R is inversely proportional to the cylinder’s cross-sectional area A.

For a given shape, the resistance depends on the material of which the object is composed. Different materials offer different resistance to the flow of charge. We define the resistivity ρ of a substance so that the resistance R of an object is directly proportional to ρ. Resistivity ρ is an intrinsic property of a material, independent of its shape or size. The resistance R of a uniform cylinder of length L, of cross-sectional area A, and made of a material with resistivity ρ, is

R = ρL/A.

Table 20.1 gives representative values of ρ. The materials listed in the table are separated into categories of conductors, semiconductors, and insulators, based on broad groupings of resistivities. Conductors have the smallest resistivities, and insulators have the largest; semiconductors have intermediate resistivities. Conductors have varying but large free charge densities, whereas most charges in insulators are bound to atoms and are not free to move. Semiconductors are intermediate, having far fewer free charges than conductors, but having properties that make the number of free charges depend strongly on the type and amount of impurities in the semiconductor. These unique properties of semiconductors are put to use in modern electronics, as will be explored in later chapters.

Table 20.1 Resistivities ρ of Various materials at 20º C

Material | Resistivity ρ (Ω ⋅ m)
Conductors | 
Silver | 1.59 × 10^(− 8)
Copper | 1.72 × 10^(− 8)
Gold | 2.44 × 10^(− 8)
Aluminum | 2.65 × 10^(− 8)
Tungsten | 5.6 × 10^(− 8)
Iron | 9.71 × 10^(− 8)
Platinum | 10.6 × 10^(− 8)
Steel | 20 × 10^(− 8)
Lead | 22 × 10^(− 8)
Manganin (Cu, Mn, Ni alloy) | 44 × 10^(− 8)
Constantan (Cu, Ni alloy) | 49 × 10^(− 8)
Mercury | 96 × 10^(− 8)
Nichrome (Ni, Fe, Cr alloy) | 100 × 10^(− 8)
Semiconductors | 
Carbon (pure) | 3.5 × 10^(–5)
Carbon | (3.5 − 60) × 10^(–5)
Germanium (pure) | 600 × 10^(− 3)
Germanium | (1 − 600) × 10^(− 3)
Silicon (pure) | 2300
Silicon | 0.1–2300
Insulators | 
Amber | 5 × 10^14
Glass | 10^9 − 10^14
Lucite | (>10)^13
Mica | 10^11 − 10^15
Quartz (fused) | 75 × 10^16
Rubber (hard) | 10^13 − 10^16
Sulfur | 10^15
Teflon | (>10)^13
Wood | 10^8 − 10^11

**Example: Calculating Resistor Diameter: A Headlight Filament**

A car headlight filament is made of tungsten and has a cold resistance of 0.350 Ω. If the filament is a cylinder 4.00 cm long (it may be coiled to save space), what is its diameter?

We can rearrange the equation R = ρL/A to find the cross-sectional area A of the filament from the given information. Then its diameter can be found by assuming it has a circular cross-section.

The cross-sectional area, found by rearranging the expression for the resistance of a cylinder given in R = ρL/A, is

A = ρL/R.

Substituting the given values, and taking ρ from Table 20.1, yields

A = ((5.6 × 10^(–8) Ω ⋅ m) (4.00 × 10^(–2) m))/(0.350 Ω); = 6.40 × 10^(–9) m^2.

The area of a circle is related to its diameter D by

A = (πD^2)/4.

Solving for the diameter D, and substituting the value found for A, gives

D = 2 ((A/π))^1/2 = 2 (((6.40 × 10^(–9) m^2)/3.14))^1/2; = 9.0 × 10^(–5) m.

The diameter is just under a tenth of a millimeter. It is quoted to only two digits, because ρ is known to only two digits.

## Temperature Variation of Resistance
The resistivity of all materials depends on temperature. Some even become superconductors (zero resistivity) at very low temperatures. (See Figure 20.11.) Conversely, the resistivity of conductors increases with increasing temperature. Since the atoms vibrate more rapidly and over larger distances at higher temperatures, the electrons moving through a metal make more collisions, effectively making the resistivity higher. Over relatively small temperature changes (about 100º C or less), resistivity ρ varies with temperature change Δ T as expressed in the following equation

ρ = ρ_0 (1 + α Δ T),

where ρ_0 is the original resistivity and α is the temperature coefficient of resistivity. (See the values of α in Table 20.2 below.) For larger temperature changes, α may vary or a nonlinear equation may be needed to find ρ. Note that α is positive for metals, meaning their resistivity increases with temperature. Some alloys have been developed specifically to have a small temperature dependence. Manganin (which is made of copper, manganese and nickel), for example, has α close to zero (to three digits on the scale in Table 20.2), and so its resistivity varies only slightly with temperature. This is useful for making a temperature-independent resistance standard, for example.

Table 20.2 Tempature Coefficients of Resistivity α

Material | Coefficient α (1/°C)
Conductors
Silver | 3.8 × 10^(− 3)
Copper | 3.9 × 10^(− 3)
Gold | 3.4 × 10^(− 3)
Aluminum | 3.9 × 10^(− 3)
Tungsten | 4.5 × 10^(− 3)
Iron | 5.0 × 10^(− 3)
Platinum | 3.93 × 10^(− 3)
Lead | 3.9 × 10^(− 3)
Manganin (Cu, Mn, Ni alloy) | 0.000 × 10^(− 3)
Constantan (Cu, Ni alloy) | 0.002 × 10^(− 3)
Mercury | 0.89 × 10^(− 3)
Nichrome (Ni, Fe, Cr alloy) | 0.4 × 10^(− 3)
Semiconductors
Carbon (pure) | − 0.5 × 10^(− 3)
Germanium (pure) | − 50 × 10^(− 3)
Silicon (pure) | − 70 × 10^(− 3)

Note also that α is negative for the semiconductors listed in Table 20.2, meaning that their resistivity decreases with increasing temperature. They become better conductors at higher temperature, because increased thermal agitation increases the number of free charges available to carry current. This property of decreasing ρ with temperature is also related to the type and amount of impurities present in the semiconductors.

The resistance of an object also depends on temperature, since R_0 is directly proportional to ρ. For a cylinder we know R = ρL / A, and so, if L and A do not change greatly with temperature, R will have the same temperature dependence as ρ. (Examination of the coefficients of linear expansion shows them to be about two orders of magnitude less than typical temperature coefficients of resistivity, and so the effect of temperature on L and A is about two orders of magnitude less than on ρ.) Thus,

R = R_0 (1 + α Δ T)

is the temperature dependence of the resistance of an object, where R_0 is the original resistance and R is the resistance after a temperature change Δ T. Numerous thermometers are based on the effect of temperature on resistance. (See Figure 20.12.) One of the most common is the thermistor, a semiconductor crystal with a strong temperature dependence, the resistance of which is measured to obtain its temperature. The device is small, so that it quickly comes into thermal equilibrium with the part of a person it touches.

**Example: Calculating Resistance: Hot-Filament Resistance**

Although caution must be used in applying ρ = ρ_0 (1 + α Δ T) and R = R_0 (1 + α Δ T) for temperature changes greater than 100º C, for tungsten the equations work reasonably well for very large temperature changes. What, then, is the resistance of the tungsten filament in the previous example if its temperature is increased from room temperature (20ºC) to a typical operating temperature of 2850º C ?

This is a straightforward application of R = R_0 (1 + α Δ T), since the original resistance of the filament was given to be R_0 = 0.350 Ω, and the temperature change is Δ T = 2830º C.

The hot resistance R is obtained by entering known values into the above equation:

R = R_0 (1 + α Δ T); = (0.350 Ω) [ 1 + (4.5 × 10^(–3) / ºC) (2830º C) ]; = 4.8 Ω.

This value is consistent with the headlight resistance example in Ohm’s Law: Resistance and Simple Circuits.

## Power in Electric Circuits
Power is associated by many people with electricity. Knowing that power is the rate of energy use or energy conversion, what is the expression for electric power? Power transmission lines might come to mind. We also think of lightbulbs in terms of their power ratings in watts. Let us compare a 25-W bulb with a 60-W bulb. (See Figure 20.13(a).) Since both operate on the same voltage, the 60-W bulb must draw more current to have a greater power rating. Thus the 60-W bulb’s resistance must be lower than that of a 25-W bulb. If we increase voltage, we also increase power. For example, when a 25-W bulb that is designed to operate on 120 V is connected to 240 V, it briefly glows very brightly and then burns out. Precisely how are voltage, current, and resistance related to electric power?

Electric energy depends on both the voltage involved and the charge moved. This is expressed most simply as PE = qV, where q is the charge moved and V is the voltage (or more precisely, the potential difference the charge moves through). Power is the rate at which energy is moved, and so electric power is

P = PE/t = qV/t.

Recognizing that current is I = q / t (note that Δ t = t here), the expression for power becomes

P = IV.

Electric power (P) is simply the product of current times voltage. Power has familiar units of watts. Since the SI unit for potential energy (PE) is the joule, power has units of joules per second, or watts. Thus, 1 A ⋅ V = 1 W. For example, cars often have one or more auxiliary power outlets with which you can charge a cell phone or other electronic devices. These outlets may be rated at 20 A, so that the circuit can deliver a maximum power P = IV = (20 A) (12 V) = 240 W. In some applications, electric power may be expressed as volt-amperes or even kilovolt-amperes (1 kA ⋅ V = 1 kW).

To see the relationship of power to resistance, we combine Ohm’s law with P = IV. Substituting I = V/R gives P = (V / R) V = V^2 / R. Similarly, substituting V = IR gives P = I (IR) = I^2 R. Three expressions for electric power are listed together here for convenience:

P = IV

P = (V^2)/R

P = I^2 R.

Note that the first equation is always valid, whereas the other two can be used only for resistors. In a simple circuit, with one voltage source and a single resistor, the power supplied by the voltage source and that dissipated by the resistor are identical. (In more complicated circuits, P can be the power dissipated by a single device and not the total power in the circuit.)

Different insights can be gained from the three different expressions for electric power. For example, P = V^2 / R implies that the lower the resistance connected to a given voltage source, the greater the power delivered. Furthermore, since voltage is squared in P = V^2 / R, the effect of applying a higher voltage is perhaps greater than expected. Thus, when the voltage is doubled to a 25-W bulb, its power nearly quadruples to about 100 W, burning it out. If the bulb’s resistance remained constant, its power would be exactly 100 W, but at the higher temperature its resistance is higher, too.

**Example: Calculating Power Dissipation and Current: Hot and Cold Power**

(a) Consider the examples given in Ohm’s Law: Resistance and Simple Circuits and Resistance and Resistivity. Then find the power dissipated by the car headlight in these examples, both when it is hot and when it is cold. (b) What current does it draw when cold?

For the hot headlight, we know voltage and current, so we can use P = IV to find the power. For the cold headlight, we know the voltage and resistance, so we can use P = V^2 / R to find the power.

Entering the known values of current and voltage for the hot headlight, we obtain

P = IV = (2.50 A) (12.0 V) = 30.0 W.

The cold resistance was 0.350 Ω, and so the power it uses when first switched on is

P = (V^2)/R = ((12.0 V)^2)/(0.350 Ω) = 411 W.

The 30 W dissipated by the hot headlight is typical. But the 411 W when cold is surprisingly higher. The initial power quickly decreases as the bulb’s temperature increases and its resistance increases.

The current when the bulb is cold can be found several different ways. We rearrange one of the power equations, P = I^2 R, and enter known values, obtaining

I = sqrt(P/R) = sqrt((411 W)/(0.350 Ω)) = 34.3 A.

The cold current is remarkably higher than the steady-state value of 2.50 A, but the current will quickly decline to that value as the bulb’s temperature increases. Most fuses and circuit breakers (used to limit the current in a circuit) are designed to tolerate very high currents briefly as a device comes on. In some cases, such as with electric motors, the current remains high for several seconds, necessitating special “slow blow” fuses.

## The Cost of Electricity
The more electric appliances you use and the longer they are left on, the higher your electric bill. This familiar fact is based on the relationship between energy and power. You pay for the energy used. Since P = E / t, we see that

E = Pt

is the energy used by a device using power P for a time interval t. For example, the more lightbulbs burning, the greater P used; the longer they are on, the greater t is. The energy unit on electric bills is the kilowatt-hour (kW ⋅ h), consistent with the relationship E = Pt. It is easy to estimate the cost of operating electric appliances if you have some idea of their power consumption rate in watts or kilowatts, the time they are on in hours, and the cost per kilowatt-hour for your electric utility. Kilowatt-hours, like all other specialized energy units such as food calories, can be converted to joules. You can prove to yourself that 1 kW ⋅ h = 3.6 × 10^6 J.

The electrical energy (E) used can be reduced either by reducing the time of use or by reducing the power consumption of that appliance or fixture. This will not only reduce the cost, but it will also result in a reduced impact on the environment. Improvements to lighting are some of the fastest ways to reduce the electrical energy used in a home or business. About 20% of a home’s use of energy goes to lighting, while the number for commercial establishments is closer to 40%. Fluorescent lights are about four times more efficient than incandescent lights—this is true for both the long tubes and the compact fluorescent lights (CFL). (See Figure 20.13(b).) Thus, a 60-W incandescent bulb can be replaced by a 15-W CFL, which has the same brightness and color. CFLs have a bent tube inside a globe or a spiral-shaped tube, all connected to a standard screw-in base that fits standard incandescent light sockets. (Original problems with color, flicker, shape, and high initial investment for CFLs have been addressed in recent years.) The heat transfer from these CFLs is less, and they last up to 10 times longer. The significance of an investment in such bulbs is addressed in the next example. New white LED lights (which are clusters of small LED bulbs) are even more efficient (twice that of CFLs) and last 5 times longer than CFLs. However, their cost is still high.

**Making Connections: Energy, Power, and Time**

The relationship E = Pt is one that you will find useful in many different contexts. The energy your body uses in exercise is related to the power level and duration of your activity, for example. The amount of heating by a power source is related to the power level and time it is applied. Even the radiation dose of an X-ray image is related to the power and time of exposure.

**Example: Calculating the Cost Effectiveness of Compact Fluorescent Lights (CFL)**

If the cost of electricity in your area is 12 cents per kWh, what is the total cost (capital plus operation) of using a 60-W incandescent bulb for 1000 hours (the lifetime of that bulb) if the bulb cost 25 cents? (b) If we replace this bulb with a compact fluorescent light that provides the same light output, but at one-quarter the wattage, and which costs $1.50 but lasts 10 times longer (10,000 hours), what will that total cost be?

To find the operating cost, we first find the energy used in kilowatt-hours and then multiply by the cost per kilowatt-hour.

The energy used in kilowatt-hours is found by entering the power and time into the expression for energy:

E = Pt = (60 W) (1000 h) = 60,000 W ⋅ h.

In kilowatt-hours, this is

E = 60.0 kW ⋅ h.

Now the electricity cost is

cost = (60.0 kW ⋅ h) ($0.12 /kW ⋅ h) = $ 7.20.

The total cost, including the cost of the bulb, will be $7.45 for 1000 hours (about one-half year at 5 hours per day).

Since the CFL uses only 15 W and not 60 W, the electricity cost will be $7.20/4 = $1.80. The CFL will last 10 times longer than the incandescent, so that the investment cost will be 1/10 of the bulb cost for that time period of use, or 0.1($1.50) = $0.15. Therefore, the total cost will be $1.95 for 1000 hours.

Therefore, it is much cheaper to use the CFLs, even though the initial investment is higher. The increased cost of labor that a business must include for replacing the incandescent bulbs more often has not been figured in here.

**Making Connections: Take-Home Experiment—Electrical Energy Use Inventory**

1) Make a list of the power ratings on a range of appliances in your home or room. Explain why something like a toaster has a higher rating than a digital clock. Estimate the energy consumed by these appliances in an average day (by estimating their time of use). Some appliances might only state the operating current. If the household voltage is 120 V, then use P = IV. 2) Check out the total wattage used in the rest rooms of your school’s floor or building. (You might need to assume the long fluorescent lights in use are rated at 32 W.) Suppose that the building was closed all weekend and that these lights were left on from 6 p.m. Friday until 8 a.m. Monday. What would this oversight cost? How about for an entire year of weekends?

## Alternating Current
Most of the examples dealt with so far, and particularly those utilizing batteries, have constant voltage sources. Once the current is established, it is thus also a constant. Direct current (DC) is the flow of electric charge in only one direction. It is the steady state of a constant-voltage circuit. Most well-known applications, however, use a time-varying voltage source. Alternating current (AC) is the flow of electric charge that periodically reverses direction. If the source varies periodically, particularly sinusoidally, the circuit is known as an alternating current circuit. Examples include the commercial and residential power that serves so many of our needs. Figure 20.14 shows graphs of voltage and current versus time for typical DC and AC power. The AC voltages and frequencies commonly used in homes and businesses vary around the world.

Figure 20.15 shows a schematic of a simple circuit with an AC voltage source. The voltage between the terminals fluctuates as shown, with the AC voltage given by

V = V_0 sin 2 π ft,

where V is the voltage at time t, V_0 is the peak voltage, and f is the frequency in hertz. For this simple resistance circuit, I = V/R, and so the AC current is

I = I_0 sin 2 π ft,

where I is the current at time t, and I_0 = V_0 /R is the peak current. For this example, the voltage and current are said to be in phase, as seen in Figure 20.14(b).

Current in the resistor alternates back and forth just like the driving voltage, since I = V/R. If the resistor is a fluorescent light bulb, for example, it brightens and dims 120 times per second as the current repeatedly goes through zero. A 120-Hz flicker is too rapid for your eyes to detect, but if you wave your hand back and forth between your face and a fluorescent light, you will see a stroboscopic effect evidencing AC. The fact that the light output fluctuates means that the power is fluctuating. The power supplied is P = IV. Using the expressions for I and V above, we see that the time dependence of power is P = I_0 V_0 sin^2 2 π ft, as shown in Figure 20.16.

**Making Connections: Take-Home Experiment—AC/DC Lights**

Wave your hand back and forth between your face and a fluorescent light bulb. Do you observe the same thing with the headlights on your car? Explain what you observe. Warning: Do not look directly at very bright light.

We are most often concerned with average power rather than its fluctuations—that 60-W light bulb in your desk lamp has an average power consumption of 60 W, for example. As illustrated in Figure 20.16, the average power P_ave is

P_ave = 1/2 I_0 V_0.

This is evident from the graph, since the areas above and below the (1 / 2) I_0 V_0 line are equal, but it can also be proven using trigonometric identities. Similarly, we define an average or rms current I_rms and average or rms voltage V_rms to be, respectively,

I_rms = (I_0)/(sqrt(2))

and

V_rms = (V_0)/(sqrt(2)).

where rms stands for root mean square, a particular kind of average. In general, to obtain a root mean square, the particular quantity is squared, its mean (or average) is found, and the square root is taken. This is useful for AC, since the average value is zero. Now,

P_ave = I_rms V_rms,

which gives

P_ave = (I_0)/(sqrt(2)) ⋅ (V_0)/(sqrt(2)) = 1/2 I_0 V_0,

as stated above. It is standard practice to quote I_rms, V_rms, and P_ave rather than the peak values. For example, most household electricity is 120 V AC, which means that V_rms is 120 V. The common 10-A circuit breaker will interrupt a sustained I_rms greater than 10 A. Your 1.0-kW microwave oven consumes P_ave = 1.0 kW, and so on. You can think of these rms and average values as the equivalent DC values for a simple resistive circuit.

To summarize, when dealing with AC, Ohm’s law and the equations for power are completely analogous to those for DC, but rms and average values are used for AC. Thus, for AC, Ohm’s law is written

I_rms = (V_rms)/R.

The various expressions for AC power P_ave are

P_ave = I_rms V_rms,

P_ave = (V_rms^2)/R,

and

P_ave = I_rms^2 R.

**Example: Peak Voltage and Power for AC**

(a) What is the value of the peak voltage for 120-V AC power? (b) What is the peak power consumption rate of a 60.0-W AC light bulb?

We are told that V_rms is 120 V and P_ave is 60.0 W. We can use V_rms = (V_0)/(sqrt(2)) to find the peak voltage, and we can manipulate the definition of power to find the peak power from the given average power.

Solving the equation V_rms = (V_0)/(sqrt(2)) for the peak voltage V_0 and substituting the known value for V_rms gives

V_0 = sqrt(2) V_rms = 1.414 (120 V) = 170 V.

This means that the AC voltage swings from 170 V to –170 V and back 60 times every second. An equivalent DC voltage is a constant 120 V.

Peak power is peak current times peak voltage. Thus,

P_0 = I_0 V_0 = 2 (1/2 I_0 V_0) = 2 P_ave.

We know the average power is 60.0 W, and so

P_0 = 2 (60.0 W) = 120 W.

So the power swings from zero to 120 W one hundred twenty times per second (twice each cycle), and the power averages 60 W.

## Why Use AC for Power Distribution?
Most large power-distribution systems are AC. Moreover, the power is transmitted at much higher voltages than the 120-V AC (240 V in most parts of the world) we use in homes and on the job. Economies of scale make it cheaper to build a few very large electric power-generation plants than to build numerous small ones. This necessitates sending power long distances, and it is obviously important that energy losses en route be minimized. High voltages can be transmitted with much smaller power losses than low voltages, as we shall see. (See Figure 20.17.) For safety reasons, the voltage at the user is reduced to familiar values. The crucial factor is that it is much easier to increase and decrease AC voltages than DC, so AC is used in most large power distribution systems.

**Example: Power Losses Are Less for High-Voltage Transmission**

(a) What current is needed to transmit 100 MW of power at 200 kV? (b) What is the power dissipated by the transmission lines if they have a resistance of 1.00 Ω ? (c) What percentage of the power is lost in the transmission lines?

We are given P_ave = 100 MW, V_rms = 200 kV, and the resistance of the lines is R = 1.00 Ω. Using these givens, we can find the current flowing (from P = IV) and then the power dissipated in the lines (P = I^2 R), and we take the ratio to the total power transmitted.

To find the current, we rearrange the relationship P_ave = I_rms V_rms and substitute known values. This gives

I_rms = (P_ave)/(V_rms) = (100 × 10^6 W)/(200 × 10^3 V) = 500 A.

Knowing the current and given the resistance of the lines, the power dissipated in them is found from P_ave = I_rms^2 R. Substituting the known values gives

P_ave = I_rms^2 R = (500 A)^2 (1.00 Ω) = 250 kW.

The percent loss is the ratio of this lost power to the total or input power, multiplied by 100:

% loss= (250 kW)/(100 MW) × 100 = 0.250 %.

One-fourth of a percent is an acceptable loss. Note that if 100 MW of power had been transmitted at 25 kV, then a current of 4000 A would have been needed. This would result in a power loss in the lines of 16.0 MW, or 16.0% rather than 0.250%. The lower the voltage, the more current is needed, and the greater the power loss in the fixed-resistance transmission lines. Of course, lower-resistance lines can be built, but this requires larger and more expensive wires. If superconducting lines could be economically produced, there would be no loss in the transmission lines at all. But, as we shall see in a later chapter, there is a limit to current in superconductors, too. In short, high voltages are more economical for transmitting power, and AC voltage is much easier to raise and lower, so that AC is used in most large-scale power distribution systems.

It is widely recognized that high voltages pose greater hazards than low voltages. But, in fact, some high voltages, such as those associated with common static electricity, can be harmless. So it is not voltage alone that determines a hazard. It is not so widely recognized that AC shocks are often more harmful than similar DC shocks. Thomas Edison thought that AC shocks were more harmful and set up a DC power-distribution system in New York City in the late 1800s. There were bitter fights, in particular between Edison and George Westinghouse and Nikola Tesla, who were advocating the use of AC in early power-distribution systems. AC has prevailed largely due to transformers and lower power losses with high-voltage transmission.

## 20.6 Electric Hazards and the Human Body
There are two known hazards of electricity—thermal and shock. A thermal hazard is one where excessive electric power causes undesired thermal effects, such as starting a fire in the wall of a house. A shock hazard occurs when electric current passes through a person. Shocks range in severity from painful, but otherwise harmless, to heart-stopping lethality. This section considers these hazards and the various factors affecting them in a quantitative manner. Electrical Safety: Systems and Devices will consider systems and devices for preventing electrical hazards.

## Thermal Hazards
Electric power causes undesired heating effects whenever electric energy is converted to thermal energy at a rate faster than it can be safely dissipated. A classic example of this is the short circuit, a low-resistance path between terminals of a voltage source. An example of a short circuit is shown in Figure 20.18. Insulation on wires leading to an appliance has worn through, allowing the two wires to come into contact. Such an undesired contact with a high voltage is called a short. Since the resistance of the short, r, is very small, the power dissipated in the short, P = V^2 / r, is very large. For example, if V is 120 V and r is 0.100 Ω, then the power is 144 kW, much greater than that used by a typical household appliance. Thermal energy delivered at this rate will very quickly raise the temperature of surrounding materials, melting or perhaps igniting them.

One particularly insidious aspect of a short circuit is that its resistance may actually be decreased due to the increase in temperature. This can happen if the short creates ionization. These charged atoms and molecules are free to move and, thus, lower the resistance r. Since P = V^2 / r, the power dissipated in the short rises, possibly causing more ionization, more power, and so on. High voltages, such as the 480-V AC used in some industrial applications, lend themselves to this hazard, because higher voltages create higher initial power production in a short.

Another serious, but less dramatic, thermal hazard occurs when wires supplying power to a user are overloaded with too great a current. As discussed in the previous section, the power dissipated in the supply wires is P = I^2 R_w, where R_w is the resistance of the wires and I the current flowing through them. If either I or R_w is too large, the wires overheat. For example, a worn appliance cord (with some of its braided wires broken) may have R_w = 2.00 Ω rather than the 0.100 Ω it should be. If 10.0 A of current passes through the cord, then P = I^2 R_w = 200 W is dissipated in the cord—much more than is safe. Similarly, if a wire with a 0.100 - Ω resistance is meant to carry a few amps, but is instead carrying 100 A, it will severely overheat. The power dissipated in the wire will in that case be P = 1000 W. Fuses and circuit breakers are used to limit excessive currents. (See Figure 20.19 and Figure 20.20.) Each device opens the circuit automatically when a sustained current exceeds safe limits.

Fuses and circuit breakers for typical household voltages and currents are relatively simple to produce, but those for large voltages and currents experience special problems. For example, when a circuit breaker tries to interrupt the flow of high-voltage electricity, a spark can jump across its points that ionizes the air in the gap and allows the current to continue flowing. Large circuit breakers found in power-distribution systems employ insulating gas and even use jets of gas to blow out such sparks. Here AC is safer than DC, since AC current goes through zero 120 times per second, giving a quick opportunity to extinguish these arcs.

## Shock Hazards
Electrical currents through people produce tremendously varied effects. An electrical current can be used to block back pain. The possibility of using electrical current to stimulate muscle action in paralyzed limbs, perhaps allowing paraplegics to walk, is under study. TV dramatizations in which electrical shocks are used to bring a heart attack victim out of ventricular fibrillation (a massively irregular, often fatal, beating of the heart) are more than common. Yet most electrical shock fatalities occur because a current put the heart into fibrillation. A pacemaker uses electrical shocks to stimulate the heart to beat properly. Some fatal shocks do not produce burns, but warts can be safely burned off with electric current (though freezing using liquid nitrogen is now more common). Of course, there are consistent explanations for these disparate effects. The major factors upon which the effects of electrical shock depend are

- The amount of current I

- The path taken by the current

- The duration of the shock

- The frequency f of the current (f = 0 for DC)

Table 20.3 gives the effects of electrical shocks as a function of current for a typical accidental shock. The effects are for a shock that passes through the trunk of the body, has a duration of 1 s, and is caused by 60-Hz power.

Table 20.3 Effects of Electrical Shock as a Function of Current

Current (mA) | Effect
1 | Threshold of sensation
5 | Maximum harmless current
10–20 | Onset of sustained muscular contraction; cannot let go for duration of shock; contraction of chest muscles may stop breathing during shock
50 | Onset of pain
100–300+ | Ventricular fibrillation possible; often fatal
300 | Onset of burns depending on concentration of current
6000 (6 A) | Onset of sustained ventricular contraction and respiratory paralysis; both cease when shock ends; heartbeat may return to normal; used to defibrillate the heart

Our bodies are relatively good conductors due to the water in our bodies. Given that larger currents will flow through sections with lower resistance (to be further discussed in the next chapter), electric currents preferentially flow through paths in the human body that have a minimum resistance in a direct path to earth. The earth is a natural electron sink. Wearing insulating shoes, a requirement in many professions, prohibits a pathway for electrons by providing a large resistance in that path. Whenever working with high-power tools (drills), or in risky situations, ensure that you do not provide a pathway for current flow (especially through the heart).

Very small currents pass harmlessly and unfelt through the body. This happens to you regularly without your knowledge. The threshold of sensation is only 1 mA and, although unpleasant, shocks are apparently harmless for currents less than 5 mA. A great number of safety rules take the 5-mA value for the maximum allowed shock. At 10 to 20 mA and above, the current can stimulate sustained muscular contractions much as regular nerve impulses do. People sometimes say they were knocked across the room by a shock, but what really happened was that certain muscles contracted, propelling them in a manner not of their own choosing. (See Figure 20.21(a).) More frightening, and potentially more dangerous, is the “can’t let go” effect illustrated in Figure 20.21(b). The muscles that close the fingers are stronger than those that open them, so the hand closes involuntarily on the wire shocking it. This can prolong the shock indefinitely. It can also be a danger to a person trying to rescue the victim, because the rescuer’s hand may close about the victim’s wrist. Usually the best way to help the victim is to give the fist a hard knock/blow/jar with an insulator or to throw an insulator at the fist. Modern electric fences, used in animal enclosures, are now pulsed on and off to allow people who touch them to get free, rendering them less lethal than in the past.

Greater currents may affect the heart. Its electrical patterns can be disrupted, so that it beats irregularly and ineffectively in a condition called “ventricular fibrillation.” This condition often lingers after the shock and is fatal due to a lack of blood circulation. The threshold for ventricular fibrillation is between 100 and 300 mA. At about 300 mA and above, the shock can cause burns, depending on the concentration of current—the more concentrated, the greater the likelihood of burns.

Very large currents cause the heart and diaphragm to contract for the duration of the shock. Both the heart and breathing stop. Interestingly, both often return to normal following the shock. The electrical patterns on the heart are completely erased in a manner that the heart can start afresh with normal beating, as opposed to the permanent disruption caused by smaller currents that can put the heart into ventricular fibrillation. The latter is something like scribbling on a blackboard, whereas the former completely erases it. TV dramatizations of electric shock used to bring a heart attack victim out of ventricular fibrillation also show large paddles. These are used to spread out current passed through the victim to reduce the likelihood of burns.

Current is the major factor determining shock severity (given that other conditions such as path, duration, and frequency are fixed, such as in the table and preceding discussion). A larger voltage is more hazardous, but since I = V/R, the severity of the shock depends on the combination of voltage and resistance. For example, a person with dry skin has a resistance of about 200 k Ω. If he comes into contact with 120-V AC, a current I = (120 V) / (200 k Ω) = 0.6 mA passes harmlessly through him. The same person soaking wet may have a resistance of 10.0 k Ω and the same 120 V will produce a current of 12 mA—above the “can’t let go” threshold and potentially dangerous.

Most of the body’s resistance is in its dry skin. When wet, salts go into ion form, lowering the resistance significantly. The interior of the body has a much lower resistance than dry skin because of all the ionic solutions and fluids it contains. If skin resistance is bypassed, such as by an intravenous infusion, a catheter, or exposed pacemaker leads, a person is rendered microshock sensitive. In this condition, currents about 1/1000 those listed in Table 20.3 produce similar effects. During open-heart surgery, currents as small as 20 μA can be used to still the heart. Stringent electrical safety requirements in hospitals, particularly in surgery and intensive care, are related to the doubly disadvantaged microshock-sensitive patient. The break in the skin has reduced his resistance, and so the same voltage causes a greater current, and a much smaller current has a greater effect.

Factors other than current that affect the severity of a shock are its path, duration, and AC frequency. Path has obvious consequences. For example, the heart is unaffected by an electric shock through the brain, such as may be used to treat manic depression. And it is a general truth that the longer the duration of a shock, the greater its effects. Figure 20.22 presents a graph that illustrates the effects of frequency on a shock. The curves show the minimum current for two different effects, as a function of frequency. The lower the current needed, the more sensitive the body is at that frequency. Ironically, the body is most sensitive to frequencies near the 50- or 60-Hz frequencies in common use. The body is slightly less sensitive for DC (f = 0), mildly confirming Edison’s claims that AC presents a greater hazard. At higher and higher frequencies, the body becomes progressively less sensitive to any effects that involve nerves. This is related to the maximum rates at which nerves can fire or be stimulated. At very high frequencies, electrical current travels only on the surface of a person. Thus a wart can be burned off with very high frequency current without causing the heart to stop. (Do not try this at home with 60-Hz AC!) Some of the spectacular demonstrations of electricity, in which high-voltage arcs are passed through the air and over people’s bodies, employ high frequencies and low currents. (See Figure 20.23.) Electrical safety devices and techniques are discussed in detail in Electrical Safety: Systems and Devices.
