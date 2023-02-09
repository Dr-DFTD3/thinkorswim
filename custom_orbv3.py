## customExtremaPoints
## Joe Gonzalez - Dr_Cortex
## plot lines for highs and lows at selected key times
## toggle lines and price for Pre-market highs and lows
## toggle lines and price for the entire over night session highs and lows
## toggle lines and price for the previous day high and lows
## 02/08/2023 v3

declare upper;

input showPmLines = yes;
input showPrevHighsLows = yes;
input showOverNightSessionLines = yes;
input showPriceTags  = yes;
input tagAdjuster = 4;
def b  = tagAdjuster;
def b1 = b + 1;

## regHrs defined
def regHrs = GetTime() >= RegularTradingStart(GetYYYYMMDD()) and
          GetTime() <= RegularTradingEnd(GetYYYYMMDD());

## regHrs Open
def regHrsOpen  = if regHrs[1] == 0 and regHrs == 1
            then open
            else regHrsOpen[1];

## Highest High during regHrs
def regHrsHH  = if isnan(close)
            then regHrsHH[1]
            else if regHrs[1] == 0 and regHrs == 1
            then high
            else if regHrs[1] == 1
            then Max(high, regHrsHH[1]) else  regHrsHH[1];

## Close during regHrs
def regHrsCls  = if regHrs[1] == 0 and regHrs == 1
            then close
            else if regHrs[1] == 1
            then close
            else regHrsCls[1];

## Lowerst Low durng regHrs
def regHrsLL  = if isnan(close)
            then regHrsLL[1]
            else if regHrs[1] == 0 and regHrs == 1
            then low
            else if regHrs[1] == 1
            then Min(low, regHrsLL[1]) else  regHrsLL[1];

## Pre-market Hours High
def pmH  = if GetTime() crosses below RegularTradingEnd(getyyyYMMDD())
            then high
            else if GetTime()<RegularTradingStart(getyyyYMMDD())
            then Max(high, pmH[1]) else pmH[1];

## Pre-market Hours Low
def pmL  = if GetTime() crosses below RegularTradingEnd(getyyyYMMDD())
            then low
            else if GetTime()<RegularTradingStart(getyyyYMMDD())
            then Min(low, pmL[1]) else  pmL[1];

## scan entire overnight session for highs/lows
def onsHigh = if !regHrs and regHrs[1]
             then high
             else if !regHrs and high > onsHigh[1]
                  then high
             else onsHigh[1];

 ## save the highest bar in all of overnight            
def onsHighBar = if !regHrs and high == onsHigh
                then BarNumber()
                else onsHighBar[1];

def onsLow = if !regHrs and regHrs[1]
            then low
            else if !regHrs and low < onsLow[1]
                 then low
            else onsLow[1];

 ## save the lowest bar in all of overnight             
def onsLowBar = if !regHrs and low == onsLow
               then BarNumber()
               else onsLowBar[1];

## update the highest high if conditions met               
def onsHighHigh = if BarNumber() == HighestAll(onsHighBar)
                    then high
                    else onsHighHigh[1];

## update the lowest low if conditions met                    
def onsLowLow = if BarNumber() == HighestAll(onsLowBar)
                   then low
                   else onsLowLow[1];

#Define Days
def Intraday = GetAggregationPeriod() < AggregationPeriod.DAY;
def dateFunc = GetYYYYMMDD();
def notToday = !IsNaN(close) and dateFunc != dateFunc[1];
def days = CompoundValue(1, if notToday then days[1] + 1 else days[1], 0);
def currentDay = (HighestAll(days) - days) ;

#Highs/Lows during lookBackLen days
def pHigh = if currentDay == 1 then regHrsHH else pHigh[1];#today==1 is 1 days ago h,c,l
def pClose = if currentDay == 1 then regHrsCls else pClose[1];
def pLow = if currentDay == 1 then regHrsLL else pLow[1];

## lines for pre-market highs
plot pmHighs = if !isnan(close) then double.nan else pmH;
pmHighs.SetDefaultColor(Color.LIGHT_GREEN);
pmHighs.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
pmHighs.SetHiding(!showPmLines);

## line for pre-market lows
plot pmLows = if !isnan(close) then double.nan else  pmL;
pmLows.SetDefaultColor(Color.PINK);
pmLows.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
pmLows.SetHiding(!showPmLines);

## line for complete over night session highs
plot ONSH = if Intraday and onsHighHigh > 0 then onsHighHigh else Double.NaN;
ONSH.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
ONSH.SetDefaultColor(Color.LIGHT_GRAY);
ONSH.SetHiding(!showOverNightSessionLines);

## line for complete over night session lows
plot ONSL = if Intraday and onsLowLow > 0 then onsLowLow else Double.NaN;
ONSL.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
ONSL.SetDefaultColor(Color.LIGHT_GRAY);
ONSL.SetHiding(!showOverNightSessionLines);

## line for previous high of day
plot pHOD = if  !isnan(close) then double.nan else  pHigh;
pHOD.SetDefaultColor(Color.LIME);
pHOD.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
pHOD.SetHiding(!showPrevHighsLows);

## line for previous low of day
plot pLOD = if !isnan(close) then double.nan else  pLow;
pLOD.SetDefaultColor(Color.LIGHT_RED);
pLOD.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
pLOD.SetHiding(!showPrevHighsLows);

## price and name tags
AddChartBubble(showPmLines and showPriceTags and IsNaN(close[b]) and !IsNaN(close[b1]), pmHighs[b], "pm Highs " + pmHighs, pmHighs.takevalueColor());
AddChartBubble(showPmLines and showPriceTags and IsNaN(close[b]) and !IsNaN(close[b1]), pmLows[b], "pm Lows " + pmLows, pmLows.takevalueColor(), no);
AddChartBubble(showOverNightSessionLines and showPriceTags and IsNaN(close[b]) and !IsNaN(close[b1]), ONSH[b], "ons Highs " + ONSH, ONSH.takevalueColor());
AddChartBubble(showOverNightSessionLines and showPriceTags and IsNaN(close[b]) and !IsNaN(close[b1]), ONSL[b], "ons Lows " + ONSL, ONSL.takevalueColor(), no);
AddChartBubble(showPrevHighsLows and showPriceTags and IsNaN(close[b]) and !IsNaN(close[b1]), pHOD[b], "pHOD " + pHOD, pHOD.takevalueColor());
AddChartBubble(showPrevHighsLows and showPriceTags and IsNaN(close[b]) and !IsNaN(close[b1]), pLOD[b], "pLOD " + pLOD, pLOD.takevalueColor(), no);

## the end

