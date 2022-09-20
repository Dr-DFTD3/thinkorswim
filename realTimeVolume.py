## realTimeVolume V 1.2
## dr_phlox
## written 9/18/22
## version 1 -> display volume as a line, highlight in specific colors as 
## volume approaches overbought or oversold conditions
##

declare lower;

## get user input on what labels to display
input plotTotalVolume = yes;
input plotBuyingVolume = yes;
input plotSellingVolume = yes;

## get user input to define overbought and oversold conditions
input over_bought = 90;
input over_sold = 10;

## get the current price action data
def O = open;
def H = high;
def C = close;
def L = low;
def V = volume;
def Buying = V * (C - L) / (H - L);
def Selling = V * (H - C) / (H - L);

## get most recent price action data
def OL = open[1];
def HL = high[1];
def CL = close[1];
def LL = low[1];
def VL = volume[1];
def LBuying = VL * (CL - LL) / (HL - LL);
def LSelling = VL * (HL - CL) / (HL - LL);

## compute buying/selling ratio
plot BSR = 100 * (Buying) / (Buying + Selling);

## create rectangles to display in the pane to highlight overbought and oversold conditions
plot OverSold = over_sold;
plot OverBought = over_bought;

BSR.SetPaintingStrategy(PaintingStrategy. LINE);
BSR.HideTitle();
BSR.HideBubble();
BSR.SetLineWeight(2);
BSR.DefineColor("OverBought", GetColor(1));
BSR.DefineColor("Normal", GetColor(0));
BSR.DefineColor("OverSold", GetColor(8));
BSR.AssignValueColor(if BSR  >=  over_bought then BSR.Color("OverBought") else if BSR <= over_sold then BSR.Color("OverSold") else BSR.Color("Normal"));
AddCloud(0,  over_sold,  Color.liGHT_RED,  Color.RED);
AddCloud(100, over_bought, Color.LigHT_GREEN, Color.GREEN);


def totVol = Round(Buying, 0) + Round(Selling, 0) ;
def buyPercent  = ( Round(Buying, 0)  / totVol ) * 100;
def sellPercent = ( Round(Selling, 0) / totVol ) * 100; 

#######################################Chart Time Frame Buying & Selling Volumes#######################################


AddLabel(plotTotalVolume, "Total Vol: " + volume(period = AggregationPeriod.DAY), Color.WHITE);
AddLabel(plotBuyingVolume, "CurrentBuy Vol: " + Round(Buying, 0) + " -- " + Round(buyPercent, 0) + "%", if Buying > Selling then Color.LIGHT_GREEN else Color.LIGHT_RED);
AddLabel(plotSellingVolume, "CurrentSell Vol: " + Round(Selling, 0) + " -- " + Round(sellPercent, 0) + "%", if Selling > Buying then Color.LIGHT_GREEN else Color.LIGHT_RED);
