## OBReversal
## This is an indicator that attempts to predict reversals based on identifying order blocks
## Order blocks (OB) are large institutional orders that have a characteristic pattern 
## of a basing candle, followed by a series of 3, 4 or 5 candles with overlapping bodies
## A common by-product of order blocks is the generation of a fair value gap that is very commonly
## filled immediately. By identifying the 3/4/5 candles series we can predict when the OB is finished
## and a possible reversal will begin.

## This script also includes pattern matching for advance blocks. These are a component of order blocks
## that can help identify the enc and reversal of the block. An advance block is characterized by a series
## of at least 3 candles, that are increasing in price, but decreasing in size, with the final candle in 
## the series having a large upper shadow (large wick relative to the body)

## Order blocks occur on all time frames and not all OB result in the same behavior, some reverse only a small
## amount while others completely change trend. By incorporating HTF chart events or moving average crossovers
## spurious OB's can be filtered to plot only the highest potential reversals.

## Alex (Alex Kingdom) Joe Gonzalez (Dr_Cortex)
## 08.20.2023

## global stuff
DefineGlobalColor("BullishFVG", Color.GREEN);
DefineGlobalColor("BearishFVG", Color.RED);
def dNaN = double.NaN;
 
##inputs for OB criteria  
input OBCandleCount = {"Four", "Five", default "Three"}; #hint OBCandleCount: Number of candles used to define an order block.
input showAdvBlocks = no; #hint showAdvBlocks: Plot a marker identifying advance blocks in a bullish or bearish series.
input signalFilter = {"MovingAverage", "FVG", "AdvanceBlocks", default "None"}; #hint signalFilter: Filter spurious bull/bear signals using multiple chart events.

##inputs for FVG criteria
input fvgSize = 0.05; #hint fvgSize: Percent of movement in price used to define a valid FVG. Smaller values displays all FVG, larger values only displays largest FVG.
input fvgTimeFrame = AggregationPeriod.THIRTY_MIN; #hint fvgTimeFrame: Time frame for plotting FVG. Must be larger than chart time or no FVG will be displayed.
input showFvgLines = no; #hint showFvgLines: If yes, show lines marking the top and bottom of an FVG
input shadeFvgRegions = no; #hint shadeFvgRegions: If yes, highlight the region between the top and bottom of an FVG
##inputs for MA crossover criteria
input movAvgType = AverageType.EXPONENTIAL; #hint movAvgType: Select the averaging scheme for use in the moving average calculation
input fastMovAvg = 1; #hint fastMovAvg: Set the length of the fast (short time duration) moving average
input slowMovAvg = 9; #hint slowMovAvg: Set the length of the slow (long time duration) moving average
input showMovAvg = no; #hint showMovAvg: Display the selected fast and slow moving averages
input shadeMACrossOver = no; #hint shadeMACrossOver: Shade the region between moving averages, changes color when a crossover occurs


AddLabel(yes,"Signal Filter: " + signalFilter + "  ",color.WHITE);

## general variables used for analyzing patterns
def topWick = high - Max(open, close);
def bottomWick = Min(open, close) - low;
def candleBody = AbsValue(open - close);
def candleWeight = AbsValue(close-open)/tickSize();
def greenCandles = if close > open then 1 else 0;
def redCandles = if close < open then 1 else 0;
def doji = if close == open then 1 else 0;

def bearAbCrit1; 
def bearAbCrit2;
def bearAbCrit3;

def bullAbCrit1;
def bullAbCrit2;
def bullAbCrit3;

def isBearAdvBlock;
def isBullAdvBlock;
def isBullEngulf;
def isBearEngulf;

def bullSignal;
def bearSignal; 

plot endBearOB;
plot endBullOB;
plot bearishAdvBlock;
plot bullishAdvBlock;

## begin code for locating and highlighting FVG
## define some variables to make code more readable
## mtfCYHigh/Low
## mtf = multiTimeFrame
## C = candle
## Y = candle number, 1 or 3 in the FVG pattern
## High/Low of candle 1 or candle 3 in the pattern
def mtfLow = low(period = fvgTimeFrame);
def mtfHigh = high(period = fvgTimeFrame);
def mtfC1Low = mtfLow[2];
def mtfC3Low = mtfLow;
def mtfC1High = mtfHigh[2];
def mtfC3High = mtfHigh;

