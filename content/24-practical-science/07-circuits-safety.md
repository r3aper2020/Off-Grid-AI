# Circuits: Series and Parallel, Batteries, Meters and Electrical Safety (OpenStax College Physics 2e, 2023)
Source: https://openstax.org/books/college-physics-2e/pages/21-1-resistors-in-series-and-parallel
Aliases: series vs parallel circuits, how to wire batteries in series or parallel, why does battery voltage drop under load, internal resistance of a battery, why do old batteries go flat, why does a flashlight dim, how to use a voltmeter, how to use an ammeter, how to measure voltage with a multimeter, what does a ground wire do, three prong plug ground, what is a gfci outlet, how a circuit breaker works, why do lights dim when an appliance turns on, resistors in parallel total resistance, double insulated tools, electrical safety at home, why grounding matters, generator grounding

## 21.1 Resistors in Series and Parallel
Most circuits have more than one component, called a resistor that limits the flow of charge in the circuit. A measure of this limit on charge flow is called resistance. The simplest combinations of resistors are the series and parallel connections illustrated in Figure 21.2. The total resistance of a combination of resistors depends on both their individual values and how they are connected.

## Resistors in Series
When are resistors in series? Resistors are in series whenever the flow of charge, called the current, must flow through devices sequentially. For example, if current flows through a person holding a screwdriver and into the Earth, then R_1 in Figure 21.2(a) could be the resistance of the screwdriver’s shaft, R_2 the resistance of its handle, R_3 the person’s body resistance, and R_4 the resistance of her shoes.

Figure 21.3 shows resistors in series connected to a voltage source. It seems reasonable that the total resistance is the sum of the individual resistances, considering that the current has to pass through each resistor in sequence. (This fact would be an advantage to a person wishing to avoid an electrical shock, who could reduce the current by wearing high-resistance rubber-soled shoes. It could be a disadvantage if one of the resistances were a faulty high-resistance cord to an appliance that would reduce the operating current.)

To verify that resistances in series do indeed add, let us consider the loss of electrical power, called a voltage drop, in each resistor in Figure 21.3.

According to Ohm’s law, the voltage drop, V, across a resistor when a current flows through it is calculated using the equation V = IR, where I equals the current in amps (A) and R is the resistance in ohms (Ω). Another way to think of this is that V is the voltage necessary to make a current I flow through a resistance R.

So the voltage drop across R_1 is V_1 = IR_1, that across R_2 is V_2 = IR_2, and that across R_3 is V_3 = IR_3. The sum of these voltages equals the voltage output of the source; that is,

V = V_1 + V_2 + V_3.

This equation is based on the conservation of energy and conservation of charge. Electrical potential energy can be described by the equation PE = qV, where q is the electric charge and V is the voltage. Thus the energy supplied by the source is qV, while that dissipated by the resistors is

qV_1 + qV_2 + qV_3.

**Connections: Conservation Laws**

The derivations of the expressions for series and parallel resistance are based on the laws of conservation of energy and conservation of charge, which state that total charge and total energy are constant in any process. These two laws are directly involved in all electrical phenomena and will be invoked repeatedly to explain both specific effects and the general behavior of electricity.

These energies must be equal, because there is no other source and no other destination for energy in the circuit. Thus, qV = qV_1 + qV_2 + qV_3. The charge q cancels, yielding V = V_1 + V_2 + V_3, as stated. (Note that the same amount of charge passes through the battery and each resistor in a given amount of time, since there is no capacitance to store charge, there is no place for charge to leak, and charge is conserved.)

Now substituting the values for the individual voltages gives

V = IR_1 + IR_2 + IR_3 = I (R_1 + R_2 + R_3).

Note that for the equivalent single series resistance R_s, we have

V = IR_s.

This implies that the total or equivalent series resistance R_s of three resistors is R_s = R_1 + R_2 + R_3.

This logic is valid in general for any number of resistors in series; thus, the total resistance R_s of a series connection is

R_s = R_1 + R_2 + R_3 +...,

as proposed. Since all of the current must pass through each resistor, it experiences the resistance of each, and resistances in series simply add up.

**Example: Calculating Resistance, Current, Voltage Drop, and Power Dissipation: Analysis of a Series Circuit**

Suppose the voltage output of the battery in Figure 21.3 is 12.0 V, and the resistances are R_1 = 1.00 Ω, R_2 = 6.00 Ω, and R_3 = 13.0 Ω. (a) What is the total resistance? (b) Find the current. (c) Calculate the voltage drop in each resistor, and show these add to equal the voltage output of the source. (d) Calculate the power dissipated by each resistor. (e) Find the power output of the source, and show that it equals the total power dissipated by the resistors.

The total resistance is simply the sum of the individual resistances, as given by this equation:

R_s = R_1 + R_2 + R_3; = 1.00 Ω + 6.00 Ω + 13.0 Ω; = 20.0 Ω.

The current is found using Ohm’s law, V = IR. Entering the value of the applied voltage and the total resistance yields the current for the circuit:

I = V/(R_s) = (12.0 V)/(20.0 Ω) = 0.600 A.

