## RangeBreakTargetsandTrend
## This script is used to trade breakouts above the high or below the low for a specified
## time period, typically the opening range of a globex session. Using the concepts of 
## Average True Range (ATR), take profit levels are successively defined as price closes 
## above or below each preceeding take profit level.
## This script also includes the super trend routine which is used to paint the candles
## based on ATR as well. The super trend code has been shown to accurately predict changes in 
## trending price action. 

## The user can select 1 of 3 sessions to trade breakouts, modify the parameters used in the ATR calculation,
## The user can also select to provide audible alerts, plot the stop loss line for the initial break out or break down 

## dr_phlox 08.06.2023


## script to get end time given start time and an offset
## used for defining the full range when logging highest/lowest price
script offsetTime {
  input hrs = 0.0;
  input mins = 0.0;
  input offset = 30.0;

  def ht = hrs + (mins/60.0);
  def ot = ht + (offset/60.0);
  def nh = 100.0*floor(ot);
  def nm = 60.0*(ot-floor(ot));
  plot newTime = nh + nm;
}

declare hide_on_daily;
declare once_per_bar;

input tradingSession = {"Midnight", "London", default "NYSE"}; #hint tradingSession: Define the session for which the opening range will be used for breakouts.
input openRangeDuration = 5; #hint openRangeDuration: Time duration, in minutes, used for calculating the median price, used for predicting session bias.
input fullRangeDuration = 30; #hint fullRangeDuration: Time duration, in minutes, used for logging the highest and lowest price used in defining a break out.
input issueAlerts  = yes; #hint issueAlerts: Alerts on cross of Opening Range.
input tpAtrMult = 2.0; #hint ATRmult: Multiplier for the ATR calculations.
input tpAtrLength = 4; #hint tpAtrLength: Length for the ATR calculation in defining the take profit levels.
input showStopLoss = no; #hint showStopLoss: Plot a line for stop loss on breakouts
input stopLoss = 2.00; #hint: stopLoss: Number of points used to offset from breakout level for displaying the stop loss line


input superTrendAtrMult = 1.0; #hint superTrendAtrMult: Multiplier for the ATR calculations used by Super Trend algorithm
input superTrendAtrLength = 4; #hint superTrendAtrLength: Length for the ATR calculation used by the Super Trend algorithm
input superTrendAvgType = AverageType.HULL; #hint superTrendAvgType: Averaging scheme used by the Super Trend algorithm for determing trend
input superTrendPaintBars = yes; #hint superTrendPaintBars: Color candles according to the Super Trend algorithm, no leaves candle painted in standard way by ToS
input superTrendShowBubbles = yes; #hint superTrendShowBubbles: If yes, display a bubble on the candle at which the trend changed
input superTrendShowPrice = yes; #hint superTrendShowPrice: If yes, display price and action when trend changes, if no only show trend has changed

addlabel(yes, "Trading Session: " + tradingSession+"  ",color.WHITE);

## define market open and range for logging highest/lowest closing price
def marketOpen =  if tradingSession == tradingSession.Midnight
                    then 0000.0
                  else if tradingSession == tradingSession.London
                    then 0300.0
                  else 0930.0;
def openRangeEnd =  if tradingSession == tradingSession.Midnight
                      then marketOpen + openRangeDuration
                    else if tradingSession == tradingSession.London
                      then marketOpen + openRangeDuration
                    else marketOpen + openRangeDuration;
def fullRangeStart =  if tradingSession == tradingSession.Midnight
                        then marketOpen
                      else if tradingSession == tradingSession.London
                        then marketOpen
                      else marketOpen;
def fullRangeEnd =  if tradingSession == tradingSession.Midnight
                      then offsetTime(hrs=0,mins=0,offset=fullRangeDuration)
                    else if tradingSession == tradingSession.London
                      then offsetTime(hrs=3,mins=0,offset=fullRangeDuration)
                    else offsetTime(hrs=9,mins=30,offset=fullRangeDuration);


def hp = high;
def lp = low;
def cp = close;
def barNum = BarNumber();
def sto = 1;
def na = Double.NaN;

## define where to place the tags
def tagLoc = IsNaN(cp[-1]);

## set the median bar based on the range of the first 5 minutes of the defined range
def isIRangeActive = if SecondsTillTime(openRangeEnd) > 0 and SecondsFromTime(marketOpen) >= 0
                        then 1
                     else 0;