## check if the bearish 3-candle pattern exists 
def mtfBearFvg = if mtfC1Low - mtfC3High > 0 then 1 else 0;
## compare the size to the user defined price width to decide if the FVG is worth plotting
def mtfBearFvgPct = if AbsValue((mtfC3High -mtfC1Low)/mtfC1Low) > fvgSize/100 then 1 else 0;
## check if the bullish 3-candle pattern exists 
def mtfBullFvg = if mtfC3Low - mtfC1High > 0 then 1 else 0;
## compare the size to the user defined price width to decide if the FVG is worth plotting
def mtfBullFvgPct = if AbsValue((mtfC3Low - mtfC1High)/mtfC1High) > fvgSize/100 then 1 else 0;

## if the bearish 3-candle pattern exists and the FVG size is suitable, store the low of the 1st candle in the series
def mtfBearFvgHTemp = if mtfBearFvg and mtfBearFvgPct then mtfC1Low else 0;
## if the bearish 3-candle pattern exists and the FVG size is suitable, store the high of the 3rd candle in the series  
def mtfBearFvgLTemp = if mtfBearFvgHTemp then mtfC3High else dNaN;

## if the bullish 3-candle pattern exists and the FVG size is suitable, store the low of the 3rd candle in the series
def mtfBullFvgHTemp = if mtfBullFvg and mtfBullFvgPct then mtfC3Low else 0;
## if the bullish 3-candle pattern exists and the FVG size is suitable, store the high of the 1st candle in the series
def mtfBullFvgLTemp = if mtfBullFvgHTemp then mtfC1High else dNaN;


## check if the current FVG is still active or if a new one is to be drawn
def mtfBearFvgHActive = if mtfBearFvgHTemp 
                            then mtfBearFvgHTemp 
                        else if mtfC3High > mtfBearFvgHActive[1] 
                            then dNaN 
                        else mtfBearFvgHActive[1];
def mtfBearFvgLActive = if mtfBearFvgHTemp 
                            then mtfBearFvgLTemp 
                        else if mtfC3High > mtfBearFvgHActive[1] 
                            then dNaN 
                        else mtfBearFvgLActive[1];

def mtfBullFvgLActive = if mtfBullFvgHTemp 
                            then mtfBullFvgLTemp 
                        else if mtfC3Low < mtfBullFvgLActive[1] 
                            then dNaN 
                        else mtfBullFvgLActive[1];
def mtfBullFvgHActive = if mtfBullFvgHTemp 
                            then mtfBullFvgHTemp 
                        else if mtfC3Low < mtfBullFvgLActive[1] 
                            then dNaN 
                        else mtfBullFvgHActive[1];

## store the top and bottom of each FVG for plotting later
def mtfBearFvgTop = if mtfBearFvgHActive then mtfBearFvgHActive else dNaN;
def mtfBearFvgBottom = if mtfBearFvgLActive then mtfBearFvgLActive else dNaN;

def mtfBullFvgTop = if mtfBullFvgHActive then mtfBullFvgHActive else dNaN;
def mtfBullFvgBottom = if mtfBullFvgLActive then mtfBullFvgLActive else dNaN;

## check if price is in an FVG
def inBullFvg = if low < mtfBullFvgTop then 1 else 0;
def inBearFvg = if high > mtfBearFvgBottom then 1 else 0;

## display control for FVG 
def showFvgTf = if signalFilter == signalFilter.FVG or showFvgLines or shadeFvgRegions then 1 else 0;
AddLabel(showFvgTf,fvgTimeFrame/60000 + " min FVG  ",color.ORANGE);
plot mtfBearFvgPlotTop = if showFvgLines then mtfBearFvgTop else dNaN;
plot mtfBearFvgPlotBottom = if showFvgLines then mtfBearFvgBottom else dNaN;
plot mtfBullFvgPlotTop = if showFvgLines then mtfBullFvgTop else dNaN;
plot mtfBullFvgPlotBottom = if showFvgLines then mtfBullFvgBottom else dNaN;

mtfBearFvgPlotTop.SetLineWeight(1);
mtfBearFvgPlotTop.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
mtfBearFvgPlotTop.SetDefaultColor(GlobalColor("BearishFVG"));
mtfBearFvgPlotBottom.SetLineWeight(1);
mtfBearFvgPlotBottom.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
mtfBearFvgPlotBottom.SetDefaultColor(GlobalColor("BearishFVG"));

mtfBullFvgPlotTop.SetLineWeight(1);
mtfBullFvgPlotTop.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
mtfBullFvgPlotTop.SetDefaultColor(GlobalColor("BullishFVG"));
mtfBullFvgPlotBottom.SetLineWeight(1);
mtfBullFvgPlotBottom.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
mtfBullFvgPlotBottom.SetDefaultColor(GlobalColor("BullishFVG"));