The voltage—or IR drop—in a resistor is given by Ohm’s law. Entering the current and the value of the first resistance yields

V_1 = IR_1 = (0.600 A) (1.0 Ω) = 0.600 V.

Similarly,

V_2 = IR_2 = (0.600 A) (6.0 Ω) = 3.60 V

and

V_3 = IR_3 = (0.600 A) (13.0 Ω) = 7.80 V.

The three IR drops add to 12.0 V, as predicted:

V_1 + V_2 + V_3 = (0.600 + 3.60 + 7.80) V = 12.0 V.

The easiest way to calculate power in watts (W) dissipated by a resistor in a DC circuit is to use Joule’s law, P = IV, where P is electric power. In this case, each resistor has the same full current flowing through it. By substituting Ohm’s law V = IR into Joule’s law, we get the power dissipated by the first resistor as

P_1 = I^2 R_1 = (0.600 A)^2 (1.00 Ω) = 0.360 W.

Similarly,

P_2 = I^2 R_2 = (0.600 A)^2 (6.00 Ω) = 2.16 W

and

P_3 = I^2 R_3 = (0.600 A)^2 (13.0 Ω) = 4.68 W.

Power can also be calculated using either P = IV or P = (V^2)/R, where V is the voltage drop across the resistor (not the full voltage of the source). The same values will be obtained.

The easiest way to calculate power output of the source is to use P = IV, where V is the source voltage. This gives

P = (0.600 A) (12.0 V) = 7.20 W.

Note, coincidentally, that the total power dissipated by the resistors is also 7.20 W, the same as the power put out by the source. That is,

P_1 + P_2 + P_3 = (0.360 + 2.16 + 4.68) W = 7.20 W.

Power is energy per unit time (watts), and so conservation of energy requires the power output of the source to be equal to the total power dissipated by the resistors.

**Major Features of Resistors in Series**

- Series resistances add: R_s = R_1 + R_2 + R_3 +....

- The same current flows through each resistor in series.

- Individual resistors in series do not get the total source voltage, but divide it.

## Resistors in Parallel
Figure 21.4 shows resistors in parallel, wired to a voltage source. Resistors are in parallel when each resistor is connected directly to the voltage source by connecting wires having negligible resistance. Each resistor thus has the full voltage of the source applied to it.

Each resistor draws the same current it would if it alone were connected to the voltage source (provided the voltage source is not overloaded). For example, an automobile’s headlights, radio, and so on, are wired in parallel, so that they utilize the full voltage of the source and can operate completely independently. The same is true in your house, or any building. (See Figure 21.4(b).)

To find an expression for the equivalent parallel resistance R_p, let us consider the currents that flow and how they are related to resistance. Since each resistor in the circuit has the full voltage, the currents flowing through the individual resistors are I_1 = V/(R_1), I_2 = V/(R_2), and I_3 = V/(R_3). Conservation of charge implies that the total current I produced by the source is the sum of these currents:

I = I_1 + I_2 + I_3.

Substituting the expressions for the individual currents gives

I = V/(R_1) + V/(R_2) + V/(R_3) = V (1/(R_1) + 1/(R_2) + 1/(R_3)).

Note that Ohm’s law for the equivalent single resistance gives

I = V/(R_p) = V (1/(R_p)).

The terms inside the parentheses in the last two equations must be equal. Generalizing to any number of resistors, the total resistance R_p of a parallel connection is related to the individual resistances by

1/(R_p) = 1/(R_1) + 1/(R_2) + 1/(R_(. 3)) +....

This relationship results in a total resistance R_p that is less than the smallest of the individual resistances. (This is seen in the next example.) When resistors are connected in parallel, more current flows from the source than would flow for any of them individually, and so the total resistance is lower.

**Example: Calculating Resistance, Current, Power Dissipation, and Power Output: Analysis of a Parallel Circuit**

Let the voltage output of the battery and resistances in the parallel connection in Figure 21.4 be the same as the previously considered series connection: V = 12.0 V, R_1 = 1.00 Ω, R_2 = 6.00 Ω, and R_3 = 13.0 Ω. (a) What is the total resistance? (b) Find the total current. (c) Calculate the currents in each resistor, and show these add to equal the total current output of the source. (d) Calculate the power dissipated by each resistor. (e) Find the power output of the source, and show that it equals the total power dissipated by the resistors.

The total resistance for a parallel combination of resistors is found using the equation below. Entering known values gives

1/(R_p) = 1/(R_1) + 1/(R_2) + 1/(R_3) = 1/(1.00 Ω) + 1/(6.00 Ω) + 1/(13.0 Ω).

Thus,

1/(R_p) = 1.00/Ω + (0.1667)/Ω + (0.07692)/Ω = (1.2436)/Ω.

(Note that in these calculations, each intermediate answer is shown with an extra digit.)

We must invert this to find the total resistance R_p. This yields

R_p = 1/(1.2436) Ω = 0.8041 Ω.

The total resistance with the correct number of significant digits is R_p = 0.804 Ω.

R_p is, as predicted, less than the smallest individual resistance.