## check if it is today if user wants to show only today   
# def today = 1;               
# def today = if sto == 0 or GetDay() == GetLastDay() and SecondsFromTime(marketOpen) >= 0
#               then 1
#             else 0;
def today = if GetDay() == GetLastDay() and SecondsFromTime(marketOpen) >= 0
              then 1
            else 0;

## 5 min range high                
def iRangeHigh = if iRangeHigh[1] == 0 or isIRangeActive[1] == 0 and isIRangeActive == 1
                    then hp
                 else if isIRangeActive and hp > iRangeHigh[1]
                    then hp
                 else iRangeHigh[1];
def activeIRangeHigh = if isIRangeActive or today < 1
                        then na
                       else iRangeHigh;
## 5 min range low                
def iRangeLow = if iRangeLow[1] == 0 or isIRangeActive[1] == 0 and isIRangeActive == 1
                  then lp
                else if isIRangeActive and lp < iRangeLow[1]
                  then lp
                else iRangeLow[1];
def activeIRangeLow = if isIRangeActive or today < 1
                        then na
                      else iRangeLow;
## calculate the range of the first 5 minuts              
def iRangeHighLow = activeIRangeHigh - Round(((activeIRangeHigh - activeIRangeLow) / 2) / TickSize(), 0) * TickSize();

## define the full range requested by user, including iRangeHighLow
def isFullRangeActive = if SecondsTillTime(fullRangeEnd) > 0 and SecondsFromTime(fullRangeStart) >= 0
                          then 1
                        else 0;
## full range high                       
def fullRangeHigh = if fullRangeHigh[1] == 0 or isFullRangeActive[1] == 0 and isFullRangeActive == 1
                      then hp
                    else if isFullRangeActive and hp > fullRangeHigh[1]
                      then hp
                    else fullRangeHigh[1];
## full range low                  
def fullRangeLow = if fullRangeLow[1] == 0 or isFullRangeActive[1] == 0 and isFullRangeActive == 1
                      then lp
                   else if isFullRangeActive and lp < fullRangeLow[1]
                      then lp
                   else fullRangeLow[1];

## get the candle number in the current range, needed as reference when defining a breakout
def rangeEndCandle = if !isFullRangeActive and isFullRangeActive[1]
                        then barNum
                     else rangeEndCandle[1];

## get candle for defining the median line
def iRangeMeanCandle = if !isIRangeActive and isIRangeActive[1]
                        then barNum
                       else iRangeMeanCandle[1];

## get the value for plotting the iRange line
def iRangeLine = if (iRangeHighLow == 0 , na, iRangeHighLow);

## plot the median line of the first 5 minutes of iRange
plot iRangeLinePlot = if BarNumber() >= HighestAll(iRangeMeanCandle)
                        then HighestAll(if IsNaN(cp[-1]) then iRangeLine[1] else na)
                      else na;
iRangeLinePlot.SetDefaultColor(CreateColor(255, 185, 50));#yellow
iRangeLinePlot.SetStyle(Curve.LONG_DASH);
iRangeLinePlot.SetLineWeight(3);
iRangeLinePlot.HideTitle();

## get the highest price in the full specified user range to plot a line
def fullRangeHighLine = if isFullRangeActive or today < 1
                          then na
                        else fullRangeHigh;
plot fullRangeHighLinePlot = if BarNumber() >= HighestAll(rangeEndCandle)
                                then HighestAll(if IsNaN(cp[-1]) then fullRangeHighLine[1] else na)
                             else na;
fullRangeHighLinePlot.SetDefaultColor(CreateColor(2, 100, 172));
fullRangeHighLinePlot.SetStyle(Curve.LONG_DASH);
fullRangeHighLinePlot.SetLineWeight(3);
fullRangeHighLinePlot.HideTitle();

## get the lowest price in the full specified user range to plot a line
def fullRangeLowLine = if isFullRangeActive or today < 1
                          then na
                       else fullRangeLow;
plot fullRangeLowLinePlot = if BarNumber() >= HighestAll(rangeEndCandle)
                              then HighestAll(if IsNaN(cp[-1]) then fullRangeLowLine[1] else na)
                            else na;
fullRangeLowLinePlot.SetDefaultColor(CreateColor(155, 85, 50));
fullRangeLowLinePlot.SetStyle(Curve.LONG_DASH);
fullRangeLowLinePlot.SetLineWeight(3);
fullRangeLowLinePlot.HideTitle();