AddCloud(if shadeFvgRegions then mtfBearFvgBottom else dNaN, if shadeFvgRegions then mtfBearFvgTop else dNaN, GlobalColor("BearishFVG"));
AddCloud(if shadeFvgRegions then mtfBullFvgTop else dNaN, if shadeFvgRegions then mtfBullFvgBottom else dNaN, GlobalColor("BullishFVG"));


## moving average filtering
def fastMA = MovingAverage(movAvgType,close,fastMovAvg);
def slowMA = MovingAverage(movAvgType,close,slowMovAvg);
def bullishCrossover = if fastMA crosses above slowMA then 1 else 0;
def bearishCrossover = if fastMA crosses below slowMA then 1 else 0;


plot fastMALine = if showMovAvg then fastMA else dNaN;
fastMALine.SetLineWeight(1);
fastMALine.SetDefaultColor(color.WHITE);

plot slowMALine = if showMovAvg then slowMA else dNaN;
slowMALine.SetLineWeight(1);
slowMALine.SetDefaultColor(color.ORANGE);

AddCloud(if shadeMACrossOver then fastMA else dNaN, if shadeMACrossOver then slowMA else dNaN, Color.WHITE, Color.ORANGE);

## begin code for pattern recognition of the OB 3,4,5-candle drive
# def greenCandles = if close > open then 1 else 0;
# def redCandles = if close < open then 1 else 0;

## A bearish OB is characterized by  a green or doji candle leading to a series of 3/4/5 red candles
## A bullish OB is characterized by a red or doji candle leading to a series of 3/4/5 green candles
## An OB reversal is characterized by 3,4,5 sequential red or green candles, followed by a doji or opposite trend candle
## An AdvBlock is characterized by a series of 3 red or green sequential candles
## that are advancing the preceeding candle in price and decreasing in body size
switch(OBCandleCount){
case Five:
    bearAbCrit1 = if greenCandles and greenCandles[1]  and greenCandles[2]  and greenCandles[3]  then 1 else 0;
    bearAbCrit2 = if bearAbCrit1 and close > close[1] and close[1] > close[2] and close[2] > close[3] then 1 else 0;
    bearAbCrit3 = if bearAbCrit2 and candleBody < candleBody[1] and candleBody[1] < candleBody[2] and candleBody[2] < candleBody[3] then 1 else 0;
    isBearAdvBlock = if bearAbCrit3 then 1 else 0;

    isBullEngulf =  if (greenCandles[6] or doji[6]) and
                      redCandles[5] and
                      redCandles[4] and
                      redCandles[3] and
                      redCandles[2] and
                      redCandles[1] and
                      (greenCandles or doji)
                        then 1
                    else 0;

    bullAbCrit1 = if redCandles and redCandles[1]  and redCandles[2]  and redCandles[3]  then 1 else 0;
    bullAbCrit2 = if bullAbCrit1 and close < close[1] and close[1] < close[2] and close[2] < close[3] then 1 else 0;
    bullAbCrit3 = if bullAbCrit2 and candleBody < candleBody[1] and candleBody[1] < candleBody[2] and candleBody[2] < candleBody[3] then 1 else 0;
    isBullAdvBlock = if bullAbCrit3 then 1 else 0;

    isBearEngulf =  if (redCandles[6] or doji[6]) and
                      greenCandles[5] and 
                      greenCandles[4] and 
                      greenCandles[3] and
                      greenCandles[2] and
                      greenCandles[1] and
                      (redCandles or doji)
                        then 1
                    else 0;
case Four:
    bearAbCrit1 = if greenCandles and greenCandles[1]  and greenCandles[2]  and greenCandles[3]  then 1 else 0;
    bearAbCrit2 = if bearAbCrit1 and close > close[1] and close[1] > close[2] and close[2] > close[3] then 1 else 0;
    bearAbCrit3 = if bearAbCrit2 and candleBody < candleBody[1] and candleBody[1] < candleBody[2] and candleBody[2] < candleBody[3] then 1 else 0;
    isBearAdvBlock = if bearAbCrit3 then 1 else 0;
    isBullEngulf =  if (greenCandles[5] or doji[5]) and
                      redCandles[4] and
                      redCandles[3] and
                      redCandles[2] and
                      redCandles[1] and
                      (greenCandles or doji)
                        then 1
                    else 0;

    bullAbCrit1 = if redCandles and redCandles[1]  and redCandles[2]  and redCandles[3]  then 1 else 0;
    bullAbCrit2 = if bullAbCrit1 and close < close[1] and close[1] < close[2] and close[2] < close[3] then 1 else 0;
    bullAbCrit3 = if bullAbCrit2 and candleBody < candleBody[1] and candleBody[1] < candleBody[2] and candleBody[2] < candleBody[3] then 1 else 0;
    isBullAdvBlock = if bullAbCrit3 then 1 else 0;

    isBearEngulf =  if (redCandles[5] or doji[5]) and
                      greenCandles[4] and 
                      greenCandles[3] and
                      greenCandles[2] and
                      greenCandles[1] and
                      (redCandles or doji)
                        then 1
                    else 0;
## default is a series of 3 candles, the traditional bare minimum for an OB
default: 
    bearAbCrit1 = if greenCandles and greenCandles[1]  and greenCandles[2]  and greenCandles[3]  then 1 else 0;
    bearAbCrit2 = if bearAbCrit1 and close > close[1] and close[1] > close[2] and close[2] > close[3] then 1 else 0;
    bearAbCrit3 = if bearAbCrit2 and candleBody < candleBody[1] and candleBody[1] < candleBody[2] and candleBody[2] < candleBody[3] then 1 else 0;
    isBearAdvBlock = if bearAbCrit3 then 1 else 0;
    isBullEngulf =  if (greenCandles[4] or doji[4]) and
                      redCandles[3] and
                      redCandles[2] and
                      redCandles[1] and
                      (greenCandles or doji)
                        then 1
                    else 0;

    bullAbCrit1 = if redCandles and redCandles[1]  and redCandles[2]  and redCandles[3]  then 1 else 0;
    bullAbCrit2 = if bullAbCrit1 and close < close[1] and close[1] < close[2] and close[2] < close[3] then 1 else 0;
    bullAbCrit3 = if bullAbCrit2 and candleBody < candleBody[1] and candleBody[1] < candleBody[2] and candleBody[2] < candleBody[3] then 1 else 0;
    isBullAdvBlock = if bullAbCrit3 then 1 else 0;

    isBearEngulf =  if (redCandles[4] or doji[4]) and
                      greenCandles[3] and
                      greenCandles[2] and
                      greenCandles[1] and
                      (redCandles or doji)
                        then 1
                    else 0;
}
## end code for OB and advance block pattern recognition