The total current can be found from Ohm’s law, substituting R_p for the total resistance. This gives

I = V/(R_p) = (12.0 V)/(0.8041 Ω) = 14.92 A.

Current I for each device is much larger than for the same devices connected in series (see the previous example). A circuit with parallel connections has a smaller total resistance than the resistors connected in series.

The individual currents are easily calculated from Ohm’s law, since each resistor gets the full voltage. Thus,

I_1 = V/(R_1) = (12.0 V)/(1.00 Ω) = 12.0 A.

Similarly,

I_2 = V/(R_2) = (12.0 V)/(6.00 Ω) = 2.00 A

and

I_3 = V/(R_3) = (12.0 V)/(13.0 Ω) = 0.92 A.

The total current is the sum of the individual currents:

I_1 + I_2 + I_3 = 14.92 A.

This is consistent with conservation of charge.

The power dissipated by each resistor can be found using any of the equations relating power to current, voltage, and resistance, since all three are known. Let us use P = (V^2)/R, since each resistor gets full voltage. Thus,

P_1 = (V^2)/(R_1) = ((12.0 V)^2)/(1.00 Ω) = 144 W.

Similarly,

P_2 = (V^2)/(R_2) = ((12.0 V)^2)/(6.00 Ω) = 24.0 W

and

P_3 = (V^2)/(R_3) = ((12.0 V)^2)/(13.0 Ω) = 11.1 W.

The power dissipated by each resistor is considerably higher in parallel than when connected in series to the same voltage source.

The total power can also be calculated in several ways. Choosing P = IV, and entering the total current, yields

P = IV = (14.92 A) (12.0 V) = 179 W.

Total power dissipated by the resistors is also 179 W:

P_1 + P_2 + P_3 = 144 W + 24.0 W + 11.1 W = 179 W.

This is consistent with the law of conservation of energy.

Note that both the currents and powers in parallel connections are greater than for the same devices in series.

**Major Features of Resistors in Parallel**

- Parallel resistance is found from 1/(R_p) = 1/(R_1) + 1/(R_2) + 1/(R_3) +..., and it is smaller than any individual resistance in the combination.

- Each resistor in parallel has the same full voltage of the source applied to it. (Power distribution systems most often use parallel connections to supply the myriad devices served with the same voltage and to allow them to operate independently.)

- Parallel resistors do not each get the total current; they divide it.

## Combinations of Series and Parallel
More complex connections of resistors are sometimes just combinations of series and parallel. These are commonly encountered, especially when wire resistance is considered. In that case, wire resistance is in series with other resistances that are in parallel.

Combinations of series and parallel can be reduced to a single equivalent resistance using the technique illustrated in Figure 21.5. Various parts are identified as either series or parallel, reduced to their equivalents, and further reduced until a single resistance is left. The process is more time consuming than difficult.

The simplest combination of series and parallel resistance, shown in Figure 21.6, is also the most instructive, since it is found in many applications. For example, R_1 could be the resistance of wires from a car battery to its electrical devices, which are in parallel. R_2 and R_3 could be the starter motor and a passenger compartment light. We have previously assumed that wire resistance is negligible, but, when it is not, it has important effects, as the next example indicates.

**Example: Calculating Resistance, IRIR Drop, Current, and Power Dissipation: Combining Series and Parallel Circuits**

Figure 21.6 shows the resistors from the previous two examples wired in a different way—a combination of series and parallel. We can consider R_1 to be the resistance of wires leading to R_2 and R_3. (a) Find the total resistance. (b) What is the IR drop in R_1 ? (c) Find the current I_2 through R_2. (d) What power is dissipated by R_2 ?

To find the total resistance, we note that R_2 and R_3 are in parallel and their combination R_p is in series with R_1. Thus the total (equivalent) resistance of this combination is

R_tot = R_1 + R_p.

First, we find R_p using the equation for resistors in parallel and entering known values:

1/(R_p) = 1/(R_2) + 1/(R_3) = 1/(6.00 Ω) + 1/(13.0 Ω) = (0.2436)/Ω.

Inverting gives

R_p = 1/(0.2436) Ω = 4.11 Ω.

So the total resistance is

R_tot = R_1 + R_p = 1.00 Ω + 4.11 Ω = 5.11 Ω.

The total resistance of this combination is intermediate between the pure series and pure parallel values (20.0 Ω and 0.804 Ω, respectively) found for the same resistors in the two previous examples.

To find the IR drop in R_1, we note that the full current I flows through R_1. Thus its IR drop is

V_1 = IR_1.

We must find I before we can calculate V_1. The total current I is found using Ohm’s law for the circuit. That is,

I = V/(R_tot) = (12.0 V)/(5.11 Ω) = 2.35 A.

Entering this into the expression above, we get

V_1 = IR_1 = (2.35 A) (1.00 Ω) = 2.35 V.

The voltage applied to R_2 and R_3 is less than the total voltage by an amount V_1. When wire resistance is large, it can significantly affect the operation of the devices represented by R_2 and R_3.