## check if the user range is ended, needed for predicting closing price
def isEndOfRange = if SecondsTillTime(fullRangeEnd) == 0 then 1 else 0;

## calculate relative position of the median line from the iRange
## if iRangeLine is closer to the lowest price during the full defined range, it is likely price will close below iRangeLine (RED)
## if iRangeLine is closer to the highest price during the full defined range, it is likely price will close above iRangeLine (GREEN)    
## if iRangeLine is balanced between the highest and lowest price during the full range, we predict a range bound day with no bias (AMBER/YELLOW)          
def iRangeRelPostion = (iRangeLine - fullRangeLowLine) / (fullRangeHighLine - fullRangeLowLine);

## assign bias color to label based on relative position of the median line
def dailyBias = if iRangeRelPostion > .5
                  then -1 ## predict down day
                else if iRangeRelPostion < .5
                  then 1 ## predict up day
                else 0; ##  predict range day

## format the text and color of the label based on the computed daily bias
addlabel(yes, if dailyBias == -1 then "Session Bias: BEARISH, close below " + iRangeLine +"  "
              else if dailyBias == 1 then "Session Bias: BULLISH, close above " + iRangeLine+"  "
              else "Session Bias: INSIDE RANGE ",
              if dailyBias == -1 then color.RED
              else if dailyBias == 1 then color.GREEN
              else color.YELLOW);

# def nyseLast = if SecondsTillTime(1600) == 0 and SecondsFromTime(1600) == 0
#                  then cp[1]
#               else nyseLast[1];
# plot nyseClose = if today and nyseLast != 0
#                  then nyseLast
#                  else Double.NaN;
# nyseClose.SetPaintingStrategy(PaintingStrategy.DASHES);
# nyseClose.SetDefaultColor(Color.WHITE);
# nyseClose.HideTitle();
# AddChartBubble(SecondsTillTime(0930) == 0, nyseClose, "prev NYSE close: " + nyseLast, Color.GRAY, yes);


Alert(cp crosses above fullRangeHighLine, "", Alert.BAR, Sound.Bell);
Alert(cp crosses below fullRangeLowLine, "", Alert.BAR, Sound.Ring);

## begin the breakout, SL and target phase
## define a breakout as a candle closing, on any time frame, above the highest price in the full range defined
## 
## Using the stoploss defined by the user, define a line for the stop, plot a line for it if user requests it            
plot breakOutSL = if showStopLoss and barNum >= rangeEndCandle and !isIRangeActive and today
                    then HighestAll(fullRangeHighLinePlot - stopLoss)
                  else na;
breakOutSL.SetStyle(Curve.SHORT_DASH);
breakOutSL.SetDefaultColor(GetColor(5));
breakOutSL.HideTitle();
def markerCandle = if cp crosses above fullRangeHighLine
                   then barNum
                   else na;
AddChartBubble(showStopLoss and barNum == HighestAll(markerCandle), breakOutSL, "BreakOut SL: " + stopLoss + " pts", color.GRAY, no);

## StopLoss for initial break down   
plot breakDownSL = if showStopLoss and barNum >= rangeEndCandle and !isIRangeActive and cp < iRangeLine
                      then HighestAll(fullRangeLowLinePlot + stopLoss)
                   else na;
breakDownSL.SetStyle(Curve.SHORT_DASH);
breakDownSL.SetDefaultColor(GetColor(6));
breakDownSL.HideTitle();
def breakDownCandle = if cp crosses below fullRangeLowLinePlot
                   then barNum
                   else na;
AddChartBubble(showStopLoss and barNum == HighestAll(breakDownCandle), HighestAll(breakDownSL), "BreakDown SL: " + stopLoss + " pts", color.GRAY, yes);


## get the impulse candle that crosses above the high price for the full range
def impulseCandle = if isIRangeActive
                      then na
                    else if !isIRangeActive and cp crosses above fullRangeHighLine
                      then barNum
                    else if !IsNaN(impulseCandle[1]) and cp crosses fullRangeHighLine
                      then impulseCandle[1]
                    else impulseCandle[1];

## use ATR to define the take profit levels for breakouts and breakdowns
def ATR = if isFullRangeActive
          then Round((Average(TrueRange(hp, cp, lp), tpAtrLength)) / TickSize(), 0) * TickSize()
          else ATR[1];


##Breakout take profit levels
## break out TP1 is defined once the a candle closes above the fullRangeHigh
## If a candle closes above breakOutTP1Line, then another TP is calculated and defined with a line plotted in the chart
## A succession of TP's are defined in sequence once the preceding TP is closed above using ATR from the preceeding TP level