## apply filters to the bullish or bearish signal
switch(signalFilter) {
    case MovingAverage:
        bullSignal = if bullishCrossover and isBullEngulf then 1 else 0;
        bearSignal = if bearishCrossover and isBearEngulf then 1 else 0;
    case FVG:
        bullSignal = if isBullEngulf and inBullFvg then 1 else 0;
        bearSignal = if isBearEngulf and inBearFvg then 1 else 0;
    case AdvanceBlocks:
        bullSignal = if isBullEngulf and isBullAdvBlock then 1 else 0;
        bearSignal = if isBearEngulf and isBearAdvBlock then 1 else 0;
    default:
        bullSignal = isBullEngulf;
        bearSignal = isBearEngulf;
}

## display control for Advance Blocks
bearishAdvBlock = if showAdvBlocks and isBearAdvBlock then high + (1 * tickSize()) else dNaN;
bearishAdvBlock.SetPaintingStrategy(paintingStrategy.BOOLEAN_ARROW_DOWN); 
bullishAdvBlock = if showAdvBlocks and isBullAdvBlock then low - (1*tickSize()) else dNaN;
bullishAdvBlock.SetPaintingStrategy(paintingStrategy.BOOLEAN_ARROW_UP); 
AddChartBubble(if showAdvBlocks then bearishAdvBlock else double.nan,    high + (5 * tickSize()),"BearAdvBlock",color.DOWNTICK,yes);
AddChartBubble(if showAdvBlocks then bullishAdvBlock else double.nan,    low - (5 * tickSize()),"BullAdvBlock",color.UPTICK,no);

## plot the final signal after any of the filters are applied
endBearOB = if( bullSignal, low - (1 * tickSize()), double.nan);
endBearOB.SetPaintingStrategy(paintingStrategy.BOOLEAN_ARROW_UP);
endBearOB.SetDefaultColor(Color.UPTICK);

endBullOB = if( bearSignal, high + (1 * tickSize()), double.nan);
endBullOB.SetPaintingStrategy(paintingStrategy.BOOLEAN_ARROW_DOWN); 
endBullOB.SetDefaultColor(Color.DOWNTICK);

AddChartBubble(endBearOB, low - (3 * tickSize()),candleWeight,color.UPTICK,no);
AddChartBubble(endBullOB, high + (3 * tickSize()),candleWeight,color.DOWNTICK,yes);

##the end
                        