To find the current through R_2, we must first find the voltage applied to it. We call this voltage V_p, because it is applied to a parallel combination of resistors. The voltage applied to both R_2 and R_3 is reduced by the amount V_1, and so it is

V_p = V − V_1 = 12.0 V − 2.35 V = 9.65 V.

Now the current I_2 through resistance R_2 is found using Ohm’s law:

I_2 = (V_p)/(R_2) = (9.65 V)/(6.00 Ω) = 1.61 A.

The current is less than the 2.00 A that flowed through R_2 when it was connected in parallel to the battery in the previous parallel circuit example.

The power dissipated by R_2 is given by

P_2 = (I_2)^2 R_2 = (1.61 A)^2 (6.00 Ω) = 15.5 W.

The power is less than the 24.0 W this resistor dissipated when connected in parallel to the 12.0-V source.

## Practical Implications
One implication of this last example is that resistance in wires reduces the current and power delivered to a resistor. If wire resistance is relatively large, as in a worn (or a very long) extension cord, then this loss can be significant. If a large current is drawn, the IR drop in the wires can also be significant.

For example, when you are rummaging in the refrigerator and the motor comes on, the refrigerator light dims momentarily. Similarly, you can see the passenger compartment light dim when you start the engine of your car (although this may be due to resistance inside the battery itself).

What is happening in these high-current situations is illustrated in Figure 21.7. The device represented by R_3 has a very low resistance, and so when it is switched on, a large current flows. This increased current causes a larger IR drop in the wires represented by R_1, reducing the voltage across the light bulb (which is R_2), which then dims noticeably.

**Problem-Solving Strategies for Series and Parallel Resistors**

- Draw a clear circuit diagram, labeling all resistors and voltage sources. This step includes a list of the knowns for the problem, since they are labeled in your circuit diagram.

- Identify exactly what needs to be determined in the problem (identify the unknowns). A written list is useful.

- Determine whether resistors are in series, parallel, or a combination of both series and parallel. Examine the circuit diagram to make this assessment. Resistors are in series if the same current must pass sequentially through them.

- Use the appropriate list of major features for series or parallel connections to solve for the unknowns. There is one list for series and another for parallel. If your problem has a combination of series and parallel, reduce it in steps by considering individual groups of series or parallel connections, as done in this module and the examples. Special note: When finding R p, the reciprocal must be taken with care.

- Check to see whether the answers are reasonable and consistent. Units and numerical results must be reasonable. Total series resistance should be greater, whereas total parallel resistance should be smaller, for example. Power should be greater for the same devices in parallel compared with series, and so on.

## 21.2 Electromotive Force: Terminal Voltage
When you forget to turn off your car lights, they slowly dim as the battery runs down. Why don’t they simply blink off when the battery’s energy is gone? Their gradual dimming implies that battery output voltage decreases as the battery is depleted.

Furthermore, if you connect an excessive number of 12-V lights in parallel to a car battery, they will be dim even when the battery is fresh and even if the wires to the lights have very low resistance. This implies that the battery’s output voltage is reduced by the overload.

The reason for the decrease in output voltage for depleted or overloaded batteries is that all voltage sources have two fundamental parts—a source of electrical energy and an internal resistance. Let us examine both.

## Electromotive Force
You can think of many different types of voltage sources. Batteries themselves come in many varieties. There are many types of mechanical/electrical generators, driven by many different energy sources, ranging from nuclear to wind. Solar cells create voltages directly from light, while thermoelectric devices create voltage from temperature differences.

A few voltage sources are shown in Figure 21.8. All such devices create a potential difference and can supply current if connected to a resistance. On the small scale, the potential difference creates an electric field that exerts force on charges, causing current. We thus use the name electromotive force, abbreviated emf.

Emf is not a force at all; it is a special type of potential difference. To be precise, the electromotive force (emf) is the potential difference of a source when no current is flowing. Units of emf are volts.

Electromotive force is directly related to the source of potential difference, such as the particular combination of chemicals in a battery. However, emf differs from the voltage output of the device when current flows. The voltage across the terminals of a battery, for example, is less than the emf when the battery supplies current, and it declines further as the battery is depleted or loaded down. However, if the device’s output voltage can be measured without drawing current, then output voltage will equal emf (even for a very depleted battery).

## Internal Resistance
As noted before, a 12-V truck battery is physically larger, contains more charge and energy, and can deliver a larger current than a 12-V motorcycle battery. Both are lead-acid batteries with identical emf, but, because of its size, the truck battery has a smaller internal resistance r. Internal resistance is the inherent resistance to the flow of current within the source itself.

Figure 21.9 is a schematic representation of the two fundamental parts of any voltage source. The emf (represented by a script E in the figure) and internal resistance r are in series. The smaller the internal resistance for a given emf, the more current and the more power the source can supply.

The internal resistance r can behave in complex ways. As noted, r increases as a battery is depleted. But internal resistance may also depend on the magnitude and direction of the current through a voltage source, its temperature, and even its history. The internal resistance of rechargeable nickel-cadmium cells, for example, depends on how many times and how deeply they have been depleted.

