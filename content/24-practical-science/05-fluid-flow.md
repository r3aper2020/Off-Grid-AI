# Fluid Flow: Flow Rate, Bernoulli's Equation and Its Applications (OpenStax College Physics 2e, 2023)
Source: https://openstax.org/books/college-physics-2e/pages/12-1-flow-rate-and-its-relation-to-velocity
Aliases: how to calculate flow rate of a pipe, gallons per minute from pipe size, why does water speed up in a narrow hose, bernoulli principle explained, how a venturi works, why a roof lifts off in high wind, how does a carburetor or sprayer work, water flow from a tank, pipe diameter and flow, how fast does water leave a hole in a tank, toricelli theorem, garden hose nozzle pressure

## 12.1 Flow Rate and Its Relation to Velocity
Flow rate Q is defined to be the volume of fluid passing by some location through an area during a period of time, as seen in Figure 12.2. In symbols, this can be written as

Q = V/t,

where V is the volume and t is the elapsed time.

The SI unit for flow rate is m^3 /s, but a number of other units for Q are in common use. For example, the heart of a resting adult pumps blood at a rate of 5.00 liters per minute (L/min). Note that a liter (L) is 1/1000 of a cubic meter or 1000 cubic centimeters (10^(− 3) m^3 or 10^3 cm^3). In this text we shall use whatever metric units are most convenient for a given situation.

Example: Calculating Volume from Flow Rate: The Heart Pumps a Lot of Blood in a Lifetime

How many cubic meters of blood does the heart pump in a 75-year lifetime, assuming the average flow rate is 5.00 L/min?

Time and flow rate Q are given, and so the volume V can be calculated from the definition of flow rate.

Solving Q = V / t for volume gives

V = Qt.

Substituting known values yields

V = ((5.00 L)/(1 min)) (75 y) ((1 m^3)/(10^3 L)) (5.26 × 10^5 min/y); = 2.0 × 10^5 m^3.

This amount is about 200,000 tons of blood. For comparison, this value is equivalent to about 200 times the volume of water contained in a 6-lane 50-m lap pool.

Flow rate and velocity are related, but quite different, physical quantities. To make the distinction clear, think about the flow rate of a river. The greater the velocity of the water, the greater the flow rate of the river. But flow rate also depends on the size of the river. A rapid mountain stream carries far less water than the Amazon River in Brazil, for example. The precise relationship between flow rate Q and velocity v is

Q = A v,

where A is the cross-sectional area and v is the average velocity. This equation seems logical enough. The relationship tells us that flow rate is directly proportional to both the magnitude of the average velocity (hereafter referred to as the speed) and the size of a river, pipe, or other conduit. The larger the conduit, the greater its cross-sectional area. Figure 12.2 illustrates how this relationship is obtained. The shaded cylinder has a volume

V = Ad,

which flows past the point P in a time t. Dividing both sides of this relationship by t gives

V/t = Ad/t.

We note that Q = V / t and the average speed is v = d / t. Thus the equation becomes Q = A v.

Figure 12.3 shows an incompressible fluid flowing along a pipe of decreasing radius. Because the fluid is incompressible, the same amount of fluid must flow past any point in the tube in a given time to ensure continuity of flow. In this case, because the cross-sectional area of the pipe decreases, the velocity must necessarily increase. This logic can be extended to say that the flow rate must be the same at all points along the pipe. In particular, for points 1 and 2,

Q_1 = Q_2; A_1 v_1 = A_2 v_2 }.

This is called the equation of continuity and is valid for any incompressible fluid. The consequences of the equation of continuity can be observed when water flows from a hose into a narrow spray nozzle: it emerges with a large speed—that is the purpose of the nozzle. Conversely, when a river empties into one end of a reservoir, the water slows considerably, perhaps picking up speed again when it leaves the other end of the reservoir. In other words, speed increases when cross-sectional area decreases, and speed decreases when cross-sectional area increases.

