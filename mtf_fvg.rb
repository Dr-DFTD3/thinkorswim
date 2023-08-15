## mtf_fvg 
## script to plot multi-time frame (MTF) FVG on a the current chart.
## User can select to show only 1, 2 or all 3 time frames
## Caveat due to ToS, only timeframes greater than the chart time will be displayed
## e.g. if you are on the 15 minute chart, you cannot display a 5 min FVG


input fvgSize = 0.05; #hint fvgSize: Percent of movement in price used to define a valid FVG. Smaller values displays all FVG, larger values only displays largest FVG
input timeFrame1 = AggregationPeriod.THIRTY_MIN; #hint timeFrame1: Time frame for plotting FVG
input timeFrame2 = AggregationPeriod.FIVE_MIN; #hint timeFrame2: 2nd unique time frame for plotting MTF FVG
input timeFrame3 = AggregationPeriod.THREE_MIN; #hint timeFrame3: 3rd unique time frame for plotting MTF FVG
input showTimeFrame2 = yes; #hint showTimeFrame2: Show the FVG from TF 2 on the chart
input showTimeFrame3 = yes; #hint showTimeFrame3: Show the FVG from TF 3 on the chart
input extendRegions = no; #hint extendRegions: If yes, FVG are displayed as a rectangle until they are completely balanced. If NO, FVG are successively reduced as price balances them
input showLines = yes; #hint showLines: If yes, show lines marking the top and bottom of an FVG
input showClouds = yes; #hint showClouds: If yes, highlight the region between the top and bottom of an FVG

## global stuff
DefineGlobalColor("TimeFrame 1", Color.ORANGE);
DefineGlobalColor("TimeFrame 2", Color.CYAN);
DefineGlobalColor("TimeFrame 3", Color.PINK);
def dNaN = double.NaN;

## timeframe1
## define some variables to make code more readable
## tfXCYHigh/Low
## tf = timeframe
## X = which timeframe
## C = candle
## Y = candle number, 1 or 3 in the FVG pattern
def tf1Low = low(period = timeFrame1);
def tf1High = high(period = timeFrame1);
def tf1C1Low = tf1Low[2];
def tf1C3Low = tf1Low;
def tf1C1High = tf1High[2];
def tf1C3High = tf1High;

## check if the bearish 3-candle pattern exists 
def tf1BearFvg = if tf1C1Low - tf1C3High > 0 then 1 else 0;
## compare the size to the user defined price width to decide if the FVG is worth plotting
def tf1BearFvgPct = if AbsValue((tf1C3High -tf1C1Low)/tf1C1Low) > fvgSize/100 then 1 else 0;
## check if the bullish 3-candle pattern exists 
def tf1BullFvg = if tf1C3Low - tf1C1High > 0 then 1 else 0;
## compare the size to the user defined price width to decide if the FVG is worth plotting
def tf1BullFvgPct = if AbsValue((tf1C3Low - tf1C1High)/tf1C1High) > fvgSize/100 then 1 else 0;

## if the bearish 3-candle pattern exists and the FVG size is suitable, store the low of the 1st candle in the series
def tf1BearFvgHTemp = if tf1BearFvg and tf1BearFvgPct then tf1C1Low else 0;
## if the bearish 3-candle pattern exists and the FVG size is suitable, store the high of the 3rd candle in the series	
def tf1BearFvgLTemp = if tf1BearFvgHTemp then tf1C3High else dNaN;

## if the bullish 3-candle pattern exists and the FVG size is suitable, store the low of the 3rd candle in the series
def tf1BullFvgHTemp = if tf1BullFvg and tf1BullFvgPct then tf1C3Low else 0;
## if the bullish 3-candle pattern exists and the FVG size is suitable, store the high of the 1st candle in the series
def tf1BullFvgLTemp = if tf1BullFvgHTemp then tf1C1High else dNaN;

## check if the current FVG is still active or if a new one is to be drawn
def tf1BearFvgHActive = if tf1BearFvgHTemp 
							then tf1BearFvgHTemp 
						else if tf1C3High > tf1BearFvgHActive[1] 
							then dNaN 
						else tf1BearFvgHActive[1];
