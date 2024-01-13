#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  //--

  //--
  return (INIT_SUCCEEDED);
}
void OnTick()
{
  static datetime dtBarCurrent = WRONG_VALUE;
  datetime dtBarPrevious = dtBarCurrent;
  dtBarCurrent = iTime(_Symbol, _Period, 0);
  bool bNewBarEvent = (dtBarCurrent != dtBarPrevious);

  if (bNewBarEvent)
  {
    Print("bNewBarEvent:", bNewBarEvent);
    double open_1 = iOpen(Symbol(), Period(), 1);   // open price of current candle
    double close_1 = iClose(Symbol(), Period(), 1); // close price of current candle
    double high_1 = iHigh(Symbol(), Period(), 1);
    double low_1 = iLow(Symbol(), Period(), 1);

    double open_2 = iOpen(Symbol(), Period(), 2); // open price of the candle next
    double close_2 = iClose(Symbol(), Period(), 2);
    double high_2 = iHigh(Symbol(), Period(), 2);
    double low_2 = iLow(Symbol(), Period(), 2);

    double open_3 = iOpen(Symbol(), Period(), 3); // open price of the candle next
    double close_3 = iClose(Symbol(), Period(), 3);
    double high_3 = iHigh(Symbol(), Period(), 3);
    double low_3 = iLow(Symbol(), Period(), 3);

    // Print("point:",MathAbs(close_3 - open_3) > (Point() * 10));
    //            Print("open_1:",open_1,"| close_1:",close_1);
    //            Print("open_2:",open_2,"| close_2:",close_2);
    //            Print("open_3:",open_3,"| close_3:",close_3);

    Print("................", TimeCurrent() + 180);
    // double high_1 = iHigh(Symbol(),Period(),1);
    // double low_3 = iLow(Symbol(),Period(),3);
    // string sl = DoubleToString(low_3);
    // string tp = DoubleToString(high_1);
    // Print(sl,tp);
    // string price = DoubleToString((open_1 + close_1)/2);
    // trade("ORDER_TYPE_SELL_LIMIT","0.1","1.09666","1.09501","1.09575");
    if (MathAbs(high_3 - low_3) > (Point() * 1))
    {

      if (
          (high_2 - low_2) / (high_3 - low_3) > 1.1 &&
          (high_1 - low_1) / (high_2 - low_2) > 3
          //(close_2 - open_2)/(close_3 - open_3)> 1.1 &&
          //(close_1 - open_1)/(close_2 - open_2)> 1.6
      )
      {
        Print("1");
        if ((close_2 - open_2) > 0 && (close_1 - open_1) > 0)
        {
          if (low_1 > low_2 && low_2 > low_3 && (high_1 - low_3) > Point() * 5000)
          {
            if ((high_1 - close_1) / (close_1 - open_1) > 0.2)
            {
              Print("b");
              string sl = DoubleToString(open_3);
              string tp = DoubleToString(high_1);
              string price = DoubleToString((high_1 + low_1) / 2);
              trade("ORDER_TYPE_BUY_LIMIT", "0.1", sl, tp, price);
            }
          }
        }
        else if ((close_2 - open_2) < 0 && (close_1 - open_1) < 0)
        {
          if (high_1 < high_2 && high_2 < high_3 && (high_3 - low_1) > Point() * 5000)
          {
            if ((close_1 - low_1) / (open_1 - close_1) > 0.2)
            {
              Print("s");
              string sl = DoubleToString(open_3);
              string tp = DoubleToString(low_1);
              string price = DoubleToString((high_1 + low_1) / 2);
              trade("ORDER_TYPE_SELL_LIMIT", "0.1", sl, tp, price);
            }
          }
        }

        Print("OK!!!!");
      }
    }
    if (dtBarPrevious == WRONG_VALUE)
    {
    }
    else
    {
    };
  }
  else
  {
  };
};

void trade(string type, string vl, string sl, string tp, string price)
{

  MqlTradeRequest request = {};
  MqlTradeResult result = {};
  if (type == "ORDER_TYPE_BUY_LIMIT")
  {
    request.type = ORDER_TYPE_BUY_LIMIT;
  }
  if (type == "ORDER_TYPE_SELL_LIMIT")
  {
    request.type = ORDER_TYPE_SELL_LIMIT;
  }

  // request.type     =type;
  Print(type, "||", request.type);
  request.action = TRADE_ACTION_PENDING;
  request.symbol = Symbol();
  request.volume = StringToDouble(vl);
  request.sl = StringToDouble(sl);
  request.tp = StringToDouble(tp);
  // request.magic    =StringToInteger(magic);
  request.price = StringToDouble(price);
  request.type_filling = ORDER_FILLING_FOK;
  request.deviation = 5;
  request.expiration = TimeCurrent() + 180;
  request.type_time = ORDER_TIME_SPECIFIED;
  // OrderSend(request,result);
  Print(__FUNCTION__, request.price);
  // Socket_Send(magic+"|"+"(string)result.deal"+"|"+"magic");
  bool success = OrderSend(request, result);
  Print("success: ", success);
  if (!success)
  {
    uint answer = result.retcode;
    Print("TradeLog: Trade request failed. Error = ", GetLastError());
    switch (answer)
    {
    //--- requote
    case 10004:
    {
      Print("TRADE_RETCODE_REQUOTE");
      Print("request.price = ", request.price, "   result.ask = ",
            result.ask, " result.bid = ", result.bid);
      break;
    }
    //--- order is not accepted by the server
    case 10006:
    {
      Print("TRADE_RETCODE_REJECT");
      Print("request.price = ", request.price, "   result.ask = ",
            result.ask, " result.bid = ", result.bid);
      break;
    }
    //--- invalid price
    case 10015:
    {
      Print("TRADE_RETCODE_INVALID_PRICE");
      Print("request.price = ", request.price, "   result.ask = ",
            result.ask, " result.bid = ", result.bid);
      break;
    }
    //--- invalid SL and/or TP
    case 10016:
    {
      Print("TRADE_RETCODE_INVALID_STOPS");
      Print("request.sl = ", request.sl, " request.tp = ", request.tp);
      Print("result.ask = ", result.ask, " result.bid = ", result.bid);
      break;
    }
    //--- invalid volume
    case 10014:
    {
      Print("TRADE_RETCODE_INVALID_VOLUME");
      Print("request.volume = ", request.volume, "   result.volume = ",
            result.volume);
      break;
    }
    //--- not enough money for a trade operation
    case 10019:
    {
      Print("TRADE_RETCODE_NO_MONEY");
      Print("request.volume = ", request.volume, "   result.volume = ",
            result.volume, "   result.comment = ", result.comment);
      break;
    }
    //--- some other reason, output the server response code
    default:
    {
      // Socket_Send("{\"status\": \"trade\", \"type\":\""+ globalType +"\",\"magic\":"+globalMagic+",\"ticket\":"+ticket+",\"openPrice\":"+openPrice+",\"vl\":"+vl+",\"sl\":"+sl+",\"tp\":"+tp+"}|");
      Print("Other answer = ", answer);
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

void OnDeinit(const int reason)
{
}
