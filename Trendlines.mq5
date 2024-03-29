//+------------------------------------------------------------------+
//|                                                   Trendlines.mq5 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

#property indicator_label1  "Zpoint"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct trade_points //define the structure for extreme values
  {
   double            price; // price
   int               pos;   // location, bar index
   bool              hpoint;// if yes, it is a peak
   bool              lpoint;// if yes, it is a bottom
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct lines
  {
   int               a;
   int               b;
   double            ax;
   double            bx;
   double            dst;
   double            coef;
  };

//--- extern parameters
input int      ExtDepth=12;
input int      ExtDeviation=5;
input int      ExtBackstep=3;

input int      Min_dist=0;       // Minimum distance
input int      fibo=25;          // Fibo ratio
input int      tolerance=200;     // Tolerance
input int      Intersection_ab=1;//The allowed number of intersections from point a to point b
input int      Intersection_bc=1;//The allowed number of intersections from point b to point c

input string          s1="Up Trend";     // Line settings
input color           UColor=clrGreen;   // Line color 
input ENUM_LINE_STYLE UStyle=STYLE_SOLID; // Line style 
input int             UWidth=1;          // Line width 
input bool            UBack=false;       // Background line 
input bool            USelection=true;   // Select for movements 
input bool            URayLeft=false;    // Continuation of the line to the left 
input bool            URayRight=true;    // Continuation of the line to the right 
input bool            UHidden=true;      // Hidden in the list of objects 
input long            UZOrder=0;         // Priority for mouse click< 

input string          s2="Down Trend";   // Line settings
input color           DColor=clrRed;     // Line color 
input ENUM_LINE_STYLE DStyle=STYLE_SOLID; // Line style 
input int             DWidth=1;          // Line width 
input bool            DBack=false;       // Background line 
input bool            DSelection=true;   // Select for movements 
input bool            DRayLeft=false;    // Continuation of the line to the left 
input bool            DRayRight=true;    // Continuation of the line to the right 
input bool            DHidden=true;      // Hidden in the list of objects 
input long            DZOrder=0;         // Priority for mouse click 


//--- indicator buffers

double         line0[];

//--- 

lines          UpTrend[];
lines          DownTrend[];

int ZZ_handle;
double ZigzagBuffer[1];
trade_points mass[];
int y=0;

int a,b,cross_ab,cross_bc;
double ax,bx,coef,deviation,price;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping

   SetIndexBuffer(0,line0,INDICATOR_DATA);

   ArraySetAsSeries(line0,true);
   ZZ_handle=iCustom(_Symbol,_Period,"Examples\\ZigzagColor",ExtDepth,ExtDeviation,ExtBackstep);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+  
void OnDeinit(const int reason)
  {
   DelObs("Down");
   DelObs("Up");
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   int i,j,limit=0,shift=0;
   
   //

   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(time,true);

   double max=close[1];
   double min=close[1];
   int z=0;

   for(shift=0;shift<rates_total && !IsStopped();shift++)
     {
      CopyBuffer(ZZ_handle,0,shift,1,ZigzagBuffer);
      Print("zigzagBuffer[",shift,"]",ZigzagBuffer[shift]);
      if(ZigzagBuffer[0]>0)
        {

         if(ZigzagBuffer[0]>=max && ZigzagBuffer[0]==high[shift])
           {
            ArrayResize(mass,z+1);
            max=ZigzagBuffer[0];
            mass[z].price=ZigzagBuffer[0];
            mass[z].pos=shift;
            mass[z].hpoint=true;
            mass[z].lpoint=false;
            z++;
           }

         if(ZigzagBuffer[0]<=min && ZigzagBuffer[0]==low[shift])
           {
            ArrayResize(mass,z+1);
            min=ZigzagBuffer[0];
            mass[z].price=ZigzagBuffer[0];
            mass[z].pos=shift;
            mass[z].lpoint=true;
            mass[z].hpoint=false;
            z++;
           }

        }
     }

//+------------------------------------------------------------------+

   for(i=0; i<z; i++)
     {

      if(mass[i].hpoint==true)
        {
         line0[mass[i].pos]=mass[i].price;
        }
      if(mass[i].lpoint==true)
        {
         line0[mass[i].pos]=mass[i].price;
        }
     }
//+------------------------------------------------------------------+    
   y=0;



   for(j=z-1; j>=0; j--)
     {
      if(mass[j].hpoint)
         for(i=j-1; i>=0; i--)
           {
            if(mass[i].hpoint)
               if(i<j)
                 {

                  a=mass[j].pos;
                  b=mass[i].pos;

                  double ratio=double((a-b)*100/a);

                  if(ratio>fibo && ratio<(100-fibo))
                     if(b>Min_dist && (a-b)>Min_dist)
                       {

                        ax=mass[j].price;
                        bx=mass[i].price;

                        coef=(ax-bx)/(a-b);

                        price=close[1];

                        deviation=(ax+coef*bx)-price;

                        cross_bc=0;
                        cross_ab=0;


                        if(MathAbs(deviation)<tolerance*_Point)
                          {
                           //number of crossings from point a to point b
                           for(int n=a; n>b; n--)
                              if(close[n]>(ax+coef*(b-n)) && close[n]<=(ax+coef*(b-n+1)))
                                 cross_ab++;
                           //number of crossings from point b to the end
                           for(int n=b-1; n>=0; n--)
                              if(close[n]>(bx+coef*(b-n)) && close[n+1]<(bx+coef*(b-n+1)))
                                 cross_bc++;

                           if(cross_bc<=Intersection_bc && cross_bc<=Intersection_ab)
                             {

                              ArrayResize(DownTrend,y+1);
                              DownTrend[y].a=a;
                              DownTrend[y].b=b;
                              DownTrend[y].ax=ax;
                              DownTrend[y].bx=bx;
                              DownTrend[y].dst=MathAbs(deviation);
                              DownTrend[y].coef=coef;

                              y++;

                             }
                          }
                       }
                 }
           }
     }

   for(j=0; j<y; j++)
     {

      a=DownTrend[j].a;
      b=DownTrend[j].b;
      ax=DownTrend[j].ax;
      bx=DownTrend[j].bx;
      coef=DownTrend[j].coef;


      if(a>0 && b>0 && MathAbs(a-b)>0)
        {
         //--- create a trend line 
         TrendCreate(0,"DownTrend "+string(j),0,time[a],ax,time[b],bx,DColor,DStyle,DWidth,DBack,DSelection,DRayLeft,DRayRight,DHidden,DZOrder);
         ChartRedraw();
        }
     }

//+------------------------------------------------------------------+    
   y=0;



   for(j=z-1; j>=0; j--)
     {
      if(mass[j].lpoint)
         for(i=j-1; i>=0; i--)
           {
            if(mass[i].lpoint)
               if(i<j)
                 {

                  a=mass[j].pos;
                  b=mass[i].pos;

                  double ratio=double((a-b)*100/a);

                  if(ratio>fibo && ratio<(100-fibo))
                     if(b>Min_dist && (a-b)>Min_dist)
                       {

                        ax=mass[j].price;
                        bx=mass[i].price;

                        coef=(ax-bx)/(a-b);

                        price=close[1];

                        deviation=(ax+coef*bx)-price;

                        cross_bc=0;
                        cross_ab=0;


                        if(MathAbs(deviation)<tolerance*_Point)
                          {

                           //number of crossings from point a to point b
                           for(int n=a; n>b; n--)
                              if(close[n]>(ax+coef*(b-n)) && close[n]<=(ax+coef*(b-n+1)))
                                 cross_ab++;
                           //number of crossings from point b to the end
                           for(int n=b-1; n>=0; n--)
                              if(close[n]>(bx+coef*(b-n)) && close[n+1]<=(bx+coef*(b-n+1)))
                                 cross_bc++;

                           if(cross_bc<=Intersection_bc && cross_bc<=Intersection_ab)
                             {

                              ArrayResize(UpTrend,y+1);
                              UpTrend[y].a=a;
                              UpTrend[y].b=b;
                              UpTrend[y].ax=ax;
                              UpTrend[y].bx=bx;
                              UpTrend[y].dst=MathAbs(deviation);
                              UpTrend[y].coef=coef;

                              y++;

                             }
                          }
                       }
                 }
           }
     }

   for(j=0; j<y; j++)
     {

      a=UpTrend[j].a;
      b=UpTrend[j].b;
      ax=UpTrend[j].ax;
      bx=UpTrend[j].bx;
      coef=UpTrend[j].coef;


      if(a>0 && b>0 && MathAbs(a-b)>0)
        {
         //--- create a trend line 
         TrendCreate(0,"UpTrend "+string(j),0,time[a],ax,time[b],bx,UColor,UStyle,UWidth,UBack,USelection,URayLeft,URayRight,UHidden,UZOrder);
         ChartRedraw();
        }
     }


//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+ 
//| Create a trend line by the given coordinates                     | 
//+------------------------------------------------------------------+ 
bool TrendCreate(const long            chart_ID=0,        // chart ID 
                 const string          name="TrendLine",  // line name 
                 const int             sub_window=0,      // subwindow index 
                 datetime              time1=0,           // first point time 
                 double                price1=0,          // first point price 
                 datetime              time2=0,           // second point time 
                 double                price2=0,          // second point price 
                 const color           clr=clrRed,        // line color 
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style 
                 const int             width=1,           // line width 
                 const bool            back=false,        // in the background 
                 const bool            selection=true,    // allocate for moving 
                 const bool            ray_left=false,    // line continuation to the left 
                 const bool            ray_right=false,   // line continuation to the right 
                 const bool            hidden=true,       // hidden in the list of objects 
                 const long            z_order=0)         // priority for mouse click 
  {

   ObjectDelete(chart_ID,name);

//--- create a trend line by the given coordinates 
   if(!ObjectCreate(chart_ID,name,OBJ_TREND,sub_window,time1,price1,time2,price2))
     {
      Print(__FUNCTION__,
            ": failed to create a trend line! Error code = ",GetLastError());
      return(false);
     }
//--- set the line color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set the line width 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the line with a mouse 
//--- when creating a graphical object using ObjectCreate function, the object cannot be 
//--- highlighted and moved by default. Selection parameter inside this method 
//--- is true by default making it possible to highlight and move the object 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- enable (true) or disable (false) the mode of continuation of the line's display to the left 
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_LEFT,ray_left);
//--- enable (true) or disable (false) the mode of continuation of the line's display to the right 
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_RIGHT,ray_right);
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click on the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Function for deleting trend lines                                | 
//+------------------------------------------------------------------+   

void DelObs(string pref)
  {
   int n=ObjectsTotal(0,-1,-1);
   for(int i=n; i>=0; i--)
     {
      string sName=ObjectName(0,i,-1,-1);
      if(StringFind(sName,pref)!=-1)
        {
         ObjectDelete(0,sName);
        }
     }}
//+------------------------------------------------------------------+