Since liquids are essentially incompressible, the equation of continuity is valid for all liquids. However, gases are compressible, and so the equation must be applied with caution to gases if they are subjected to compression or expansion.

**Example: Calculating Fluid Speed: Speed Increases When a Tube Narrows**

A nozzle with a radius of 0.250 cm is attached to a garden hose with a radius of 0.900 cm. The flow rate through hose and nozzle is 0.500 L/s. Calculate the speed of the water (a) in the hose and (b) in the nozzle.

We can use the relationship between flow rate and speed to find both velocities. We will use the subscript 1 for the hose and 2 for the nozzle.

First, we solve Q = A v for v_1 and note that the cross-sectional area is A = πr^2, yielding

v_1 = Q/(A_1) = Q/(πr_1^2).

Substituting known values and making appropriate unit conversions yields

v_1 = ((0.500 L/s) (10^(− 3) m^3/L))/(π (9.00 × 10^(− 3) m)^2) = 1.96 m/s.

We could repeat this calculation to find the speed in the nozzle v_2, but we will use the equation of continuity to give a somewhat different insight. Using the equation which states

A_1 v_1 = A_2 v_2,

solving for v_2 and substituting πr^2 for the cross-sectional area yields

v_2 = (A_1)/(A_2) v_1 = (πr_1^2)/(πr_2^2) v_1 = (r_(1^2))/(r_(2^2)) v_1.

Substituting known values,

v_2 = ((0.900 cm)^2)/((0.250 cm)^2) 1.96 m/s = 25.5 m/s.

A speed of 1.96 m/s is about right for water emerging from a nozzleless hose. The nozzle produces a considerably faster stream merely by constricting the flow to a narrower tube.

The solution to the last part of the example shows that speed is inversely proportional to the square of the radius of the tube, making for large effects when radius varies. We can blow out a candle at quite a distance, for example, by pursing our lips, whereas blowing on a candle with our mouth wide open is quite ineffective.

In many situations, including in the cardiovascular system, branching of the flow occurs. The blood is pumped from the heart into arteries that subdivide into smaller arteries (arterioles) which branch into very fine vessels called capillaries. In this situation, continuity of flow is maintained but it is the sum of the flow rates in each of the branches in any portion along the tube that is maintained. The equation of continuity in a more general form becomes

n_1 A_1 v_1 = n_2 A_2 v_2,

where n_1 and n_2 are the number of branches in each of the sections along the tube.

**Example: Calculating Flow Speed and Vessel Diameter: Branching in the Cardiovascular System**

The aorta is the principal blood vessel through which blood leaves the heart in order to circulate around the body. (a) Calculate the average speed of the blood in the aorta if the flow rate is 5.0 L/min. The aorta has a radius of 10 mm. (b) Blood also flows through smaller blood vessels known as capillaries. When the rate of blood flow in the aorta is 5.0 L/min, the speed of blood in the capillaries is about 0.33 mm/s. Given that the average diameter of a capillary is 8.0 μ m, calculate the number of capillaries in the blood circulatory system.

We can use Q = A v to calculate the speed of flow in the aorta and then use the general form of the equation of continuity to calculate the number of capillaries as all of the other variables are known.

The flow rate is given by Q = A v or v = Q/(πr^2) for a cylindrical vessel.

Substituting the known values (converted to units of meters and seconds) gives

v = ((5.0 L/min) (10^(− 3) m^3/L) (1 min/60 s))/(π ((0.010 m))^2) = 0.27 m/s.

Using n_1 A_1 v_1 = n_2 A_2 v_1, assigning the subscript 1 to the aorta and 2 to the capillaries, and solving for n_2 (the number of capillaries) gives n_2 = (n_1 A_1 v_1)/(A_2 v_2). Converting all quantities to units of meters and seconds and substituting into the equation above gives

n_2 = ((1) (π) ((10 × 10^(− 3) m))^2 (0.27 m/s))/((π) ((4.0 × 10^(− 6) m))^2 (0.33 × 10^(− 3) m/s)) = 5.0 × 10^9 capillaries.

