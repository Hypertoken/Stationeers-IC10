# Salacious Rewritten Mixer Script v0.1

#Shared Settings
const ratio = 0.5
const smoothPc = 90
const maxDiffRatio = 0.001
const @minOutput = 0
const @maxOutput = 3
const @minTankMols = 100
const @maxMixPressure = 47Mpa


#PreMix Settings
const @targetPressure = 17Mpa


# SuperFuel Settings
const @targetPressureSuper = 760Kpa
const maxSuperFuelTemp = 35C

# N2O Settings
const minNitrousTemp = -19c
const maxNitrousPressure = 800Kpa


# PreMix Devices
const @Pump1TankName = "OxygenTank"
alias Pump1Tank = IC.Device["StructureTankSmallInsulated"].Name[@Pump1TankName]

const @Pump2TankName = "NitrogenTank"
alias Pump2Tank = IC.Device["StructureTankSmallInsulated"].Name[@Pump2TankName]

const @Pump1Name = "OxygenPump"
alias Pump1 = IC.Device["StructureVolumePump"].Name[@Pump1Name]

const @Pump2Name = "NitrogenPump"
alias Pump2 = IC.Device["StructureVolumePump"].Name[@Pump2Name]

const @PAName = "PremixPA"
alias MixPA = IC.Device["StructurePipeAnalysizer"].Name[@PAName]


# SuperFuel Devices
const @Pump3TankName = "VolatilesTank"
alias Pump3Tank = IC.Device["StructureTankSmallInsulated"].Name[@Pump3TankName]

const @Pump3Name = "VolatilesPump"
alias Pump3 = IC.Device["StructureVolumePump"].Name[@Pump3Name]

const @Pump4Name = "N2OPump"
alias Pump4 = IC.Device["StructureVolumePump"].Name[@Pump4Name]

const @N2OPAName = "N2OPA"
alias N2OPA = IC.Device["StructurePipeAnalysizer"].Name[@N2OPAName]

const @SuperFuelPAName = "SuperFuelPA"
alias SuperFuelPA = IC.Device["StructurePipeAnalysizer"].Name[@SuperFuelPAName]

const @SuperFuelEvac = "SuperFuelEvac"
alias evacPumps = IC.Device["StructureTurboVolumePump"].Name[@SuperFuelEvac]

const @superfuelDVName = "SuperfuelDV"
alias SuperFuelDV = IC.Device["StructureDigitalValve"].Name[@superfuelDVName]


# N2O Devices
alias nitrolizer = IC.Device["StructureNitrolyzer"]

const @N20Filter = "N2OFilter"
alias N2OFilter = IC.Device["StructureFiltration"].Name[@N20Filter]

Main:
yield()

#Check Nitrous
if (N2OPA.Temperature < minNitrousTemp) || (N2OPA.Pressure > maxNitrousPressure) then
    nitrolizer.On = 0
    N2OFilter.On = 0
else
    nitrolizer.On = 1
    N2OFilter.On = 1
endif

# Check for Combustion and Evac Superfuel to Prevent Explosion
if (SuperFuelPA.Temperature > maxSuperFuelTemp) then 
    evacPumps.On = 1
    SuperFuelDV.On = 0
else
    evacPumps.On = 0
    SuperFuelDV.On = 1
endif

if ((Pump1Tank.TotalMoles < @minTankMols) ||
 (Pump2Tank.TotalMoles < @minTankMols)) ||
 ((MixPA.Pressure > @maxMixPressure)) then
    Pump1.On = 0
    Pump2.On = 0
else
    Pump1.On = 1
    Pump2.On = 1
endif

if ((Pump3Tank.TotalMoles < @minTankMols) ||
 (N2OPA.TotalMoles < @minTankMols)) ||
 ((SuperFuelPA.Pressure > @maxMixPressure)) ||
(SuperFuelPA.Temperature > maxSuperFuelTemp) then
    Pump3.On = 0
    Pump4.On = 0
else
    Pump3.On = 1
    Pump4.On = 1
endif

var pump1Val
var pump2Val
var curRatioDiff = ratio - MixPA.RatioOxygen
var fillOffset = @targetPressure - MixPA.Pressure

var smoothKpa = @targetPressure / 100
smoothKpa = smoothKpa * smoothPc
smoothKpa = @targetPressure - smoothKpa
pump1Val = @targetPressure - MixPA.Pressure
gosub PressCalc

Pump1.Setting = pump1Val
Pump2.Setting = pump2Val

# SuperFuel Mixer
smoothKpa = @targetPressureSuper / 100
smoothKpa = smoothKpa * smoothPc
smoothKpa = @targetPressureSuper - smoothKpa
curRatioDiff = ratio - SuperFuelPA.RatioVolatiles
fillOffset = @targetPressureSuper - SuperFuelPA.Pressure
gosub PressCalc

Pump3.Setting = pump1Val
Pump4.Setting = pump2Val

goto Main


PressCalc:
if (abs(curRatioDiff) <= maxDiffRatio) then
    # Pressure Calculation
    pump1Val = min(fillOffset, @maxOutput)
    pump1Val = max(pump1Val, 0)
    pump2Val = pump1Val
    if (pump1Val <= 0) then
        pump1Val = curRatioDiff / maxDiffRatio
        pump1Val = pump1Val * @maxOutput
        pump2Val = pump1Val * -1
    endif
else
    # Ratio Calculation
    pump1Val = curRatioDiff / maxDiffRatio
    pump1Val = pump1Val * @maxOutput
    pump2Val = pump1Val * -1
endif

# max pump output if in smoothing area
fillOffset = max(fillOffset, 0) 
fillOffset = min(fillOffset, smoothKpa) 
var tempMaxOutput = fillOffset / smoothKpa
tempMaxOutput = tempMaxOutput * @maxOutput

pump1Val = min(pump1Val, tempMaxOutput)
pump1Val = max(pump1Val, @minOutput)
pump2Val = min(pump2Val, tempMaxOutput)
pump2Val = max(pump2Val, @minOutput)

return