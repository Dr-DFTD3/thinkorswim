## customVolumeData V 1.2
## dr_phlox
## written 9/18/22
## version 1 -> plot buying and selling volume in a single bar
## version 2 -> + signinificant volume data, averages, previous day volume etx...
## updated: added labels to show volume data
##
declare lower;
## inputs let user define what labels are displayed
input plotPrevVolume = yes;
input plot30DayAvg = yes;
input plotTodaysVolume = yes;
input plotVolumeRatio = yes;
input plot30BarAvg = yes;
input plotCurrentVolumeBar = yes;
input plotBuyingVol = yes;
input plotSellingVol = yes;

## average and comparison user defined values
input unusualVolume = 200; ## percent
input barLength = 50;


## get yesterdays volume
def prevDayVol = volume(period = "DAY")[2];


#### get the average volume over the last 30 days
def vol30days =0;
def volIter = fold idx = 1 to 31 with va = 0 do va+volume(period = "DAY")[idx];
def volAvg30 = volIter/30;
####


def todaysVolume = volume(period = "DAY");

## compute ratio of todays volume with the average of 30 days
## this is used as a comparison to determine if the volume is significant
def volRatio = Round((todaysVolume / volAvg30) * 100, 0);


#### get the average volume from the last "barLength" bars
def avgBars = fold id = 1 to 31 with vb =0 do vb+volume[id];
def avgVolBars = avgBars/barLength;
#####

def curVolume = volume;

## compute selling volume
def O = open;
def H = high;
def C = close;
def L = low;
def V = volume;
def Selling = V * (H - C) / (H - L);
def Buying = V * (C - L) / (H - L);


## labels
AddLabel(plotPrevVolume, "Prev Day Volume:" + prevDayVol + " ", Color.LIGHT_ORANGE);

AddLabel(plot30DayAvg, "Daily Avg: " + Round(volAvg30, 0), Color.LIGHT_GRAY);

## if the volume is greater than "unusual volume" paint it green, if it is less than unusual but > 100, paint it orange, if it is normal volume, paint it gray
AddLabel(plotTodaysVolume, "Today: " + todaysVolume, (if volRatio >= unusualVolume then Color.GREEN else if volRatio >= 100 then Color.ORANGE else Color.LIGHT_GRAY));

## if the volume is greater than "unusual volume" paint it green, if it is less than unusual but > 100, paint it orange, if it is normal volume, paint it gray
AddLabel(plotVolumeRatio, "V/V" + barLength + ": " + volRatio + "%", (if volRatio >= unusualVolume then Color.GREEN else if volRatio >= 100 then Color.ORANGE else Color.WHITE) );

AddLabel(plot30BarAvg, "Avg " + barLength + " Bars: " + Round(avgVolBars, 0), Color.LIGHT_GRAY);

## if current volume bar is greater than avg of last "barLength" bars, paint is green, else paint it orange
AddLabel(plotCurrentVolumeBar, "Cur Bar: " + curVolume, (if curVolume >= avgVolBars then Color.GREEN else Color.PINK));

AddLabel(plotBuyingVol,"Buying Vol: " + Round(Buying,0) + " ",Color.LIGHT_GREEN);
AddLabel(plotBuyingVol,"Selling Vol: " +Round(Selling,0) + " ",Color.LIGHT_RED);

## plotted data
##
## volume color coded by amount of volume on up-tick versus amount of volume on down-tick
## selling volume
plot SV = Selling;
SV.SetPaintingStrategy(PaintingStrategy.HISTOGRAM);
SV.SetDefaultColor(Color.RED);
SV.HideTitle();
SV.HideBubble();
SV.SetLineWeight(5);

## buying volume
## we can just use volume since total volume = selling + buying. paint total as green and overlay selling volume with red
plot BV =  volume;
BV.SetPaintingStrategy(PaintingStrategy.HISTOGRAM);
BV.SetDefaultColor(Color.DARK_GREEN);
BV.HideTitle();
BV.HideBubble();
BV.SetLineWeight(5);

## create a line to display average volume, averaged over user input "barLength"
plot Vol = volume;
plot VolAvg = Average(volume, barLength);
VolAvg.SetDefaultColor(Color.WHITE);
Vol.SetPaintingStrategy(PaintingStrategy.HISTOGRAM);