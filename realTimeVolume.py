## realTimeVolume V 1.2
## dr_phlox
## written 9/18/22
## version 1 -> display volume as a line, highlight in specific colors as 
## volume approaches overbought or oversold conditions
##

declare lower;

## get user input on what labels to display
input ShowTotalVolume = yes;
input ShowBuyingVolume = yes;
input ShowSellingVolume = yes;


## get user input to define overbought and oversold conditions
input ovrBought = 90;
input ovrSold = 10;

## compute buying and selling volume using current price action
## Buy + Sell = V
## buy volume is obtained by scaling total volume with the advancing side of a bullish candle
## sell volume is obtained by scaling total volume with the declining side of a bearish candle
## V(c-l/h-l) + V(h-c/h-l) = V[c - l + h - c]/(h-l) = V(h-l/h-l) = V
def buyVol = volume * (close - low) / (high - low);
def sellVol = volume * (high - close) / (high - low);

## compute buy/sell ratio
plot buySellRatio = 100 * (buyVol) / (buyVol + sellVol);

## create rectangles to display in the pane to highlight overbought and oversold conditions
plot OverSold = ovrSold;
plot OverBought = ovrBought;

## this area defines the code to draw shaded regions indicating the over bought and over sold regions
## they can be redefined by the user via inputs
buySellRatio.SetPaintingStrategy(PaintingStrategy.LINE);
buySellRatio.HideTitle();
buySellRatio.HideBubble();

## this bit of code defines the color of the line in real time
## i chose the obvious green and red, but you can change these by hardcoding your favorite colors.
## i cant get this to be a user input for some reason
buySellRatio.SetLineWeight(2);
buySellRatio.DefineColor("OverBought", Color.LIGHT_GREEN );
buySellRatio.DefineColor("Normal", Color.LIGHT_GRAY);
buySellRatio.DefineColor("OverSold", Color.LIGHT_RED);
## do some fancy realtime painting of the line based on the buying/selling ratio
buySellRatio.AssignValueColor(if buySellRatio  >=  ovrBought then buySellRatio.Color("OverBought") else if buySellRatio <= ovrSold then buySellRatio.Color("OverSold") else buySellRatio.Color("Normal"));

## draw horizontal lines to highlight the edge of the over bought/sold regions
AddCloud(0,  ovrSold,  Color.LIGHT_RED,  Color.RED);
AddCloud(100, ovrBought, Color.LIGHT_GREEN, Color.GREEN);

## compute some data for display in labels
def totVol = Round(buyVol, 0) + Round(sellVol, 0) ;
def buyPercent  = ( Round(buyVol, 0)  / totVol ) * 100;
def sellPercent = ( Round(sellVol, 0) / totVol ) * 100; 

## labels to show computed volume data. they can be selectively turned off/on via user input
AddLabel(ShowTotalVolume, "Total Vol: " + volume(period = AggregationPeriod.DAY), Color.WHITE);
AddLabel(ShowBuyingVolume, "Buying Vol: " + Round(buyVol, 0) + " -> " + Round(buyPercent, 0) + "%", if buyVol > sellVol then Color.LIGHT_GREEN else Color.LIGHT_RED);
AddLabel(ShowSellingVolume, "Selling Vol: " + Round(sellVol, 0) + " -> " + Round(sellPercent, 0) + "%", if sellVol > buyVol then Color.LIGHT_GREEN else Color.LIGHT_RED);

## the end