Note that the speed of flow in the capillaries is considerably reduced relative to the speed in the aorta due to the significant increase in the total cross-sectional area at the capillaries. This low speed is to allow sufficient time for effective exchange to occur although it is equally important for the flow not to become stationary in order to avoid the possibility of clotting. Does this large number of capillaries in the body seem reasonable? In active muscle, one finds about 200 capillaries per mm^3, or about 200 × 10^6 per 1 kg of muscle. For 20 kg of muscle, this amounts to about 4 × 10^9 capillaries.

## 12.2 Bernoulli’s Equation
When a fluid flows into a narrower channel, its speed increases. That means its kinetic energy also increases. Where does that change in kinetic energy come from? The increased kinetic energy comes from the net work done on the fluid to push it into the channel and the work done on the fluid by the gravitational force, if the fluid changes vertical position. Recall the work-energy theorem,

W_net = 1/2 mv^2 − 1/2 mv_0^2.

There is a pressure difference when the channel narrows. This pressure difference results in a net force on the fluid: recall that pressure times area equals force. The net work done increases the fluid’s kinetic energy. As a result, the pressure will drop in a rapidly-moving fluid, whether or not the fluid is confined to a tube.

There are a number of common examples of pressure dropping in rapidly-moving fluids. Shower curtains have a disagreeable habit of bulging into the shower stall when the shower is on. The high-velocity stream of water and air creates a region of lower pressure inside the shower, and standard atmospheric pressure on the other side. The pressure difference results in a net force inward pushing the curtain in. You may also have noticed that when passing a truck on the highway, your car tends to veer toward it. The reason is the same—the high velocity of the air between the car and the truck creates a region of lower pressure, and the vehicles are pushed together by greater pressure on the outside. (See Figure 12.4.) This effect was observed as far back as the mid-1800s, when it was found that trains passing in opposite directions tipped precariously toward one another.

**Making Connections: Take-Home Investigation with a Sheet of Paper**

Hold the short edge of a sheet of paper parallel to your mouth with one hand on each side of your mouth. The page should slant downward over your hands. Blow over the top of the page. Describe what happens and explain the reason for this behavior.

## Bernoulli’s Equation
The relationship between pressure and velocity in fluids is described quantitatively by Bernoulli’s equation, named after its discoverer, the Swiss scientist Daniel Bernoulli (1700–1782). Bernoulli’s equation states that for an incompressible, frictionless fluid, the following sum is constant:

P + 1/2 ρv^2 + ρ gh = constant,

where P is the absolute pressure, ρ is the fluid density, v is the velocity of the fluid, h is the height above some reference point, and g is the acceleration due to gravity. If we follow a small volume of fluid along its path, various quantities in the sum may change, but the total remains constant. Let the subscripts 1 and 2 refer to any two points along the path that the bit of fluid follows; Bernoulli’s equation becomes

P_1 + 1/2 ρv_1^2 + ρ gh_1 = P_2 + 1/2 ρv_2^2 + ρ gh_2.

Bernoulli’s equation is a form of the conservation of energy principle. Note that the second and third terms are the kinetic and potential energy with m replaced by ρ. In fact, each term in the equation has units of energy per unit volume. We can prove this for the second term by substituting ρ = m / V into it and gathering terms:

1/2 ρv^2 = (1/2 mv^2)/V = KE/V.

So 1/2 ρv^2 is the kinetic energy per unit volume. Making the same substitution into the third term in the equation, we find

ρ gh = mgh/V = (PE_g)/V,

so ρ gh is the gravitational potential energy per unit volume. Note that pressure P has units of energy per unit volume, too. Since P = F / A, its units are N/m^2. If we multiply these by m/m, we obtain N ⋅ m/m^3 = J/m^3, or energy per unit volume. Bernoulli’s equation is, in fact, just a convenient statement of conservation of energy for an incompressible fluid in the absence of friction.

**Making Connections: Conservation of Energy**

