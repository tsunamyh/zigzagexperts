//+------------------------------------------------------------------+
//|                                                 zigzagexpert.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
// Mohem
#property indicator_buffers 1
#property indicator_plots   1
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
//--- extern parameters
input int      ExtDepth=5;
input int      ExtDeviation=5;
input int      ExtBackstep=3;

int ZZ_handle;
double ZigzagBuf[500];
double Z_data[8];
double Z_dataPre_0 = 0;
double Z_dataPre_1 = 0;
int OnInit()
  {

   ZZ_handle=iCustom(_Symbol,_Period,"Examples\\Zigzag",ExtDepth,ExtDeviation,ExtBackstep);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   static datetime dtBarCurrent  = WRONG_VALUE;
   datetime dtBarPrevious = dtBarCurrent;
   dtBarCurrent  = iTime( _Symbol, _Period, 0 );
   bool bNewBarEvent  = ( dtBarCurrent != dtBarPrevious );
        
   if(bNewBarEvent)
   {

    //double Z_dataPrevious = Z_data[0];
    CopyBuffer(ZZ_handle,0,0,200,ZigzagBuf);
    Print("rates_total????????????????????????????????????????????????????????????:");
    int num = 0;
    for(int i=200;i>0;i--)
    {
     if(ZigzagBuf[i] != 0.0)
     {
       if(num < 8)
       {
         Z_data[num] = ZigzagBuf[i];
         num++;
       }        
          //Print("zigzagBuf[",i,"]",ZigzagBuf[i]);
      }
    }
    Z_dataPre_0 = Z_data[0];
    Z_dataPre_1 = Z_data[1];

    
   if(
      Z_data[4] < Z_data[6] &&
      Z_data[3] < Z_data[5] &&
      Z_data[4] < Z_data[2] &&
      Z_data[1] < Z_data[3] &&
      Z_data[2] < Z_data[0] 
      )
     {
      //if(Z_data[0] != Z_dataPre_0 && Z_data[1] != Z_dataPre_1 )
      //{
        trade("ORDER_TYPE_BUY_LIMIT","0.1",Z_data[1],Z_data[0],Z_data[4]);
        Print(Z_data[0],Z_dataPre_0);
        Z_dataPre_0 = Z_data[0];
        Z_dataPre_1 = Z_data[1];
      //}//---
      
      Print("shart bargharar shod!!!!!");
     }  
     for(int i=0;i<8;i++)
       {
         Print("Z_data[",i,"]: ",Z_data[i]);
       }
   }
  }

void trade(string type,string vl,double sl,double tp,double price)
{  

   MqlTradeRequest request= {};
   MqlTradeResult result= {};
   if (type == "ORDER_TYPE_BUY_LIMIT"){ request.type   =ORDER_TYPE_BUY_LIMIT;}
   if (type == "ORDER_TYPE_SELL_LIMIT"){ request.type  =ORDER_TYPE_SELL_LIMIT;}
   
   //request.type     =type;
   Print(type,"||",request.type);
   request.action   =TRADE_ACTION_PENDING;                    
   request.symbol   =Symbol();
   request.volume   =StringToDouble(vl); 
   request.sl       =(sl);        
   request.tp       =(tp);   
   //request.magic    =StringToInteger(magic);            
   request.price    =(price);
   request.type_filling = ORDER_FILLING_FOK;
   request.deviation =5; 
   request.expiration = TimeCurrent() + 180;
   request.type_time = ORDER_TIME_SPECIFIED;
   //OrderSend(request,result);
   Print(__FUNCTION__,request.price);
   //Socket_Send(magic+"|"+"(string)result.deal"+"|"+"magic");
   bool success=OrderSend(request,result);
   Print("success: ",success);
   if(!success)
     {
      uint answer=result.retcode;
      Print("TradeLog: Trade request failed. Error = ",GetLastError());
      switch(answer)
        {
         //--- requote
         case 10004:
           {
            Print("TRADE_RETCODE_REQUOTE");
            Print("request.price = ",request.price,"   result.ask = ",
                  result.ask," result.bid = ",result.bid);
            break;
           }
         //--- order is not accepted by the server
         case 10006:
           {
            Print("TRADE_RETCODE_REJECT");
            Print("request.price = ",request.price,"   result.ask = ",
                  result.ask," result.bid = ",result.bid);
            break;
           }
         //--- invalid price
         case 10015:
           {
            Print("TRADE_RETCODE_INVALID_PRICE");
            Print("request.price = ",request.price,"   result.ask = ",
                  result.ask," result.bid = ",result.bid);
            break;
           }
         //--- invalid SL and/or TP
         case 10016:
           {
            Print("TRADE_RETCODE_INVALID_STOPS");
            Print("request.sl = ",request.sl," request.tp = ",request.tp);
            Print("result.ask = ",result.ask," result.bid = ",result.bid);
            break;
           }
         //--- invalid volume
         case 10014:
           {
            Print("TRADE_RETCODE_INVALID_VOLUME");
            Print("request.volume = ",request.volume,"   result.volume = ",
                  result.volume);
            break;
           }
         //--- not enough money for a trade operation 
         case 10019:
           {
            Print("TRADE_RETCODE_NO_MONEY");
            Print("request.volume = ",request.volume,"   result.volume = ",
                  result.volume,"   result.comment = ",result.comment);
            break;
           }
         //--- some other reason, output the server response code 
         default:
           {
           // Socket_Send("{\"status\": \"trade\", \"type\":\""+ globalType +"\",\"magic\":"+globalMagic+",\"ticket\":"+ticket+",\"openPrice\":"+openPrice+",\"vl\":"+vl+",\"sl\":"+sl+",\"tp\":"+tp+"}|");
            Print("Other answer = ",answer);
           }
        }
      //--- notify about the unsuccessful result of the trade request by returning false
     } else {
        //Print("ticket :",result.order,",price:",result.price,",retcode:",result.retcode,",request.price:",request.price);

        
        //PositionSelectByTicket();
        //double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        //Print(openPrice);
        //Socket_Send("{\"status\": \"trade\", \"type\":\""+ type +"\",\"magic\":"+magic+",\"ticket\":"+(string)result.order+",\"openPrice\":"+(string)openPrice+",\"vl\":"+(string)result.volume+",\"sl\":"+sl+",\"tp\":"+tp+"}|");
        //magic+"|"+(string)result.order+"|"+(string)result.volume+"|"+sl+"|"+tp+"|"+"magic");
     }
}