def tf1BearFvgLActive = if tf1BearFvgHTemp 
							then tf1BearFvgLTemp 
						else if tf1C3High > tf1BearFvgHActive[1] 
							then dNaN 
						else if !extendRegions and tf1C3High > tf1BearFvgLActive[1] 
						 	then tf1C3High else tf1BearFvgLActive[1];

def tf1BullFvgLActive = if tf1BullFvgHTemp 
							then tf1BullFvgLTemp 
						else if tf1C3Low < tf1BullFvgLActive[1] 
							then dNaN 
						else tf1BullFvgLActive[1];
def tf1BullFvgHActive = if tf1BullFvgHTemp 
							then tf1BullFvgHTemp 
						else if tf1C3Low < tf1BullFvgLActive[1] 
							then dNaN 
						else if !extendRegions and tf1C3Low < tf1BullFvgHActive[1] 
							then tf1C3Low 
						else tf1BullFvgHActive[1];

## store the top and bottom of each FVG for plotting later
def tf1BearFvgBottom = if tf1BearFvgHActive then tf1BearFvgHActive else dNaN;
def tf1BearFvgTop = if tf1BearFvgLActive then tf1BearFvgLActive else dNaN;

def tf1BullFvgTop = if tf1BullFvgHActive then tf1BullFvgHActive else dNaN;
def tf1BullFvgBottom = if tf1BullFvgLActive then tf1BullFvgLActive else dNaN;



##timeframe 2
## no comments here, see timeframe 1 for details
def tf2Low = low(period = timeFrame2);
def tf2High = high(period = timeFrame2);
def tf2C1Low = tf2Low[2];
def tf2C3Low = tf2Low;
def tf2C1High = tf2High[2];
def tf2C3High = tf2High;


def tf2BearFvg = if tf2C1Low - tf2C3High > 0 then 1 else 0;
def tf2BearFvgPct = if AbsValue((tf2C3High -tf2C1Low)/tf2C1Low) > fvgSize/100 then 1 else 0;

def tf2BullFvg = if tf2C3Low - tf2C1High > 0 then 1 else 0;
def tf2BullFvgPct = if AbsValue((tf2C3Low - tf2C1High)/tf2C1High) > fvgSize/100 then 1 else 0;

def tf2BearFvgHTemp = if tf2BearFvg and tf2BearFvgPct then tf2C1Low else 0;
def tf2BearFvgLTemp = if tf2BearFvgHTemp then tf2C3High else dNaN;

def tf2BullFvgHTemp = if tf2BullFvg and tf2BullFvgPct then tf2C3Low else 0;
def tf2BullFvgLTemp = if tf2BullFvgHTemp then tf2C1High else dNaN;

def tf2BearFvgHActive = if tf2BearFvgHTemp 
							then tf2BearFvgHTemp 
						else if tf2C3High > tf2BearFvgHActive[1] 
							then dNaN 
						else tf2BearFvgHActive[1];
def tf2BearFvgLActive = if tf2BearFvgHTemp 
							then tf2BearFvgLTemp 
						else if tf2C3High > tf2BearFvgHActive[1] 
							then dNaN 
						else if !extendRegions and tf2C3High > tf2BearFvgLActive[1] 
							then tf2C3High 
						else tf2BearFvgLActive[1];

def tf2BullFvgLActive = if tf2BullFvgHTemp 
							then tf2BullFvgLTemp 
						else if tf2C3Low < tf2BullFvgLActive[1] 
							then dNaN 
						else tf2BullFvgLActive[1];
def tf2BullFvgHActive = if tf2BullFvgHTemp 
							then tf2BullFvgHTemp 
						else if tf2C3Low < tf2BullFvgLActive[1] 
							then dNaN 
						else if !extendRegions and tf2C3Low < tf2BullFvgHActive[1] 
							then tf2C3Low 
						else tf2BullFvgHActive[1];

def tf2BearFvgBottom = if tf2BearFvgHActive then tf2BearFvgHActive else dNaN;
def tf2BearFvgTop = if tf2BearFvgLActive then tf2BearFvgLActive else dNaN;

def tf2BullFvgTop = if tf2BullFvgHActive then tf2BullFvgHActive else dNaN;
def tf2BullFvgBottom = if tf2BullFvgLActive then tf2BullFvgLActive else dNaN;

