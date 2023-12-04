//+------------------------------------------------------------------
//|                                         Trend Quality Q indicator
//|                                                            mladen 
//|                                    
//| as Published in TASC 22:04 article
//| Trend Quality indicator" by David Sepiashvili
//+------------------------------------------------------------------
#property copyright "www.forex-tsd.com"
#property link      "www.forex-tsd.com"

#property indicator_separate_window
#property indicator_buffers    4
#property indicator_color1     DeepSkyBlue
#property indicator_color2     PaleVioletRed
#property indicator_color3     DimGray
#property indicator_color4     HotPink
#property indicator_width1     2
#property indicator_width2     2
#property indicator_width3     2
#property indicator_width4     2
#property indicator_levelcolor DimGray

//
//
//
//
//

extern int    TrendPeriod             =   4;
extern int    NoisePeriod             = 250;
extern double CorrectionFactor        =   2;
extern int    FastLength              =   7;
extern int    SlowLength              =  15;
extern int    Price                   = PRICE_CLOSE;
extern double LevelBoundBeneathNoise  =   1;
extern double LevelBoundWeakTrend     =   2;
extern double LevelBoundModerateTrend =   5;

//
//
//
//
//

double trendQu[];
double trendQd[];
double trendQ[];
double trendQSign[];


//+------------------------------------------------------------------
//|                                                                  
//+------------------------------------------------------------------
//
//
//
//
//

int init()
{
   SetIndexBuffer(0,trendQu); SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexBuffer(1,trendQd); SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexBuffer(2,trendQ);
   SetIndexBuffer(3,trendQSign);
   
      //
      //
      //
      //
      //
      
      SetLevelValue(0,0);
      SetLevelValue(1, LevelBoundBeneathNoise);
      SetLevelValue(2,-LevelBoundBeneathNoise);
      SetLevelValue(3, LevelBoundWeakTrend);
      SetLevelValue(4,-LevelBoundWeakTrend);
      SetLevelValue(5, LevelBoundModerateTrend);
      SetLevelValue(6,-LevelBoundModerateTrend);
      IndicatorShortName("Trend quality Q1 ("+TrendPeriod+","+NoisePeriod+","+DoubleToStr(CorrectionFactor,2)+","+FastLength+","+SlowLength+")");
   return(0);
}
int deinit() { return(0); }


//+------------------------------------------------------------------
//|                                                                  
//+------------------------------------------------------------------
//
//
//
//
//
// initialize work array

double work[][7];
#define _price  0
#define _emaf   1
#define _emas   2
#define _sign   3
#define _cpc    4
#define _trend  5
#define _dt     6


int start()
{
   int i,k,r,limit,counted_bars=IndicatorCounted();

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
         limit = Bars-counted_bars;
         if (ArrayRange(work,0) != Bars) ArrayResize(work,Bars);

   double alpha1 = 2.0 / (1.0+FastLength);
   double alpha2 = 2.0 / (1.0+SlowLength);

  // main for loop, caculate the trend quality value for each price bar

   for(i=limit, r=Bars-limit-1; i>=0; i--,r++)
   {
    // macd calculation and directional component
      work[r][_price] = iMA(NULL,0,1,0,MODE_SMA,Price,i);
      work[r][_emaf]  = work[r-1][_emaf]+alpha1*(work[r][_price]-work[r-1][_emaf]);
      work[r][_emas]  = work[r-1][_emas]+alpha2*(work[r][_price]-work[r-1][_emas]);
         double macd  = work[r][_emaf]-work[r][_emas];
                        work[r][_sign] = work[r-1][_sign];
                           if (macd>0) work[r][_sign] =  1;
                           if (macd<0) work[r][_sign] = -1;
                        trendQSign[i] = work[r][_sign];
        // get absolute value of the price change
         double change = MathAbs(work[r][_price]-work[r-1][_price]);
         // if previous price sign is different from current price sign, reset the cpc and trend value
         if (work[r][_sign] != work[r-1][_sign])
            {
               work[r][_cpc]   = 0;
               work[r][_trend] = 0;
            }
         else
            {
               work[r][_cpc]   = work[r][_sign]*change+work[r-1][_cpc];
               work[r][_trend] = work[r][_cpc]*(1.0/TrendPeriod)+work[r-1][_trend]*(1.0-(1.0/TrendPeriod));
            }
         work[r][_dt] = (work[r][_cpc]-work[r][_trend])*(work[r][_cpc]-work[r][_trend]);
         

         // avgDt, noise calculation
         double avgDt = 0; for (k=0; k<NoisePeriod; k++) avgDt += work[r-k][_dt]; avgDt /= NoisePeriod;
         double noise = CorrectionFactor*MathSqrt(avgDt);
           if (noise != 0)
                  trendQ[i] = work[r][_trend]/noise;
            else  trendQ[i] = 0;
                  trendQu[i] = EMPTY_VALUE;
                  trendQd[i] = EMPTY_VALUE;
                     if (trendQ[i]>0)  trendQu[i] = trendQ[i];
                     if (trendQ[i]<0)  trendQd[i] = trendQ[i];
   }      
   return(0);
}