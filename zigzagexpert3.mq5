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
input int      MovingPeriod_1=50;
input int      MovingPeriod_2=200;
input int      MovingShift=0;

//---- handles for indicators
int ZZ_handle;
int MA_handle_50;
int MA_handle_200;

double ZigzagBuf[1];
double MABuf_50[1];
double MABuf_200[1];

double Z_data[8];
double M50_data[8];
double M200_data[8];  

double Z_dataPre_0 = 0;
double Z_dataPre_1 = 0;
  
int OnInit()
  {

    MA_handle_50=iMA(_Symbol,_Period,MovingPeriod_1,MovingShift,MODE_SMA,PRICE_CLOSE);
    MA_handle_200=iMA(_Symbol,_Period,MovingPeriod_2,MovingShift,MODE_SMA,PRICE_CLOSE);
    ZZ_handle=iCustom(_Symbol,_Period,"Examples\\Zigzag",ExtDepth,ExtDeviation,ExtBackstep);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
  {
   static datetime dtBarCurrent  = WRONG_VALUE;
   datetime dtBarPrevious = dtBarCurrent;
   dtBarCurrent  = iTime( _Symbol, _Period, 0 );
   bool bNewBarEvent  = ( dtBarCurrent != dtBarPrevious );
        
   if(bNewBarEvent)
   {
    int shift = 0 , num = 0;
   //ArraySetAsSeries(MA_data_50,true); 
   //Print("MA_data_50[0]:",MABuf_50[rates_total -1]);
   Print("rates_total: ",rates_total); 
   
   for(shift=0;shift<rates_total && !IsStopped();shift++)
   {
      CopyBuffer(ZZ_handle,0,shift,1,ZigzagBuf);
      CopyBuffer(MA_handle_50,0,shift,1,MABuf_50);
      CopyBuffer(MA_handle_200,0,shift,1,MABuf_200);     
      if(ZigzagBuf[0] != 0.0)
      {
       if(num < 8)
       {
         
         Z_data[num] = ZigzagBuf[0];
         M50_data[num] = MABuf_50[0];
         M200_data[num] = MABuf_200[0];
         num++;
       }        
       //Print("zigzagBuf[",0,"]",ZigzagBuf[0]);
      }
   }
      for(int i=0;i<8;i++)
       {
         Print("Z_data[",i,"]: ",Z_data[i]);
         Print("m50_data[",i,"]: ",M50_data[i]);
         Print("m200_data[",i,"]: ",M200_data[i]);
       }
        if(checkBuy())
     {
      Print("Sharte Buy");
      //for(int i=0;i<8;i++)
      // {
      //   Print("Z_data[",i,"]: ",Z_data[i]);
      // }
      //Print("Z_dataPre_0",Z_dataPre_0);
      //Print("Z_dataPre_1",Z_dataPre_1);
      if(Z_data[0] != Z_dataPre_0 && Z_data[1] != Z_dataPre_1 )
      {
        double price = (Z_data[1] + Z_data[2]) / 2;
        double sl = Z_data[1];
        double tp = Z_data[0];
        trade("ORDER_TYPE_BUY_LIMIT","0.1",sl,tp,price);
        //Print(Z_data[0],Z_dataPre_0);
        Z_dataPre_0 = Z_data[0];
        Z_dataPre_1 = Z_data[1];
      }//---
      
      //Print("shart bargharar shod!!!!!");
     } else
         {
//          Print("Buy ELSE");
//          if(
//            Z_data[4] > Z_data[6] &&
//            Z_data[3] > Z_data[5] &&
//            Z_data[4] > Z_data[2] &&
//            Z_data[1] > Z_data[3] &&
//            Z_data[2] > Z_data[0] &&
//            Z_data[5] > Z_data[4] 
//            )
//           {
//             Print("Sharte Sell");
//             //for(int i=0;i<8;i++)
//             // {
//             //  Print("Z_data[",i,"]: ",Z_data[i]);
//             // }
//             //Print("Z_dataPre_0",Z_dataPre_0);
//             //Print("Z_dataPre_1",Z_dataPre_1);
//             if(Z_data[0] != Z_dataPre_0 && Z_data[1] != Z_dataPre_1 )
//               {
//                double price = (Z_data[1] + Z_data[2]) / 2;
//                double sl = Z_data[1];
//                double tp = Z_data[0];
//                trade("ORDER_TYPE_SELL_LIMIT","0.1",sl,tp,price);
//                //Print(Z_data[0],Z_dataPre_0);
//                Z_dataPre_0 = Z_data[0];
//                Z_dataPre_1 = Z_data[1];
//               }//---
//      
//             //Print("shart bargharar shod!!!!!");
//             }
          }
      }   
   //}
   return(rates_total);
 }

bool checkBuy()
{
  return(
      Z_data[4] < Z_data[6] &&
      Z_data[3] < Z_data[5] &&
      Z_data[4] < Z_data[2] &&
      Z_data[1] < Z_data[3] &&
      Z_data[2] < Z_data[0] &&
      Z_data[5] < Z_data[4] 
      
      );
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
   request.expiration = TimeCurrent() + 1200;
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