##timeframe 3
def tf3Low = low(period = timeFrame3);
def tf3High = high(period = timeFrame3);
def tf3C1Low = tf3Low[2];
def tf3C3Low = tf3Low;
def tf3C1High = tf3High[2];
def tf3C3High = tf3High;

def tf3BearFvg = if tf3C1Low - tf3C3High > 0 then 1 else 0;
def tf3BearFvgPct = if AbsValue((tf3C3High -tf3C1Low)/tf3C1Low) > fvgSize/100 then 1 else 0;

def tf3BullFvg = if tf3C3Low - tf3C1High > 0 then 1 else 0;
def tf3BullFvgPct = if AbsValue((tf3C3Low - tf3C1High)/tf3C1High) > fvgSize/100 then 1 else 0;

def tf3BearFvgHTemp = if tf3BearFvg and tf3BearFvgPct then tf3C1Low else 0;
def tf3BearFvgLTemp = if tf3BearFvgHTemp then tf3C3High else dNaN;

def tf3BullFvgHTemp = if tf3BullFvg and tf3BullFvgPct then tf3C3Low else 0;
def tf3BullFvgLTemp = if tf3BullFvgHTemp then tf3C1High else dNaN;

def tf3BearFvgHActive = if tf3BearFvgHTemp 
							then tf3BearFvgHTemp 
						else if tf3C3High > tf3BearFvgHActive[1] 
							then dNaN 
						else tf3BearFvgHActive[1];
def tf3BearFvgLActive = if tf3BearFvgHTemp 
							then tf3BearFvgLTemp 
						else if tf3C3High > tf3BearFvgHActive[1] 
							then dNaN 
						else if !extendRegions and tf3C3High > tf3BearFvgLActive[1] 
							then tf3C3High 
						else tf3BearFvgLActive[1];

def tf3BullFvgLActive = if tf3BullFvgHTemp 
							then tf3BullFvgLTemp 
						else if tf3C3Low < tf3BullFvgLActive[1] 
							then dNaN 
						else tf3BullFvgLActive[1];
def tf3BullFvgHActive = if tf3BullFvgHTemp 
							then tf3BullFvgHTemp 
						else if tf3C3Low < tf3BullFvgLActive[1] 
							then dNaN 
						else if !extendRegions and tf3C3Low < tf3BullFvgHActive[1] 
							then tf3C3Low 
						else tf3BullFvgHActive[1];

def tf3BearFvgBottom = if tf3BearFvgHActive then tf3BearFvgHActive else dNaN;
def tf3BearFvgTop = if tf3BearFvgLActive then tf3BearFvgLActive else dNaN;

def tf3BullFvgTop = if tf3BullFvgHActive then tf3BullFvgHActive else dNaN;
def tf3BullFvgBottom = if tf3BullFvgLActive then tf3BullFvgLActive else dNaN;

## display related routines 
AddLabel(yes,timeFrame1/60000 + " min FVG  ",GlobalColor("TimeFrame 1"));
AddLabel(showTimeFrame2,timeFrame2/60000 + " min FVG  ",GlobalColor("TimeFrame 2"));
AddLabel(showTimeFrame3,timeFrame3/60000 + " min FVG  ",GlobalColor("TimeFrame 3"));

AddCloud(if showClouds then tf1BearFvgBottom else dNaN, if showClouds then tf1BearFvgTop else dNaN, GlobalColor("TimeFrame 1"));
AddCloud(if showClouds then tf1BullFvgTop else dNaN, if showClouds then tf1BullFvgBottom else dNaN, GlobalColor("TimeFrame 1"));

AddCloud(if showClouds and showTimeFrame2 then tf2BearFvgBottom else dNaN, if showClouds and  showTimeFrame2 then tf2BearFvgTop else dNaN, GlobalColor("TimeFrame 2"));
AddCloud(if showClouds and showTimeFrame2 then tf2BullFvgTop else dNaN, if showClouds and showTimeFrame2 then tf2BullFvgBottom else dNaN, GlobalColor("TimeFrame 2"));