Why are the chemicals able to produce a unique potential difference? Quantum mechanical descriptions of molecules, which take into account the types of atoms and numbers of electrons in them, are able to predict the energy states they can have and the energies of reactions between them.

In the case of a lead-acid battery, an energy of 2 eV is given to each electron sent to the anode. Voltage is defined as the electrical potential energy divided by charge: V = (P_E)/q. An electron volt is the energy given to a single electron by a voltage of 1 V. So the voltage here is 2 V, since 2 eV is given to each electron. It is the energy produced in each molecular reaction that produces the voltage. A different reaction produces a different energy and, hence, a different voltage.

## Terminal Voltage
The voltage output of a device is measured across its terminals and, thus, is called its terminal voltage V. Terminal voltage is given by

V = emf − Ir,

where r is the internal resistance and I is the current flowing at the time of the measurement.

I is positive if current flows away from the positive terminal, as shown in Figure 21.9. You can see that the larger the current, the smaller the terminal voltage. And it is likewise true that the larger the internal resistance, the smaller the terminal voltage.

Suppose a load resistance R_load is connected to a voltage source, as in Figure 21.12. Since the resistances are in series, the total resistance in the circuit is R_load + r. Thus the current is given by Ohm’s law to be

I = emf/(R_load + r).

We see from this expression that the smaller the internal resistance r, the greater the current the voltage source supplies to its load R_load. As batteries are depleted, r increases. If r becomes a significant fraction of the load resistance, then the current is significantly reduced, as the following example illustrates.

**Example: Calculating Terminal Voltage, Power Dissipation, Current, and Resistance: Terminal Voltage and Load**

A certain battery has a 12.0-V emf and an internal resistance of 0.100 Ω. (a) Calculate its terminal voltage when connected to a 10.0- Ω load. (b) What is the terminal voltage when connected to a 0.500- Ω load? (c) What power does the 0.500- Ω load dissipate? (d) If the internal resistance grows to 0.500 Ω, find the current, terminal voltage, and power dissipated by a 0.500- Ω load.

The analysis above gave an expression for current when internal resistance is taken into account. Once the current is found, the terminal voltage can be calculated using the equation V = emf − Ir. Once current is found, the power dissipated by a resistor can also be found.

Entering the given values for the emf, load resistance, and internal resistance into the expression above yields

I = emf/(R_load + r) = (12.0 V)/(10.1 Ω) = 1.188 A.

Enter the known values into the equation V = emf − Ir to get the terminal voltage:

V = emf − Ir = 12.0 V − (1.188 A) (0.100 Ω); = 11.9 V.

The terminal voltage here is only slightly lower than the emf, implying that 10.0 Ω is a light load for this particular battery.

Similarly, with R_load = 0.500 Ω, the current is

I = emf/(R_load + r) = (12.0 V)/(0.600 Ω) = 20.0 A.

The terminal voltage is now

V = emf − Ir = 12.0 V − (20.0 A) (0.100 Ω); = 10.0 V.

This terminal voltage exhibits a more significant reduction compared with emf, implying 0.500 Ω is a heavy load for this battery.

The power dissipated by the 0.500 - Ω load can be found using the formula P = I^2 R. Entering the known values gives

P_load = I^2 R_load = ((20.0 A))^2 (0.500 Ω) = 2.00 × 10^2 W.

Note that this power can also be obtained using the expressions (V^2)/R or IV, where V is the terminal voltage (10.0 V in this case).

Here the internal resistance has increased, perhaps due to the depletion of the battery, to the point where it is as great as the load resistance. As before, we first find the current by entering the known values into the expression, yielding

I = emf/(R_load + r) = (12.0 V)/(1.00 Ω) = 12.0 A.

Now the terminal voltage is

V = emf − Ir = 12.0 V − (12.0 A) (0.500 Ω); = 6.00 V,

and the power dissipated by the load is

P_load = I^2 R_load = ((12.0 A))^2 (0.500 Ω) = 72.0 W.

We see that the increased internal resistance has significantly decreased terminal voltage, current, and power delivered to a load.

Battery testers, such as those in Figure 21.13, use small load resistors to intentionally draw current to determine whether the terminal voltage drops below an acceptable level. They really test the internal resistance of the battery. If internal resistance is high, the battery is weak, as evidenced by its low terminal voltage.

Some batteries can be recharged by passing a current through them in the direction opposite to the current they supply to a resistance. This is done routinely in cars and batteries for small electrical appliances and electronic devices, and is represented pictorially in Figure 21.14. The voltage output of the battery charger must be greater than the emf of the battery to reverse current through it. This will cause the terminal voltage of the battery to be greater than the emf, since V = emf − Ir, and I is now negative.

## Multiple Voltage Sources
There are two voltage sources when a battery charger is used. Voltage sources connected in series are relatively simple. When voltage sources are in series, their internal resistances add and their emfs add algebraically. (See Figure 21.15.) Series connections of voltage sources are common—for example, in flashlights, toys, and other appliances. Usually, the cells are in series in order to produce a larger total emf.

But if the cells oppose one another, such as when one is put into an appliance backward, the total emf is less, since it is the algebraic sum of the individual emfs.