## initial take profit for a break out, used to calculate the 2nd take profit if needed
def boTP1 = if hp > fullRangeHighLine and hp[1] <= fullRangeHighLine
              then Round((fullRangeHighLine  + (ATR * tpAtrMult)) / TickSize(), 0) * TickSize()
            else boTP1[1];
plot breakOutTP1Line = if barNum >= impulseCandle
                     then boTP1
                   else na;
breakOutTP1Line.SetPaintingStrategy(PaintingStrategy.DASHES);
breakOutTP1Line.SetLineWeight(1);
breakOutTP1Line.SetDefaultColor(Color.WHITE);
breakOutTP1Line.HideTitle();
AddChartBubble(tagLoc, breakOutTP1Line, "1st TP", Color.WHITE, if cp > breakOutTP1Line then no else yes);

## 2nd take profit
def boTP2 = if cp crosses above boTP1
              then Round((boTP1 + (ATR * tpAtrMult)) / TickSize(), 0) * TickSize()
            else boTP2[1];
plot breakOutTP2Line = if barNum >= impulseCandle
                         then  boTP2
                       else na;
breakOutTP2Line.SetPaintingStrategy(PaintingStrategy.POINTS);
breakOutTP2Line.SetLineWeight(1);
breakOutTP2Line.SetDefaultColor(Color.GRAY);
breakOutTP2Line.HideTitle();
AddChartBubble(tagLoc, breakOutTP2Line, "2nd TP", Color.GRAY, if cp > breakOutTP2Line then no else yes);

## 3rd take profit
def boTP3 = if cp crosses above boTP2
              then Round((boTP2 + (ATR * tpAtrMult)) / TickSize(), 0) * TickSize()
            else boTP3[1];
plot breakOutTP3Line = if barNum >= impulseCandle
                then boTP3
                else na;
breakOutTP3Line.SetPaintingStrategy(PaintingStrategy.POINTS);
breakOutTP3Line.SetLineWeight(1);
breakOutTP3Line.SetDefaultColor(Color.GRAY);
breakOutTP3Line.HideTitle();
AddChartBubble(IsNaN(cp[-1]), breakOutTP3Line, "3rd TP", Color.GRAY, if cp > breakOutTP3Line then no else yes);

## 4th take profit
def boTP4 = if cp crosses above boTP3
                  then Round((boTP3 + (ATR * tpAtrMult)) / TickSize(), 0) * TickSize()
                else boTP4[1];
plot breakOutTP4Line = if barNum >= HighestAll(impulseCandle)
                then boTP4
                else na;
breakOutTP4Line.SetPaintingStrategy(PaintingStrategy.POINTS);
breakOutTP4Line.SetLineWeight(1);
breakOutTP4Line.SetDefaultColor(Color.GRAY);
breakOutTP4Line.HideTitle();
AddChartBubble(tagLoc, breakOutTP4Line, "4th TP", Color.GRAY, if cp > breakOutTP4Line then no else yes);

## 5th take profit
def boTP5 = if cp crosses above boTP4
              then Round((boTP4 + (ATR * tpAtrMult)) / TickSize(), 0) * TickSize()
            else boTP5[1];
plot breakOutTP5Line = if barNum >= impulseCandle
                then boTP5
                else na;
breakOutTP5Line.SetPaintingStrategy(PaintingStrategy.POINTS);
breakOutTP5Line.SetLineWeight(1);
breakOutTP5Line.SetDefaultColor(Color.GRAY);
breakOutTP5Line.HideTitle();
AddChartBubble(tagLoc, breakOutTP5Line, "5th TP", Color.GRAY, if cp > breakOutTP5Line then no else yes);



## break down targets
def bdTP1 = if lp < fullRangeLowLine and lp[1] >= fullRangeLowLine
                    then Round((fullRangeLowLine  - (tpAtrMult * ATR)) / TickSize(), 0) * TickSize()
                    else bdTP1[1];
plot breakDownTP1Line = if barNum >= HighestAll(rangeEndCandle)
                    then HighestAll(if IsNaN(cp[-1])
                                    then bdTP1
                                    else na)
                    else na;