AddCloud(if showClouds and showTimeFrame3 then tf3BearFvgBottom else dNaN, if showClouds and showTimeFrame3 then tf3BearFvgTop else dNaN, GlobalColor("TimeFrame 3"));
AddCloud(if showClouds and showTimeFrame3 then tf3BullFvgTop else dNaN, if showClouds and showTimeFrame3 then tf3BullFvgBottom else dNaN, GlobalColor("TimeFrame 3"));


plot tf1BearFvgPlotTop = if showLines then tf1BearFvgTop else dNaN;
plot tf1BearFvgPlotBottom = if showLines then tf1BearFvgBottom else dNaN;
plot tf1BullFvgPlotTop = if showLines then tf1BullFvgTop else dNaN;
plot tf1BullFvgPlotBottom = if showLines then tf1BullFvgBottom else dNaN;

tf1BearFvgPlotTop.SetLineWeight(2);
tf1BearFvgPlotBottom.SetLineWeight(2);
tf1BearFvgPlotTop.SetDefaultColor(GlobalColor("TimeFrame 1"));
tf1BearFvgPlotBottom.SetDefaultColor(GlobalColor("TimeFrame 1"));
tf1BearFvgPlotTop.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
tf1BearFvgPlotBottom.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);

tf1BullFvgPlotTop.SetLineWeight(2);
tf1BullFvgPlotBottom.SetLineWeight(2);
tf1BullFvgPlotTop.SetDefaultColor(GlobalColor("TimeFrame 1"));
tf1BullFvgPlotBottom.SetDefaultColor(GlobalColor("TimeFrame 1"));
tf1BullFvgPlotTop.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
tf1BullFvgPlotBottom.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);

plot tf2BearFvgPlotTop = if showLines and showTimeFrame2 then tf2BearFvgTop else dNaN;
plot tf2BearFvgPlotBottom = if showLines and showTimeFrame2  then tf2BearFvgBottom else dNaN;
plot tf2BullFvgPlotTop = if showLines and showTimeFrame2  then tf2BullFvgTop else dNaN;
plot tf2BullFvgPlotBottom = if showLines and showTimeFrame2  then tf2BullFvgBottom else dNaN;

tf2BearFvgPlotTop.SetLineWeight(2);
tf2BearFvgPlotBottom.SetLineWeight(2);
tf2BearFvgPlotTop.SetDefaultColor(GlobalColor("TimeFrame 2"));
tf2BearFvgPlotBottom.SetDefaultColor(GlobalColor("TimeFrame 2"));
tf2BearFvgPlotTop.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
tf2BearFvgPlotBottom.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);

tf2BullFvgPlotTop.SetLineWeight(2);
tf2BullFvgPlotBottom.SetLineWeight(2);
tf2BullFvgPlotTop.SetDefaultColor(GlobalColor("TimeFrame 2"));
tf2BullFvgPlotBottom.SetDefaultColor(GlobalColor("TimeFrame 2"));
tf2BullFvgPlotTop.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
tf2BullFvgPlotBottom.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);

plot tf3BearFvgPlotTop = if showLines and showTimeFrame3 then tf3BearFvgTop else dNaN;
plot tf3BearFvgPlotBottom = if showLines and showTimeFrame3 then tf3BearFvgBottom else dNaN;
plot tf3BullFvgPlotTop = if showLines and showTimeFrame3 then tf3BullFvgTop else dNaN;
plot tf3BullFvgPlotBottom = if showLines and showTimeFrame3 then tf3BullFvgBottom else dNaN;
tf3BearFvgPlotTop.SetLineWeight(2);
tf3BearFvgPlotBottom.SetLineWeight(2);
tf3BearFvgPlotTop.SetDefaultColor(GlobalColor("TimeFrame 3"));
tf3BearFvgPlotBottom.SetDefaultColor(GlobalColor("TimeFrame 3"));
tf3BearFvgPlotTop.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
tf3BearFvgPlotBottom.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);

tf3BullFvgPlotTop.SetLineWeight(2);
tf3BullFvgPlotBottom.SetLineWeight(2);
tf3BullFvgPlotTop.SetDefaultColor(GlobalColor("TimeFrame 3"));
tf3BullFvgPlotBottom.SetDefaultColor(GlobalColor("TimeFrame 3"));
tf3BullFvgPlotTop.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
tf3BullFvgPlotBottom.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);