A battery is a multiple connection of voltaic cells, as shown in Figure 21.16. The disadvantage of series connections of cells is that their internal resistances add. One of the authors once owned a 1957 MGA that had two 6-V batteries in series, rather than a single 12-V battery. This arrangement produced a large internal resistance that caused him many problems in starting the engine.

If the series connection of two voltage sources is made into a complete circuit with the emfs in opposition, then a current of magnitude I = ((emf_1 – emf_2))/(r_1 + r_2) flows. See Figure 21.17, for example, which shows a circuit exactly analogous to the battery charger discussed above. If two voltage sources in series with emfs in the same sense are connected to a load R_load, as in Figure 21.18, then I = ((emf_1 + emf_2))/(r_1 + r_2 + R_load) flows.

**Take-Home Experiment: Flashlight Batteries**

Find a flashlight that uses several batteries and find new and old batteries. Based on the discussions in this module, predict the brightness of the flashlight when different combinations of batteries are used. Do your predictions match what you observe? Now place new batteries in the flashlight and leave the flashlight switched on for several hours. Is the flashlight still quite bright? Do the same with the old batteries. Is the flashlight as bright when left on for the same length of time with old and new batteries? What does this say for the case when you are limited in the number of available new batteries?

Figure 21.19 shows two voltage sources with identical emfs in parallel and connected to a load resistance. In this simple case, the total emf is the same as the individual emfs. But the total internal resistance is reduced, since the internal resistances are in parallel. The parallel connection thus can produce a larger current.

Here, I = emf/((r_tot + R_load)) flows through the load, and r_tot is less than those of the individual batteries. For example, some diesel-powered cars use two 12-V batteries in parallel; they produce a total emf of 12 V but can deliver the larger current needed to start a diesel engine.

## Animals as Electrical Detectors
A number of animals both produce and detect electrical signals. Fish, sharks, platypuses, and echidnas (spiny anteaters) all detect electric fields generated by nerve activity in prey. Electric eels produce their own emf through biological cells (electric organs) called electroplaques, which are arranged in both series and parallel as a set of batteries.

Electroplaques are flat, disk-like cells; those of the electric eel have a voltage of 0.15 V across each one. These cells are usually located toward the head or tail of the animal, although in the case of the electric eel, they are found along the entire body. The electroplaques in the South American eel are arranged in 140 rows, with each row stretching horizontally along the body and containing 5,000 electroplaques. This can yield an emf of approximately 600 V, and a current of 1 A—deadly.

The mechanism for detection of external electric fields is similar to that for producing nerve signals in the cell through depolarization and repolarization—the movement of ions across the cell membrane. Within the fish, weak electric fields in the water produce a current in a gel-filled canal that runs from the skin to sensing cells, producing a nerve signal. The Australian platypus, one of the very few mammals that lay eggs, can detect fields of 30 mV/m, while sharks have been found to be able to sense a field in their snouts as small as 100 mV/m (Figure 21.20). Electric eels use their own electric fields produced by the electroplaques to stun their prey or enemies.

## Solar Cell Arrays
Another example dealing with multiple voltage sources is that of combinations of solar cells—wired in both series and parallel combinations to yield a desired voltage and current. Photovoltaic generation (PV), the conversion of sunlight directly into electricity, is based upon the photoelectric effect, in which photons hitting the surface of a solar cell create an electric current in the cell.

Most solar cells are made from pure silicon—either as single-crystal silicon, or as a thin film of silicon deposited upon a glass or metal backing. Most single cells have a voltage output of about 0.5 V, while the current output is a function of the amount of sunlight upon the cell (the incident solar radiation—the insolation). Under bright noon sunlight, a current of about 100 mA/cm^2 of cell surface area is produced by typical single-crystal cells.

Individual solar cells are connected electrically in modules to meet electrical-energy needs. They can be wired together in series or in parallel—connected like the batteries discussed earlier. A solar-cell array or module usually consists of between 36 and 72 cells, with a power output of 50 W to 140 W.

The output of the solar cells is direct current. For most uses in a home, AC is required, so a device called an inverter must be used to convert the DC to AC. Any extra output can then be passed on to the outside electrical grid for sale to the utility.

## 21.4 DC Voltmeters and Ammeters
Voltmeters measure voltage, whereas ammeters measure current. Some of the meters in automobile dashboards, digital cameras, cell phones, and tuner-amplifiers are voltmeters or ammeters. (See Figure 21.26.) The internal construction of the simplest of these meters and how they are connected to the system they monitor give further insight into applications of series and parallel connections.

Voltmeters are connected in parallel with whatever device’s voltage is to be measured. A parallel connection is used because objects in parallel experience the same potential difference. (See Figure 21.27, where the voltmeter is represented by the symbol V.)

Ammeters are connected in series with whatever device’s current is to be measured. A series connection is used because objects in series have the same current passing through them. (See Figure 21.28, where the ammeter is represented by the symbol A.)