Conservation of energy applied to fluid flow produces Bernoulli’s equation. The net work done by the fluid’s pressure results in changes in the fluid’s KE and PE_g per unit volume. If other forms of energy are involved in fluid flow, Bernoulli’s equation can be modified to take these forms into account. Such forms of energy include thermal energy dissipated because of fluid viscosity.

The general form of Bernoulli’s equation has three terms in it, and it is broadly applicable. To understand it better, we will look at a number of specific situations that simplify and illustrate its use and meaning.

## Bernoulli’s Equation for Static Fluids
Let us first consider the very simple situation where the fluid is static—that is, v_1 = v_2 = 0. Bernoulli’s equation in that case is

P_1 + ρ gh_1 = P_2 + ρ gh_2.

We can further simplify the equation by taking h_2 = 0 (we can always choose some height to be zero, just as we often have done for other situations involving the gravitational force, and take all other heights to be relative to this). In that case, we get

P_2 = P_1 + ρ gh_1.

This equation tells us that, in static fluids, pressure increases with depth. As we go from point 1 to point 2 in the fluid, the depth increases by h_1, and consequently, P_2 is greater than P_1 by an amount ρ gh_1. In the very simplest case, P_1 is zero at the top of the fluid, and we get the familiar relationship P = ρ gh. (Recall that P = ρgh and Δ PE_g = mgh.) Bernoulli’s equation includes the fact that the pressure due to the weight of a fluid is ρ gh. Although we introduce Bernoulli’s equation for fluid flow, it includes much of what we studied for static fluids in the preceding chapter.

## Bernoulli’s Principle—Bernoulli’s Equation at Constant Depth
Another important situation is one in which the fluid moves but its depth is constant—that is, h_1 = h_2. Under that condition, Bernoulli’s equation becomes

P_1 + 1/2 ρv_1^2 = P_2 + 1/2 ρv_2^2.

Situations in which fluid flows at a constant depth are so important that this equation is often called Bernoulli’s principle. It is Bernoulli’s equation for fluids at constant depth. (Note again that this applies to a small volume of fluid as we follow it along its path.) As we have just discussed, pressure drops as speed increases in a moving fluid. We can see this from Bernoulli’s principle. For example, if v_2 is greater than v_1 in the equation, then P_2 must be less than P_1 for the equality to hold.

**Example: Calculating Pressure: Pressure Drops as a Fluid Speeds Up**

In Example 12.2, we found that the speed of water in a hose increased from 1.96 m/s to 25.5 m/s going from the hose to the nozzle. Calculate the pressure in the hose, given that the absolute pressure in the nozzle is 1.01 × 10^5 N/m^2 (atmospheric, as it must be) and assuming level, frictionless flow.

Level flow means constant depth, so Bernoulli’s principle applies. We use the subscript 1 for values in the hose and 2 for those in the nozzle. We are thus asked to find P_1.

Solving Bernoulli’s principle for P_1 yields

P_1 = P_2 + 1/2 ρv_2^2 − 1/2 ρv_1^2 = P_2 + 1/2 ρ (v_2^2 − v_1^2).

Substituting known values,

P_1 = 1.01 × 10^5 N/m^2; + 1/2 (10^3 kg/m^3) [(25.5 m/s)^2 − (1.96 m/s)^2]; = 4.24 × 10^5 N/m^2.

This absolute pressure in the hose is greater than in the nozzle, as expected since v is greater in the nozzle. The pressure P_2 in the nozzle must be atmospheric since it emerges into the atmosphere without other changes in conditions.

## Applications of Bernoulli’s Principle
There are a number of devices and situations in which fluid flows at a constant height and, thus, can be analyzed with Bernoulli’s principle.

**Entrainment**

People have long put the Bernoulli principle to work by using reduced pressure in high-velocity fluids to move things about. With a higher pressure on the outside, the high-velocity fluid forces other fluids into the stream. This process is called entrainment. Entrainment devices have been in use since ancient times, particularly as pumps to raise water small heights, as in draining swamps, fields, or other low-lying areas. Some other devices that use the concept of entrainment are shown in Figure 12.5.