breakDownTP1Line.SetPaintingStrategy(PaintingStrategy.DASHES);
breakDownTP1Line.SetLineWeight(1);
breakDownTP1Line.SetDefaultColor(Color.WHITE);
breakDownTP1Line.HideTitle();
AddChartBubble(tagLoc, bdTP1, "1st TP", Color.WHITE, if cp < breakDownTP1Line then yes else no);

## 2nd take profit
def bdTP2 = if cp crosses below bdTP1
              then Round((bdTP1 - (tpAtrMult * ATR)) / TickSize(), 0) * TickSize()
            else bdTP2[1];
plot breakDownTP2Line =  if barNum >= HighestAll(rangeEndCandle)
                 then HighestAll(if IsNaN(cp[-1])
                                 then bdTP2
                                 else na)
                 else na;
breakDownTP2Line.SetPaintingStrategy(PaintingStrategy.POINTS);
breakDownTP2Line.SetLineWeight(1);
breakDownTP2Line.SetDefaultColor(Color.GRAY);
breakDownTP2Line.HideTitle();
AddChartBubble(tagLoc, bdTP2, "2nd TP", Color.GRAY, if cp < bdTP2 then yes else no);

## 3rd take profit
def bdTP3 = if cp crosses below bdTP2
              then Round((bdTP2 - (tpAtrMult * ATR)) / TickSize(), 0) * TickSize()
            else bdTP3[1];
plot breakDownTP3Line = if barNum >= HighestAll(rangeEndCandle)
                      then HighestAll(if IsNaN(cp[-1]) then bdTP3 else na)
                    else na;
breakDownTP3Line.SetPaintingStrategy(PaintingStrategy.POINTS);
breakDownTP3Line.SetLineWeight(1);
breakDownTP3Line.SetDefaultColor(Color.GRAY);
breakDownTP3Line.HideTitle();
AddChartBubble(tagLoc, bdTP3, "3rd TP", Color.GRAY, if cp < breakDownTP3Line then yes else no);

#4th take profit
def bdTP4 = if cp crosses bdTP3
              then Round((bdTP3 - (tpAtrMult * ATR)) / TickSize(), 0) * TickSize()
            else bdTP4[1];
plot breakDownTP4Line = if barNum >= HighestAll(rangeEndCandle)
                      then HighestAll(if IsNaN(cp[-1]) then bdTP4 else na)
                    else na;
breakDownTP4Line.SetPaintingStrategy(PaintingStrategy.POINTS);
breakDownTP4Line.SetLineWeight(1);
breakDownTP4Line.SetDefaultColor(Color.GRAY);
breakDownTP4Line.HideTitle();
AddChartBubble(tagLoc, bdTP4, "4th TP", Color.GRAY, if cp < breakDownTP4Line then yes else no);

##5th take profit
def bdTP5 = if cp crosses bdTP4
              then Round((bdTP4 - (tpAtrMult * ATR)) / TickSize(), 0) * TickSize()
            else bdTP5[1];
plot breakDownTP5Line = if barNum >= HighestAll(rangeEndCandle)
                          then HighestAll(if IsNaN(cp[-1]) then bdTP5 else na)
                        else na;
breakDownTP5Line.SetPaintingStrategy(PaintingStrategy.POINTS);
breakDownTP5Line.SetLineWeight(1);
breakDownTP5Line.SetDefaultColor(Color.GRAY);
breakDownTP5Line.HideTitle();
AddChartBubble(tagLoc, bdTP5, "5th TP", Color.GRAY, if cp < breakDownTP5Line then yes else no);



## Begin super trend indicator

def stATR = MovingAverage(superTrendAvgType, TrueRange(hp, cp, lp), superTrendAtrLength);
def UP = HL2 + (superTrendAtrMult * stATR);
def DN = HL2 + (-superTrendAtrMult * stATR);
def ST = if cp < ST[1] then UP else DN;
plot SuperTrend = ST;
SuperTrend.AssignValueColor(if cp < ST then Color.RED else Color.GREEN);
AssignPriceColor(if superTrendPaintBars and cp < ST

                    then Color.DOWNTICK

                  else if superTrendPaintBars and cp > ST

                    then Color.UPTICK

                  else Color.CURRENT);


AddChartBubble(superTrendShowBubbles and cp crosses below ST, lp[1], if superTrendShowPrice then "Sell: " + lp[1] else "COT", CreateColor(235, 85, 85));
AddChartBubble(superTrendShowBubbles and cp crosses above ST, hp[1], if superTrendShowPrice then "Buy: " +  hp[1] else "COT", CreateColor(85, 235, 85), no);

## the end