## Analog Meters: Galvanometers
Analog meters have a needle that swivels to point at numbers on a scale, as opposed to digital meters, which have numerical readouts similar to a hand-held calculator. The heart of most analog meters is a device called a galvanometer, denoted by G. Current flow through a galvanometer, I_G, produces a proportional needle deflection. (This deflection is due to the force of a magnetic field upon a current-carrying wire.)

The two crucial characteristics of a given galvanometer are its resistance and current sensitivity. Current sensitivity is the current that gives a full-scale deflection of the galvanometer’s needle, the maximum current that the instrument can measure. For example, a galvanometer with a current sensitivity of 50 μA has a maximum deflection of its needle when 50 μA flows through it, reads half-scale when 25 μA flows through it, and so on.

If such a galvanometer has a 2 5- Ω resistance, then a voltage of only V = IR = (50 μA) (25 Ω) = 1.25 mV produces a full-scale reading. By connecting resistors to this galvanometer in different ways, you can use it as either a voltmeter or ammeter that can measure a broad range of voltages or currents.

**Galvanometer as Voltmeter**

Figure 21.29 shows how a galvanometer can be used as a voltmeter by connecting it in series with a large resistance, R. The value of the resistance R is determined by the maximum voltage to be measured. Suppose you want 10 V to produce a full-scale deflection of a voltmeter containing a 2 5-Ω galvanometer with a 50-μA sensitivity. Then 10 V applied to the meter must produce a current of 50 μA. The total resistance must be

R_tot = R + r = V/I = (10 V)/(50 μA) = 200 k Ω, or

R = R_tot − r = 200 kΩ − 25 Ω ≈ 200 k Ω.

(R is so large that the galvanometer resistance, r, is nearly negligible.) Note that 5 V applied to this voltmeter produces a half-scale deflection by producing a 2 5-μA current through the meter, and so the voltmeter’s reading is proportional to voltage as desired.

This voltmeter would not be useful for voltages less than about half a volt, because the meter deflection would be small and difficult to read accurately. For other voltage ranges, other resistances are placed in series with the galvanometer. Many meters have a choice of scales. That choice involves switching an appropriate resistance into series with the galvanometer.

**Galvanometer as Ammeter**

The same galvanometer can also be made into an ammeter by placing it in parallel with a small resistance R, often called the shunt resistance, as shown in Figure 21.30. Since the shunt resistance is small, most of the current passes through it, allowing an ammeter to measure currents much greater than those producing a full-scale deflection of the galvanometer.

Suppose, for example, an ammeter is needed that gives a full-scale deflection for 1.0 A, and contains the same 2 5- Ω galvanometer with its 50-μA sensitivity. Since R and r are in parallel, the voltage across them is the same.

These IR drops are IR = I_G r so that IR = (I_G)/I = R/r. Solving for R, and noting that I_G is 50 μA and I is 0.999950 A, we have

R = r (I_G)/I = (25 Ω) (50 μA)/(0.999950 A) = 1.25 × 10^(− 3) Ω.

## Taking Measurements Alters the Circuit
When you use a voltmeter or ammeter, you are connecting another resistor to an existing circuit and, thus, altering the circuit. Ideally, voltmeters and ammeters do not appreciably affect the circuit, but it is instructive to examine the circumstances under which they do or do not interfere.

First, consider the voltmeter, which is always placed in parallel with the device being measured. Very little current flows through the voltmeter if its resistance is a few orders of magnitude greater than the device, and so the circuit is not appreciably affected. (See Figure 21.31(a).) (A large resistance in parallel with a small one has a combined resistance essentially equal to the small one.) If, however, the voltmeter’s resistance is comparable to that of the device being measured, then the two in parallel have a smaller resistance, appreciably affecting the circuit. (See Figure 21.31(b).) The voltage across the device is not the same as when the voltmeter is out of the circuit.

An ammeter is placed in series in the branch of the circuit being measured, so that its resistance adds to that branch. Normally, the ammeter’s resistance is very small compared with the resistances of the devices in the circuit, and so the extra resistance is negligible. (See Figure 21.32(a).) However, if very small load resistances are involved, or if the ammeter is not as low in resistance as it should be, then the total series resistance is significantly greater, and the current in the branch being measured is reduced. (See Figure 21.32(b).)

A practical problem can occur if the ammeter is connected incorrectly. If it was put in parallel with the resistor to measure the current in it, you could possibly damage the meter; the low resistance of the ammeter would allow most of the current in the circuit to go through the galvanometer, and this current would be larger since the effective resistance is smaller.

One solution to the problem of voltmeters and ammeters interfering with the circuits being measured is to use galvanometers with greater sensitivity. This allows construction of voltmeters with greater resistance and ammeters with smaller resistance than when less sensitive galvanometers are used.

There are practical limits to galvanometer sensitivity, but it is possible to get analog meters that make measurements accurate to a few percent. Note that the inaccuracy comes from altering the circuit, not from a fault in the meter.

## 23.8 Electrical Safety: Systems and Devices
Electricity has two hazards. A thermal hazard occurs when there is electrical overheating. A shock hazard occurs when electric current passes through a person. Both hazards have already been discussed. Here we will concentrate on systems and devices that prevent electrical hazards.