**Wings and Sails**

The airplane wing is a beautiful example of Bernoulli’s principle in action. Figure 12.6(a) shows the characteristic shape of a wing. The wing is tilted upward at a small angle and the upper surface is longer, causing air to flow faster over it. The pressure on top of the wing is therefore reduced, creating a net upward force or lift. (Wings can also gain lift by pushing air downward, utilizing the conservation of momentum principle. The deflected air molecules result in an upward force on the wing — Newton’s third law.) Sails also have the characteristic shape of a wing. (See Figure 12.6(b).) The pressure on the front side of the sail, P_front, is lower than the pressure on the back of the sail, P_back. This results in a forward force and even allows you to sail into the wind.

**Making Connections: Take-Home Investigation with Two Strips of Paper**

For a good illustration of Bernoulli’s principle, make two strips of paper, each about 15 cm long and 4 cm wide. Hold the small end of one strip up to your lips and let it drape over your finger. Blow across the paper. What happens? Now hold two strips of paper up to your lips, separated by your fingers. Blow between the strips. What happens?

**Velocity measurement**

Figure 12.7 shows two devices that measure fluid velocity based on Bernoulli’s principle. The manometer in Figure 12.7(a) is connected to two tubes that are small enough not to appreciably disturb the flow. The tube facing the oncoming fluid creates a dead spot having zero velocity (v_1 = 0) in front of it, while fluid passing the other tube has velocity v_2. This means that Bernoulli’s principle as stated in P_1 + 1/2 ρv_1^2 = P_2 + 1/2 ρv_2^2 becomes

P_1 = P_2 + 1/2 ρv_2^2.

Thus pressure P_2 over the second opening is reduced by 1/2 ρv_2^2, and so the fluid in the manometer rises by h on the side connected to the second opening, where

h ∝ 1/2 ρv_2^2.

(Recall that the symbol ∝ means “proportional to.”) Solving for v_2, we see that

v_2 ∝ sqrt(h).

Figure 12.7(b) shows a version of this device that is in common use for measuring various fluid velocities; such devices are frequently used as air speed indicators in aircraft.

## Torricelli’s Theorem
Figure 12.8 shows water gushing from a large tube through a dam. What is its speed as it emerges? Interestingly, if resistance is negligible, the speed is just what it would be if the water fell a distance h from the surface of the reservoir; the water’s speed is independent of the size of the opening. Let us check this out. Bernoulli’s equation must be used since the depth is not constant. We consider water flowing from the surface (point 1) to the tube’s outlet (point 2). Bernoulli’s equation as stated in previously is

P_1 + 1/2 ρv_1^2 + ρ gh_1 = P_2 + 1/2 ρv_2^2 + ρ gh_2.

Both P_1 and P_2 equal atmospheric pressure (P_1 is atmospheric pressure because it is the pressure at the top of the reservoir. P_2 must be atmospheric pressure, since the emerging water is surrounded by the atmosphere and cannot have a pressure different from atmospheric pressure.) and subtract out of the equation, leaving

1/2 ρv_1^2 + ρ gh_1 = 1/2 ρv_2^2 + ρ gh_2.

Solving this equation for v_2^2, noting that the density ρ cancels (because the fluid is incompressible), yields

v_2^2 = v_1^2 + 2 g (h_1 − h_2).

We let h = h_1 − h_2; the equation then becomes

v_2^2 = v_1^2 + 2 gh

where h is the height dropped by the water. This is simply a kinematic equation for any object falling a distance h with negligible resistance. In fluids, this last equation is called Torricelli’s theorem. Note that the result is independent of the velocity’s direction, just as we found when applying conservation of energy to falling objects.

All preceding applications of Bernoulli’s equation involved simplifying conditions, such as constant height or constant pressure. The next example is a more general application of Bernoulli’s equation in which pressure, velocity, and height all change. (See Figure 12.9.)

**Example: Calculating Pressure: A Fire Hose Nozzle**

