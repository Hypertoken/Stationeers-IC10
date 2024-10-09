alias larre d0
alias seedBin d1
alias fertBin d2
alias outbin d3

alias potID = IC.Device["StructureHydroponicsTrayData"]

const @outPos = 23
const @seedPos = 22 
const @fertPos = 1

ARRAY hashArray[20]

hashArray[0] = "D1"
hashArray[1] = "D2"
hashArray[2] = "D3"
hashArray[3] = "D4"
hashArray[4] = "D5"
hashArray[5] = "D6"
hashArray[6] = "D7"
hashArray[7] = "D8"
hashArray[8] = "D9"
hashArray[9] = "D10"
hashArray[10] = "D11"
hashArray[11] = "D12"
hashArray[12] = "D13"
hashArray[13] = "D14"
hashArray[14] = "D15"
hashArray[15] = "D16"
hashArray[16] = "D17"
hashArray[17] = "D18"
hashArray[18] = "D19"
hashArray[19] = "D20"

IterateStackDevices: 
yield()
var counter = 0

CheckNextDevice:
var position = counter + 2
var hash = hashArray[counter]
db.Setting = position
if counter > 19 then
 goto IterateStackDevices
endif
counter++

checkdead:
if (potID.name[hash].slot[0].Occupied == 1) && (potID.name[hash].slot[0].Health < 1) then
SendLarreToTask(position)
endif

checkplant:
if (potID.name[hash].slot[0].Occupied == 1) || (seedBin.slot[0].Occupied == 0) then
 goto checkfert
endif
if larre.slot[0].Occupied == 0 then
 SendLarreToTask(@seedPos)
endif

checkfert:
if (potID.name[hash].slot[1].Occupied == 1) || (fertBin.slot[0].Occupied == 0) then
 if larre.slot[0].Occupied == 1 then
  SendLarreToTask(position)
 endif
 goto ContinueHarvest
endif

addfert:
SendLarreToTask(@fertPos)
SendLarreToTask(position)
while larre.slot[0].Occupied == 1
 SendLarreToTask(position)
endwhile

ContinueHarvest:
if (potID.name[hash].slot[0].Seeding == 1) then
 SendLarreToTask(position)
 while potID.name[hash].slot[0].Mature == 1
  SendLarreToTask(position)
 endwhile
 goto Dropoff
else
 goto CheckNextDevice
endif

Dropoff:
SendLarreToTask(@outPos)
Outbin.Open = 0
if (potID.name[hash].slot[0].Occupied == 1) then 
 SendLarreToTask(@outPos)
 Outbin.Open = 0
 goto CheckNextDevice
endif
goto checkplant

function SendLarreToTask(POS)
larre.Setting = POS
while larre.Idle == 0 
 yield()
endwhile
larre.Activate = 1
wait(2)
endfunction