Figure 23.29 shows the schematic for a simple AC circuit with no safety features. This is not how power is distributed in practice. Modern household and industrial wiring requires the three-wire system, shown schematically in Figure 23.30, which has several safety features. First is the familiar circuit breaker (or fuse) to prevent thermal overload. Second, there is a protective case around the appliance, such as a toaster or refrigerator. The case’s safety feature is that it prevents a person from touching exposed wires and coming into electrical contact with the circuit, helping prevent shocks.

There are three connections to earth or ground (hereafter referred to as “earth/ground”) shown in Figure 23.30. Recall that an earth/ground connection is a low-resistance path directly to the earth. The two earth/ground connections on the neutral wire force it to be at zero volts relative to the earth, giving the wire its name. This wire is therefore safe to touch even if its insulation, usually white, is missing. The neutral wire is the return path for the current to follow to complete the circuit. Furthermore, the two earth/ground connections supply an alternative path through the earth, a good conductor, to complete the circuit. The earth/ground connection closest to the power source could be at the generating plant, while the other is at the user’s location. The third earth/ground is to the case of the appliance, through the green earth/ground wire, forcing the case, too, to be at zero volts. The live or hot wire (hereafter referred to as “live/hot”) supplies voltage and current to operate the appliance. Figure 23.31 shows a more pictorial version of how the three-wire system is connected through a three-prong plug to an appliance.

A note on insulation color-coding: Insulating plastic is color-coded to identify live/hot, neutral and ground wires but these codes vary around the world. Live/hot wires may be brown, red, black, blue or grey. Neutral wire may be blue, black or white. Since the same color may be used for live/hot or neutral in different parts of the world, it is essential to determine the color code in your region. The only exception is the earth/ground wire which is often green but may be yellow or just bare wire. Striped coatings are sometimes used for the benefit of those who are colorblind.

The three-wire system replaced the older two-wire system, which lacks an earth/ground wire. Under ordinary circumstances, insulation on the live/hot and neutral wires prevents the case from being directly in the circuit, so that the earth/ground wire may seem like double protection. Grounding the case solves more than one problem, however. The simplest problem is worn insulation on the live/hot wire that allows it to contact the case, as shown in Figure 23.32. Lacking an earth/ground connection (some people cut the third prong off the plug because they only have outdated two hole receptacles), a severe shock is possible. This is particularly dangerous in the kitchen, where a good connection to earth/ground is available through water on the floor or a water faucet. With the earth/ground connection intact, the circuit breaker will trip, forcing repair of the appliance. Why are some appliances still sold with two-prong plugs? These have nonconducting cases, such as power tools with impact resistant plastic cases, and are called doubly insulated. Modern two-prong plugs can be inserted into the asymmetric standard outlet in only one way, to ensure proper connection of live/hot and neutral wires.

Electromagnetic induction causes a more subtle problem that is solved by grounding the case. The AC current in appliances can induce an emf on the case. If grounded, the case voltage is kept near zero, but if the case is not grounded, a shock can occur as pictured in Figure 23.33. Current driven by the induced case emf is called a leakage current, although current does not necessarily pass from the resistor to the case.

A ground fault interrupter (GFI) is a safety device found in updated kitchen and bathroom wiring that works based on electromagnetic induction. GFIs compare the currents in the live/hot and neutral wires. When live/hot and neutral currents are not equal, it is almost always because current in the neutral is less than in the live/hot wire. Then some of the current, again called a leakage current, is returning to the voltage source by a path other than through the neutral wire. It is assumed that this path presents a hazard, such as shown in Figure 23.34. GFIs are usually set to interrupt the circuit if the leakage current is greater than 5 mA, the accepted maximum harmless shock. Even if the leakage current goes safely to earth/ground through an intact earth/ground wire, the GFI will trip, forcing repair of the leakage.

Figure 23.35 shows how a GFI works. If the currents in the live/hot and neutral wires are equal, then they induce equal and opposite emfs in the coil. If not, then the circuit breaker will trip.

Another induction-based safety device is the isolation transformer, shown in Figure 23.36. Most isolation transformers have equal input and output voltages. Their function is to put a large resistance between the original voltage source and the device being operated. This prevents a complete circuit between them, even in the circumstance shown. There is a complete circuit through the appliance. But there is not a complete circuit for current to flow through the person in the figure, who is touching only one of the transformer’s output wires, and neither output wire is grounded. The appliance is isolated from the original voltage source by the high resistance of the material between the transformer coils, hence the name isolation transformer. For current to flow through the person, it must pass through the high-resistance material between the coils, through the wire, the person, and back through the earth—a path with such a large resistance that the current is negligible.

The basics of electrical safety presented here help prevent many electrical hazards. Electrical safety can be pursued to greater depths. There are, for example, problems related to different earth/ground connections for appliances in close proximity. Many other examples are found in hospitals. Microshock-sensitive patients, for instance, require special protection. For these people, currents as low as 0.1 mA may cause ventricular fibrillation. The interested reader can use the material presented here as a basis for further study.