Fire hoses used in major structure fires have inside diameters of 6.40 cm. Suppose such a hose carries a flow of 40.0 L/s starting at a gauge pressure of 1.62 × 10^6 N/m^2. The hose goes 10.0 m up a ladder to a nozzle having an inside diameter of 3.00 cm. Assuming negligible resistance, what is the pressure in the nozzle?

Here we must use Bernoulli’s equation to solve for the pressure, since depth is not constant.

Bernoulli’s equation states

P_1 + 1/2 ρv_1^2 + ρ gh_1 = P_2 + 1/2 ρv_2^2 + ρ gh_2,

where the subscripts 1 and 2 refer to the initial conditions at ground level and the final conditions inside the nozzle, respectively. We must first find the speeds v_1 and v_2. Since Q = A_1 v_1, we get

v_1 = Q/(A_1) = (40.0 × 10^(− 3) m^3/s)/(π (3.20 × 10^(− 2) m)^2) = 12.434 m/s.

Similarly, we find

v_2 = 56.588 m/s.

(This rather large speed is helpful in reaching the fire.) Now, taking h_1 to be zero, we solve Bernoulli’s equation for P_2:

P_2 = P_1 + 1/2 ρ (v_1^2 − v_2^2) − ρ gh_2.

Substituting known values yields

P_2 =; 1.62 × 10^6 N/m^2 + 1/2 (1000 kg/m^3) [ (12.434 m/s)^2 − (56.588 m/s)^2 ] − (1000 kg/m^3) (9.80 m/s^2) (10.0 m); ≈ 1800 N/m^2.

This value is a gauge pressure, since the initial pressure was given as a gauge pressure. Thus the nozzle pressure is very close to atmospheric pressure, as it must because the water exits into the atmosphere without changes in its conditions.

## Power in Fluid Flow
Power is the rate at which work is done or energy in any form is used or supplied. To see the relationship of power to fluid flow, consider Bernoulli’s equation:

P + 1/2 ρv^2 + ρ gh = constant.

All three terms have units of energy per unit volume, as discussed in the previous section. Now, considering units, if we multiply energy per unit volume by flow rate (volume per unit time), we get units of power. That is, (E / V) (V / t) = E / t. This means that if we multiply Bernoulli’s equation by flow rate Q, we get power. In equation form, this is

(P + 1/2 ρv^2 + ρ gh) Q = power.

Each term has a clear physical meaning. For example, PQ is the power supplied to a fluid, perhaps by a pump, to give it its pressure P. Similarly, 1/2 ρv^2 Q is the power supplied to a fluid to give it its kinetic energy. And ρ ghQ is the power going to gravitational potential energy.

**Making Connections: Power**

Power is defined as the rate of energy transferred, or E / t. Fluid flow involves several types of power. Each type of power is identified with a specific type of energy being expended or changed in form.

**Example: Calculating Power in a Moving Fluid**

Suppose the fire hose in the previous example is fed by a pump that receives water through a hose with a 6.40-cm diameter coming from a hydrant with a pressure of 0.700 × 10^6 N/m^2. What power does the pump supply to the water?

Here we must consider energy forms as well as how they relate to fluid flow. Since the input and output hoses have the same diameters and are at the same height, the pump does not change the speed of the water nor its height, and so the water’s kinetic energy and gravitational potential energy are unchanged. That means the pump only supplies power to increase water pressure by 0.92 × 10^6 N/m^2 (from 0.700 × 10^6 N/m^2 to 1.62 × 10^6 N/m^2).

As discussed above, the power associated with pressure is

power = PQ; = (0.920 × 10^6 N/m^2) (40.0 × 10^(− 3) m^3 /s).; = 3.68 × 10^4 W = 36.8 kW.

Such a substantial amount of power requires a large pump, such as is found on some fire trucks. (This kilowatt value converts to about 50 hp.) The pump in this example increases only the water’s pressure. If a pump—such as the heart—directly increases velocity and height as well as pressure, we would have to calculate all three terms to find the power it supplies.
