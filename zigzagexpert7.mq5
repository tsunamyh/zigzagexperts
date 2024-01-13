//+------------------------------------------------------------------+
//|                                                 zigzagexpert.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"
#property indicator_chart_window
// Mohem
#property indicator_buffers 1
#property indicator_plots 1
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
//--- extern parameters
input int ExtDepth = 12;
input int ExtDeviation = 5;
input int ExtBackstep = 3;
input int MovingPeriod_1 = 1;
input int MovingPeriod_2 = 200;
input int MovingShift = 0;

//---- handles for indicators
int ZZ_handle;
int MA_handle_High;
int MA_handle_Low;
int MA_handle_200;

double ZigzagBuf[500];
double MABuf_High[500];
double MABuf_Low[500];
double MABuf_200[500];

double Z_data[10];
int Z_candles[10];
double MA_data_high;    // array for iMA indicator values
double MA_data_low[20]; // array for iMA indicator values
double MA_data_200[10];

double Z_dataPre_0 = 0;
double Z_dataPre_1 = 0;

string trade = "";
int candleCounter = 0;
string finalTrade = "";

//---- indicator buffers

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
{

    ZZ_handle = iCustom(_Symbol, _Period, "Examples\\Zigzag", ExtDepth, ExtDeviation, ExtBackstep);
    MA_handle_High = iMA(_Symbol, _Period, MovingPeriod_1, MovingShift, MODE_SMA, PRICE_HIGH);
    // MA_handle_Low  = iMA(_Symbol, _Period, MovingPeriod_1, MovingShift, MODE_SMA, PRICE_LOW);
    // MA_handle_200 = iMA(_Symbol, _Period, MovingPeriod_2, MovingShift, MODE_SMA, PRICE_CLOSE);
    return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //---
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
{
    static datetime dtBarCurrent = WRONG_VALUE;
    datetime dtBarPrevious = dtBarCurrent;
    dtBarCurrent = iTime(_Symbol, _Period, 0);
    bool bNewBarEvent = (dtBarCurrent != dtBarPrevious);

    if (bNewBarEvent)
    {
        Print("trade:", trade);
        if (trade == "buyActive")
        {
            Print("if(trade == buyActive) {");
            if (candleCounter < 6)
            {
                candleCounter++;

                double low_1 = iLow(Symbol(), Period(), 1);
                Print("low_1:", low_1);
                if (low_1 > Z_data[2])
                {
                    // double price = Z_data[4];
                    double sl = Z_data[0] - (Point() * 50);
                    double tp = Z_data[1];
                    trade("ORDER_TYPE_BUY", "0.1", sl, tp);
                    candleCounter = 0;
                    trade = "";
                }
            }
            else
            {
                candleCounter = 0;
                trade = "";
            }
        }
        if (trade == "sellActive")
        {
            Print("if(trade == sellActive) {");
            if (candleCounter < 6)
            {
                candleCounter++;

                double high_1 = iHigh(Symbol(), Period(), 1);
                Print("high_1:", high_1);
                if (high_1 < Z_data[2])
                {

                    // double price = Z_data[4];
                    double sl = Z_data[0] + (Point() * 50);
                    double tp = Z_data[1];
                    trade("ORDER_TYPE_SELL", "0.1", sl, tp);
                    candleCounter = 0;
                    trade = "";
                }
            }
            else
            {
                candleCounter = 0;
                trade = "";
            }
        }

        CopyBuffer(ZZ_handle, 0, 0, 250, ZigzagBuf);
        // CopyBuffer(MA_handle_Low, 0, 0, 250, MABuf_Low);

        int num = 0;
        int counter = 0;
        for (int i = 249; i > 0; i--)
        {
            if (ZigzagBuf[i] != 0.0)
            {
                if (num < 10)
                {
                    Z_data[num] = ZigzagBuf[i];
                    // MA_data_high[num] = MABuf_High[i];
                    Z_candles[num] = counter;
                    num++;
                }
                counter = 0;
            }
            else
            {
                counter++;
            }
        }
        for (int i = 0; i < 5; i++)
        {
            Print("Z_data[", i, "]: ", Z_data[i]);
            // Print("Z_candles[", i, "]: ", Z_candles[i]);
            // Print("MA_data_high[", i, "]: ", MA_data_high);
        }
        if (checkBuy())
        {
            // Print("Sharte Buy");
            if (Z_data[0] != Z_dataPre_0 && Z_data[1] != Z_dataPre_1)
            {

                trade = "buyActive";
                // Print(Z_data[0],Z_dataPre_0);
                Z_dataPre_0 = Z_data[0];
                Z_dataPre_1 = Z_data[1];
            } //---

            // Print("shart bargharar shod!!!!!");
        }
        else
        {
            Print("Buy ELSE");
            if (checkSell())
            {
                Print("Sharte Sell");
                if (Z_data[0] != Z_dataPre_0 && Z_data[1] != Z_dataPre_1)
                {
                    // Print("(Z_data[3] - Z_data[2]) / (Z_data[5] - Z_data[4]) :", (Z_data[3] - Z_data[2]) / (Z_data[5] - Z_data[4]));
                    trade = "sellActive";
                    Print("sharte Dovvom::::::>>>>", trade);
                    Z_dataPre_0 = Z_data[0];
                    Z_dataPre_1 = Z_data[1];
                }
                else
                {

                    // int num=0;
                    // for(int i = 249; i > 0; i--) {
                    //         if(num < 10) {
                    //             MA_data_high[num] = MABuf_High[i];
                    //             num++;
                    //         }
                    // }
                }

                // Print("shart bargharar shod!!!!!");
            }
        }
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkBuy()
{
    return (
        Z_data[2] > Z_data[4] &&
        Z_data[3] > Z_data[2] &&
        Z_data[3] < Z_data[1] &&
        Z_data[0] < Z_data[2] &&
        // //((Z_candles[1]+1)/ (Z_candles[2]+1)) > 1.5  &&
        (Z_candles[4] + Z_candles[3]) > (Z_candles[2] + Z_candles[1]) &&
        (Z_candles[2] / Z_candles[4] > 0.5 ||
        Z_candles[2] / Z_candles[4] < 1.5) &&
        (Z_data[1] - Z_data[2]) > (Z_data[3] - Z_data[4]) &&
        (Z_data[3] - Z_data[4]) > (Point() * 100));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkSell()
{
    return (
        Z_data[2] < Z_data[4] &&
        Z_data[3] < Z_data[2] &&
        Z_data[3] > Z_data[1] &&
        Z_data[0] > Z_data[2] &&
        (Z_candles[4] + Z_candles[3]) > (Z_candles[2] + Z_candles[1]) &&
        (Z_candles[2] / Z_candles[4] > 0.5 ||
        Z_candles[2] / Z_candles[4] < 1.5) &&
        (Z_data[2] - Z_data[1]) > (Z_data[4] - Z_data[3]) &&
        (Z_data[4] - Z_data[3]) > (Point() * 100));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void trade(string type, string vl, double sl, double tp)
{

    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    if (type == "ORDER_TYPE_BUY")
    {
        request.type = ORDER_TYPE_BUY;
    }
    if (type == "ORDER_TYPE_SELL")
    {
        request.type = ORDER_TYPE_SELL;
    }

    // request.type     =type;
    // Print(type, "||", request.type);
    request.action = TRADE_ACTION_DEAL;
    request.symbol = Symbol();
    request.volume = StringToDouble(vl);
    request.sl = (sl);
    request.tp = (tp);
    // request.magic    =StringToInteger(magic);
    // request.price        = (price);
    request.type_filling = ORDER_FILLING_FOK;
    request.deviation = 5;
    request.expiration = TimeCurrent() + 1200 * 3;
    request.type_time = ORDER_TIME_SPECIFIED;
    if (type == "ORDER_TYPE_SELL")
    {
        request.price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    }
    if (type == "ORDER_TYPE_BUY")
    {
        request.price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    }
    // OrderSend(request,result);
    // Print(__FUNCTION__, request.price);
    // Socket_Send(magic+"|"+"(string)result.deal"+"|"+"magic");
    bool success = OrderSend(request, result);
    // Print("success: ", success);
    if (!success)
    {
        uint answer = result.retcode;
        // Print("TradeLog: Trade request failed. Error = ", GetLastError());
        switch (answer)
        {
        //--- requote
        case 10004:
        {
            // Print("TRADE_RETCODE_REQUOTE");
            // Print("request.price = ", request.price, "   result.ask = ",
            //       result.ask, " result.bid = ", result.bid);
            break;
        }
        //--- order is not accepted by the server
        case 10006:
        {
            // Print("TRADE_RETCODE_REJECT");
            // Print("request.price = ", request.price, "   result.ask = ",
            //       result.ask, " result.bid = ", result.bid);
            break;
        }
        //--- invalid price
        case 10015:
        {
            // Print("TRADE_RETCODE_INVALID_PRICE");
            // Print("request.price = ", request.price, "   result.ask = ",
            //       result.ask, " result.bid = ", result.bid);
            break;
        }
        //--- invalid SL and/or TP
        case 10016:
        {
            // Print("TRADE_RETCODE_INVALID_STOPS");
            // Print("request.sl = ", request.sl, " request.tp = ", request.tp);
            // Print("result.ask = ", result.ask, " result.bid = ", result.bid);
            break;
        }
        //--- invalid volume
        case 10014:
        {
            // Print("TRADE_RETCODE_INVALID_VOLUME");
            // Print("request.volume = ", request.volume, "   result.volume = ",
            //       result.volume);
            break;
        }
        //--- not enough money for a trade operation
        case 10019:
        {
            // Print("TRADE_RETCODE_NO_MONEY");
            // Print("request.volume = ", request.volume, "   result.volume = ",
            //       result.volume, "   result.comment = ", result.comment);
            break;
        }
        //--- some other reason, output the server response code
        default:
        {
            // Socket_Send("{\"status\": \"trade\", \"type\":\""+ globalType +"\",\"magic\":"+globalMagic+",\"ticket\":"+ticket+",\"openPrice\":"+openPrice+",\"vl\":"+vl+",\"sl\":"+sl+",\"tp\":"+tp+"}|");
            // Print("Other answer = ", answer);
        }
        }
        //--- notify about the unsuccessful result of the trade request by returning false
    }
    else
    {
        // Print("ticket :",result.order,",price:",result.price,",retcode:",result.retcode,",request.price:",request.price);

        // PositionSelectByTicket();
        // double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        // Print(openPrice);
        // Socket_Send("{\"status\": \"trade\", \"type\":\""+ type +"\",\"magic\":"+magic+",\"ticket\":"+(string)result.order+",\"openPrice\":"+(string)openPrice+",\"vl\":"+(string)result.volume+",\"sl\":"+sl+",\"tp\":"+tp+"}|");
        // magic+"|"+(string)result.order+"|"+(string)result.volume+"|"+sl+"|"+tp+"|"+"magic");
    }
}
//+------------------------------------------------------------------+
