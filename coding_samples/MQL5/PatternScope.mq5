//+------------------------------------------------------------------+
//|                                                 PatternScope.mq5 |
//|                                  Classic Chart Pattern Scanner   |
//|                          Reversal / Continuation / Candlestick   |
//|                                                                  |
//|  Public portfolio sample. No credentials or proprietary data.    |
//|  Source encoding: UTF-8 (no BOM).                                |
//|  If JP characters appear garbled in MetaEditor, re-save as       |
//|  UTF-8 with BOM (File > Save As ... > Encoding).                 |
//+------------------------------------------------------------------+
#property copyright   "PatternScope"
#property link        ""
#property version     "1.10"
#property description "Classic chart & candlestick pattern scanner."
#property description "Highlights formations and shows an MTF dashboard."
#property description "Bilingual UI (Japanese / English) via Language input."
#property strict
#property indicator_chart_window
#property indicator_plots 0

//==================================================================
// LANGUAGE ENUM
//==================================================================
enum ENUM_PS_LANG
  {
   LANG_JA = 0,   // 日本語
   LANG_EN = 1    // English
  };

//==================================================================
// INPUTS
//==================================================================
input group "=== Language / 表示言語 ==="
input ENUM_PS_LANG InpLanguage = LANG_JA;   // UI language (JP / EN)

input group "=== Pivot / Swing Detection ==="
input int    InpPivotLeft        = 5;        // Bars left of pivot
input int    InpPivotRight       = 5;        // Bars right of pivot
input int    InpScanBars         = 800;      // Bars to scan
input int    InpMaxPivots        = 60;       // Max swing points kept

input group "=== Tolerance ==="
input double InpEqualTolPct      = 0.20;     // Equal-price tolerance (%)
input double InpSlopeFlatPct     = 0.05;     // Slope considered flat (%/bar)
input int    InpMinPatternBars   = 8;        // Minimum pattern width (bars)

input group "=== Reversal Patterns ==="
input bool   InpDoubleTop        = true;
input bool   InpDoubleBottom     = true;
input bool   InpTripleTop        = true;
input bool   InpTripleBottom     = true;
input bool   InpHeadShoulders    = true;
input bool   InpInverseHS        = true;
input bool   InpRoundingTop      = true;
input bool   InpRoundingBottom   = true;
input bool   InpVTop             = true;
input bool   InpVBottom          = true;
input bool   InpDiamondTop       = true;
input bool   InpDiamondBottom    = true;
input bool   InpBroadeningTop    = true;
input bool   InpBroadeningBottom = true;

input group "=== Continuation Patterns ==="
input bool   InpBullFlag         = true;
input bool   InpBearFlag         = true;
input bool   InpBullPennant      = true;
input bool   InpBearPennant      = true;
input bool   InpRectangle        = true;
input bool   InpAscTriangle      = true;
input bool   InpDescTriangle     = true;
input bool   InpSymTriangle      = true;
input bool   InpRisingWedge      = true;
input bool   InpFallingWedge     = true;
input bool   InpCupHandle        = true;
input bool   InpInvCupHandle     = true;

input group "=== Candlestick Patterns ==="
input bool   InpEngulfing        = true;
input bool   InpHammer           = true;
input bool   InpShootingStar     = true;
input bool   InpDoji             = true;
input bool   InpMorningStar      = true;
input bool   InpEveningStar      = true;
input bool   InpThreeSoldiers    = true;
input bool   InpThreeCrows       = true;
input bool   InpTweezer          = true;
input bool   InpPiercing         = true;
input bool   InpDarkCloud        = true;

input group "=== Visual ==="
input color  InpBullColor        = clrDodgerBlue;
input color  InpBearColor        = clrCrimson;
input color  InpNeutralColor     = clrGoldenrod;
input int    InpLineWidth        = 2;
input bool   InpFillBox          = false;
input int    InpLabelFontSize    = 9;
input string InpLabelFont        = "Arial Bold";

input group "=== Multi-Timeframe Dashboard ==="
input bool             InpShowDashboard = true;
input ENUM_TIMEFRAMES  InpTF1 = PERIOD_M5;
input ENUM_TIMEFRAMES  InpTF2 = PERIOD_M15;
input ENUM_TIMEFRAMES  InpTF3 = PERIOD_H1;
input ENUM_TIMEFRAMES  InpTF4 = PERIOD_H4;
input ENUM_TIMEFRAMES  InpTF5 = PERIOD_D1;
input int              InpDashX        = 12;
input int              InpDashY        = 24;
input color            InpDashBgColor  = C'18,18,24';
input color            InpDashHeader   = clrGold;
input color            InpDashText     = clrWhiteSmoke;
input int              InpDashFontSize = 8;

input group "=== Alerts ==="
input bool   InpAlertPopup       = true;
input bool   InpAlertSound       = false;
input bool   InpAlertPush        = false;
input string InpAlertSoundFile   = "alert.wav";

//==================================================================
// CONSTANTS
//==================================================================
#define PS_PREFIX  "PSC_"
#define PS_DASH    "PSD_"
#define MAX_PATTERNS 32

// Pattern catalog — internal English IDs (used as map keys).
// Display text is resolved at render time via LocalizedPatternName().
const string g_patternNames[] = {
   "Double Top","Double Bottom","Triple Top","Triple Bottom",
   "Head&Shoulders","Inverse H&S","Rounding Top","Rounding Bottom",
   "V-Top","V-Bottom","Diamond Top","Diamond Bottom",
   "Broadening Top","Broadening Bottom",
   "Bull Flag","Bear Flag","Bull Pennant","Bear Pennant",
   "Rectangle","Asc Triangle","Desc Triangle","Sym Triangle",
   "Rising Wedge","Falling Wedge","Cup&Handle","Inv Cup&Handle",
   "Engulfing","Hammer","Shooting Star","Doji",
   "Morning Star","Evening Star"
};

//==================================================================
// LOCALIZATION
//==================================================================
string Tr(string ja, string en)
  {
   return (InpLanguage == LANG_JA) ? ja : en;
  }

string LocalizedPatternName(string id)
  {
   if(InpLanguage == LANG_EN) return id;
   if(id == "Double Top")        return "ダブルトップ";
   if(id == "Double Bottom")     return "ダブルボトム";
   if(id == "Triple Top")        return "トリプルトップ";
   if(id == "Triple Bottom")     return "トリプルボトム";
   if(id == "Head&Shoulders")    return "ヘッド&ショルダー";
   if(id == "Inverse H&S")       return "逆ヘッド&ショルダー";
   if(id == "Rounding Top")      return "ラウンディングトップ";
   if(id == "Rounding Bottom")   return "ラウンディングボトム";
   if(id == "V-Top")             return "V字トップ";
   if(id == "V-Bottom")          return "V字ボトム";
   if(id == "Diamond Top")       return "ダイヤモンドトップ";
   if(id == "Diamond Bottom")    return "ダイヤモンドボトム";
   if(id == "Broadening Top")    return "ブロードニングトップ";
   if(id == "Broadening Bottom") return "ブロードニングボトム";
   if(id == "Bull Flag")         return "上昇フラッグ";
   if(id == "Bear Flag")         return "下降フラッグ";
   if(id == "Bull Pennant")      return "上昇ペナント";
   if(id == "Bear Pennant")      return "下降ペナント";
   if(id == "Rectangle")         return "レクタングル";
   if(id == "Asc Triangle")      return "上昇トライアングル";
   if(id == "Desc Triangle")     return "下降トライアングル";
   if(id == "Sym Triangle")      return "対称トライアングル";
   if(id == "Rising Wedge")      return "ライジングウェッジ";
   if(id == "Falling Wedge")     return "フォーリングウェッジ";
   if(id == "Cup&Handle")        return "カップ&ハンドル";
   if(id == "Inv Cup&Handle")    return "逆カップ&ハンドル";
   if(id == "Engulfing")         return "包み線";
   if(id == "Hammer")            return "ハンマー";
   if(id == "Shooting Star")     return "シューティングスター";
   if(id == "Doji")              return "ドージ(同事)";
   if(id == "Morning Star")      return "明けの明星";
   if(id == "Evening Star")      return "宵の明星";
   if(id == "Three Soldiers")    return "赤三兵";
   if(id == "Three Crows")       return "三羽烏";
   if(id == "Tweezer Top")       return "毛抜きトップ";
   if(id == "Tweezer Bottom")    return "毛抜きボトム";
   if(id == "Piercing Line")     return "切り込み線";
   if(id == "Dark Cloud Cover")  return "かぶせ線";
   return id;
  }

string DirectionLabel(bool bullish)
  {
   if(InpLanguage == LANG_JA) return bullish ? "買い" : "売り";
   return bullish ? "BUY" : "SELL";
  }

//==================================================================
// STRUCTURES
//==================================================================
struct Pivot
  {
   int       idx;       // shift from current bar (0 = newest)
   datetime  time;
   double    price;
   bool      isHigh;
  };

struct PatternRecord
  {
   string   name;
   datetime t1;
   datetime t2;
   double   p1;
   double   p2;
   color    clr;
   bool     bullish;
   int      tfMinutes;  // 0 = current chart
  };

// Dashboard scan result per TF
struct TFStatus
  {
   ENUM_TIMEFRAMES tf;
   bool   active[MAX_PATTERNS];
   bool   bullish[MAX_PATTERNS];
  };

//==================================================================
// GLOBALS
//==================================================================
Pivot         g_pivots[];
PatternRecord g_records[];
int           g_recordCount = 0;
datetime      g_lastBarTime = 0;
TFStatus      g_tfStatus[5];
int           g_tfCount = 0;
string        g_lastAlertTag = "";
datetime      g_lastAlertTime = 0;

//==================================================================
// INIT / DEINIT
//==================================================================
int OnInit()
  {
   IndicatorSetString(INDICATOR_SHORTNAME,"PatternScope");
   ArrayResize(g_pivots,0);
   ArrayResize(g_records,0);
   g_recordCount = 0;
   g_lastBarTime = 0;
   ConfigureTFList();
   if(InpShowDashboard) BuildDashboardSkeleton();
   ChartRedraw();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,PS_PREFIX);
   ObjectsDeleteAll(0,PS_DASH);
   ChartRedraw();
  }

void ConfigureTFList()
  {
   ENUM_TIMEFRAMES tfs[5] = {InpTF1,InpTF2,InpTF3,InpTF4,InpTF5};
   g_tfCount = 0;
   for(int i=0;i<5;i++)
     {
      if(tfs[i]==PERIOD_CURRENT) continue;
      g_tfStatus[g_tfCount].tf = tfs[i];
      for(int j=0;j<MAX_PATTERNS;j++)
        {
         g_tfStatus[g_tfCount].active[j]  = false;
         g_tfStatus[g_tfCount].bullish[j] = false;
        }
      g_tfCount++;
     }
  }

//==================================================================
// MAIN LOOP
//==================================================================
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
   if(rates_total < InpScanBars + InpPivotLeft + InpPivotRight + 10)
      return(rates_total);

   // Only refresh on new bar to keep things fast
   datetime newest = time[rates_total-1];
   if(newest == g_lastBarTime && prev_calculated > 0)
      return(rates_total);
   g_lastBarTime = newest;

   // Clear previous drawings/records
   ObjectsDeleteAll(0,PS_PREFIX);
   ArrayResize(g_records,0);
   g_recordCount = 0;

   // === Scan current chart timeframe ===
   ScanTimeframe(_Symbol, PERIOD_CURRENT, true);

   // === MTF scan for dashboard ===
   if(InpShowDashboard)
     {
      for(int i=0;i<g_tfCount;i++)
         ScanTimeframe(_Symbol, g_tfStatus[i].tf, false, i);
      UpdateDashboard();
     }

   ChartRedraw();
   return(rates_total);
  }

//==================================================================
// TIMEFRAME SCANNER
//==================================================================
void ScanTimeframe(string symbol, ENUM_TIMEFRAMES tf, bool draw, int tfSlot=-1)
  {
   int bars = (int)MathMin(InpScanBars, Bars(symbol,tf));
   if(bars < InpPivotLeft + InpPivotRight + InpMinPatternBars + 5) return;

   MqlRates rates[];
   if(CopyRates(symbol, tf, 0, bars, rates) <= 0) return;

   // Detect pivots from this rate array
   Pivot pivots[];
   DetectPivots(rates, pivots);
   if(ArraySize(pivots) < 3) return;

   // Reset TF status slot
   if(tfSlot >= 0)
      for(int p=0;p<MAX_PATTERNS;p++)
        {
         g_tfStatus[tfSlot].active[p] = false;
         g_tfStatus[tfSlot].bullish[p] = false;
        }

   // Run pattern detectors
   //   Reversal
   if(InpDoubleTop)        DetectDoubleTop       (rates, pivots, draw, tfSlot);
   if(InpDoubleBottom)     DetectDoubleBottom    (rates, pivots, draw, tfSlot);
   if(InpTripleTop)        DetectTripleTop       (rates, pivots, draw, tfSlot);
   if(InpTripleBottom)     DetectTripleBottom    (rates, pivots, draw, tfSlot);
   if(InpHeadShoulders)    DetectHeadShoulders   (rates, pivots, draw, tfSlot);
   if(InpInverseHS)        DetectInverseHS       (rates, pivots, draw, tfSlot);
   if(InpRoundingTop)      DetectRoundingTop     (rates, pivots, draw, tfSlot);
   if(InpRoundingBottom)   DetectRoundingBottom  (rates, pivots, draw, tfSlot);
   if(InpVTop)             DetectVTop            (rates, pivots, draw, tfSlot);
   if(InpVBottom)          DetectVBottom         (rates, pivots, draw, tfSlot);
   if(InpDiamondTop)       DetectDiamondTop      (rates, pivots, draw, tfSlot);
   if(InpDiamondBottom)    DetectDiamondBottom   (rates, pivots, draw, tfSlot);
   if(InpBroadeningTop)    DetectBroadeningTop   (rates, pivots, draw, tfSlot);
   if(InpBroadeningBottom) DetectBroadeningBottom(rates, pivots, draw, tfSlot);
   //   Continuation
   if(InpBullFlag)         DetectBullFlag        (rates, pivots, draw, tfSlot);
   if(InpBearFlag)         DetectBearFlag        (rates, pivots, draw, tfSlot);
   if(InpBullPennant)      DetectBullPennant     (rates, pivots, draw, tfSlot);
   if(InpBearPennant)      DetectBearPennant     (rates, pivots, draw, tfSlot);
   if(InpRectangle)        DetectRectangle       (rates, pivots, draw, tfSlot);
   if(InpAscTriangle)      DetectAscendingTri    (rates, pivots, draw, tfSlot);
   if(InpDescTriangle)     DetectDescendingTri   (rates, pivots, draw, tfSlot);
   if(InpSymTriangle)      DetectSymmetricalTri  (rates, pivots, draw, tfSlot);
   if(InpRisingWedge)      DetectRisingWedge     (rates, pivots, draw, tfSlot);
   if(InpFallingWedge)     DetectFallingWedge    (rates, pivots, draw, tfSlot);
   if(InpCupHandle)        DetectCupHandle       (rates, pivots, draw, tfSlot);
   if(InpInvCupHandle)     DetectInverseCupHandle(rates, pivots, draw, tfSlot);
   //   Candlestick (only last few bars)
   DetectCandlestickPatterns(rates, draw, tfSlot);
  }

//==================================================================
// PIVOT DETECTION
//==================================================================
void DetectPivots(const MqlRates &rates[], Pivot &out[])
  {
   int n = ArraySize(rates);
   int L = InpPivotLeft, R = InpPivotRight;
   ArrayResize(out,0);

   for(int i = L; i <= n - R - 1; i++)
     {
      double h = rates[i].high;
      double l = rates[i].low;
      bool isHigh = true, isLow = true;
      for(int k=1; k<=L && (isHigh||isLow); k++)
        {
         if(rates[i-k].high >= h) isHigh = false;
         if(rates[i-k].low  <= l) isLow  = false;
        }
      for(int k=1; k<=R && (isHigh||isLow); k++)
        {
         if(rates[i+k].high >= h) isHigh = false;
         if(rates[i+k].low  <= l) isLow  = false;
        }
      if(isHigh)
        {
         Pivot p;
         p.idx = i; p.time = rates[i].time;
         p.price = h; p.isHigh = true;
         AppendPivot(out, p);
        }
      if(isLow)
        {
         Pivot p;
         p.idx = i; p.time = rates[i].time;
         p.price = l; p.isHigh = false;
         AppendPivot(out, p);
        }
     }
   // Sort by time ascending (already in order due to scan direction)
   // Trim to last InpMaxPivots
   int sz = ArraySize(out);
   if(sz > InpMaxPivots)
     {
      Pivot trimmed[];
      ArrayResize(trimmed, InpMaxPivots);
      for(int i=0;i<InpMaxPivots;i++)
         trimmed[i] = out[sz - InpMaxPivots + i];
      ArrayResize(out, InpMaxPivots);
      for(int i=0;i<InpMaxPivots;i++) out[i] = trimmed[i];
     }
  }

void AppendPivot(Pivot &arr[], Pivot &p)
  {
   int sz = ArraySize(arr);
   ArrayResize(arr, sz+1);
   arr[sz] = p;
  }

//==================================================================
// UTILITY HELPERS
//==================================================================
bool Equalish(double a, double b)
  {
   double base = (MathAbs(a)+MathAbs(b))*0.5;
   if(base <= 0.0) return false;
   return (MathAbs(a-b)/base * 100.0) <= InpEqualTolPct;
  }

double Slope(double y1, double y2, int barsBetween)
  {
   if(barsBetween <= 0) return 0.0;
   return (y2 - y1) / (double)barsBetween;
  }

double SlopePct(double y1, double y2, int barsBetween)
  {
   if(y1 <= 0 || barsBetween <= 0) return 0.0;
   return ((y2 - y1) / y1) / (double)barsBetween * 100.0;
  }

bool IsFlat(double y1, double y2, int barsBetween)
  {
   return MathAbs(SlopePct(y1,y2,barsBetween)) <= InpSlopeFlatPct;
  }

// Find next high pivot after index i in pivot array
int NextHigh(const Pivot &pv[], int i)
  {
   int n = ArraySize(pv);
   for(int k=i+1;k<n;k++) if(pv[k].isHigh) return k;
   return -1;
  }
int NextLow(const Pivot &pv[], int i)
  {
   int n = ArraySize(pv);
   for(int k=i+1;k<n;k++) if(!pv[k].isHigh) return k;
   return -1;
  }

// Slope of best-fit through high/low pivots in range
double LineSlope(const Pivot &pv[], int from, int to, bool useHighs)
  {
   double sx=0,sy=0,sxx=0,sxy=0; int n=0;
   for(int i=from;i<=to;i++)
     {
      if(pv[i].isHigh != useHighs) continue;
      double x = (double)pv[i].idx;
      double y = pv[i].price;
      sx+=x; sy+=y; sxx+=x*x; sxy+=x*y; n++;
     }
   if(n<2) return 0.0;
   double denom = n*sxx - sx*sx;
   if(denom==0) return 0.0;
   return (n*sxy - sx*sy)/denom;
  }

//==================================================================
// PATTERN RECORD + DRAWING
//==================================================================
void Register(string name, datetime t1, datetime t2, double p1, double p2,
              color clr, bool bullish, int tfSlot)
  {
   if(tfSlot >= 0)
     {
      int idx = PatternIndexByName(name);
      if(idx >= 0)
        {
         g_tfStatus[tfSlot].active[idx]  = true;
         g_tfStatus[tfSlot].bullish[idx] = bullish;
        }
      return; // MTF-only registration; no drawing
     }
   PatternRecord rec;
   rec.name = name; rec.t1 = t1; rec.t2 = t2;
   rec.p1 = p1; rec.p2 = p2; rec.clr = clr; rec.bullish = bullish;
   rec.tfMinutes = 0;
   int sz = ArraySize(g_records);
   ArrayResize(g_records, sz+1);
   g_records[sz] = rec;
   g_recordCount++;
  }

int PatternIndexByName(string name)
  {
   int n = ArraySize(g_patternNames);
   for(int i=0;i<n;i++) if(g_patternNames[i]==name) return i;
   return -1;
  }

void DrawBox(string tag, datetime t1, double p1, datetime t2, double p2, color clr)
  {
   string name = PS_PREFIX + "BOX_" + tag;
   if(ObjectFind(0,name) < 0)
      ObjectCreate(0,name,OBJ_RECTANGLE,0,t1,p1,t2,p2);
   ObjectSetInteger(0,name,OBJPROP_TIME,0,t1);
   ObjectSetDouble (0,name,OBJPROP_PRICE,0,p1);
   ObjectSetInteger(0,name,OBJPROP_TIME,1,t2);
   ObjectSetDouble (0,name,OBJPROP_PRICE,1,p2);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,InpLineWidth);
   ObjectSetInteger(0,name,OBJPROP_FILL, InpFillBox);
   ObjectSetInteger(0,name,OBJPROP_BACK, InpFillBox);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
  }

void DrawTrend(string tag, datetime t1, double p1, datetime t2, double p2,
               color clr, ENUM_LINE_STYLE style=STYLE_SOLID, bool ray=false)
  {
   string name = PS_PREFIX + "LINE_" + tag;
   if(ObjectFind(0,name) < 0)
      ObjectCreate(0,name,OBJ_TREND,0,t1,p1,t2,p2);
   ObjectSetInteger(0,name,OBJPROP_TIME,0,t1);
   ObjectSetDouble (0,name,OBJPROP_PRICE,0,p1);
   ObjectSetInteger(0,name,OBJPROP_TIME,1,t2);
   ObjectSetDouble (0,name,OBJPROP_PRICE,1,p2);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,InpLineWidth);
   ObjectSetInteger(0,name,OBJPROP_STYLE,style);
   ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT, ray);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
  }

void DrawLabel(string tag, datetime t, double price, string text, color clr, bool above)
  {
   string name = PS_PREFIX + "TXT_" + tag;
   if(ObjectFind(0,name) < 0)
      ObjectCreate(0,name,OBJ_TEXT,0,t,price);
   ObjectSetInteger(0,name,OBJPROP_TIME,0,t);
   ObjectSetDouble (0,name,OBJPROP_PRICE,0,price);
   ObjectSetString (0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,InpLabelFontSize);
   ObjectSetString (0,name,OBJPROP_FONT,InpLabelFont);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR, above ? ANCHOR_LOWER : ANCHOR_UPPER);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
  }

void DrawArrow(string tag, datetime t, double price, bool up, color clr)
  {
   string name = PS_PREFIX + "ARR_" + tag;
   if(ObjectFind(0,name) < 0)
      ObjectCreate(0,name,up?OBJ_ARROW_BUY:OBJ_ARROW_SELL,0,t,price);
   ObjectSetInteger(0,name,OBJPROP_TIME,0,t);
   ObjectSetDouble (0,name,OBJPROP_PRICE,0,price);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,2);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
  }

// Generic helper that draws box + label + (optional) lines for a pattern.
// `name` is the internal English ID; UI strings are localized inside.
void EmphasizeBox(string name, datetime t1, datetime t2, double pHigh, double pLow,
                  color clr, bool bullish, int tfSlot)
  {
   Register(name,t1,t2,pHigh,pLow,clr,bullish,tfSlot);
   if(tfSlot >= 0) return;
   string tag = name + "_" + (string)t1;
   StringReplace(tag," ","_");
   StringReplace(tag,"&","_");
   DrawBox(tag,t1,pHigh,t2,pLow,clr);
   DrawLabel(tag+"_lbl", t2, pHigh, LocalizedPatternName(name), clr, true);
   FireAlert(name,bullish);
  }

//==================================================================
// PATTERN DETECTORS — REVERSAL
//==================================================================

// --- Double Top: H, L, H' ; H~H', L is valley ---
void DetectDoubleTop(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   for(int i=n-1;i>=2;i--)
     {
      if(!pv[i].isHigh) continue;
      // find previous high
      int prevH = -1;
      for(int j=i-1;j>=0;j--) if(pv[j].isHigh){ prevH=j; break; }
      if(prevH<0) continue;
      // valley between them
      int valley = -1;
      for(int j=prevH+1;j<i;j++) if(!pv[j].isHigh){ valley=j; break; }
      if(valley<0) continue;
      if(!Equalish(pv[i].price, pv[prevH].price)) continue;
      // valley must be meaningfully below
      double depth = pv[i].price - pv[valley].price;
      double base  = pv[i].price;
      if(depth/base*100.0 < 0.30) continue;
      int span = pv[i].idx - pv[prevH].idx;
      if(span < InpMinPatternBars) continue;

      EmphasizeBox("Double Top", pv[prevH].time, pv[i].time,
                   MathMax(pv[i].price,pv[prevH].price), pv[valley].price,
                   InpBearColor, false, tfSlot);
      if(tfSlot<0)
        {
         string tag = "DT_neck_"+(string)pv[i].time;
         DrawTrend(tag, pv[valley].time, pv[valley].price,
                   pv[i].time, pv[valley].price, InpBearColor, STYLE_DASH, true);
        }
      return; // only most-recent
     }
  }

void DetectDoubleBottom(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   for(int i=n-1;i>=2;i--)
     {
      if(pv[i].isHigh) continue;
      int prevL = -1;
      for(int j=i-1;j>=0;j--) if(!pv[j].isHigh){ prevL=j; break; }
      if(prevL<0) continue;
      int peak = -1;
      for(int j=prevL+1;j<i;j++) if(pv[j].isHigh){ peak=j; break; }
      if(peak<0) continue;
      if(!Equalish(pv[i].price, pv[prevL].price)) continue;
      double height = pv[peak].price - pv[i].price;
      double base = pv[i].price;
      if(height/base*100.0 < 0.30) continue;
      int span = pv[i].idx - pv[prevL].idx;
      if(span < InpMinPatternBars) continue;

      EmphasizeBox("Double Bottom", pv[prevL].time, pv[i].time,
                   pv[peak].price, MathMin(pv[i].price,pv[prevL].price),
                   InpBullColor, true, tfSlot);
      if(tfSlot<0)
        {
         string tag = "DB_neck_"+(string)pv[i].time;
         DrawTrend(tag, pv[peak].time, pv[peak].price,
                   pv[i].time, pv[peak].price, InpBullColor, STYLE_DASH, true);
        }
      return;
     }
  }

void DetectTripleTop(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   for(int i=n-1;i>=4;i--)
     {
      if(!pv[i].isHigh) continue;
      int h2=-1,h1=-1;
      for(int j=i-1;j>=0;j--) if(pv[j].isHigh){ h2=j; break; }
      if(h2<0) continue;
      for(int j=h2-1;j>=0;j--) if(pv[j].isHigh){ h1=j; break; }
      if(h1<0) continue;
      if(!Equalish(pv[i].price,pv[h2].price)) continue;
      if(!Equalish(pv[h2].price,pv[h1].price)) continue;
      int v1=-1,v2=-1;
      for(int j=h1+1;j<h2;j++) if(!pv[j].isHigh){ v1=j; break; }
      for(int j=h2+1;j<i;j++) if(!pv[j].isHigh){ v2=j; break; }
      if(v1<0||v2<0) continue;
      double neck = MathMin(pv[v1].price,pv[v2].price);
      double top  = MathMax(MathMax(pv[h1].price,pv[h2].price),pv[i].price);
      EmphasizeBox("Triple Top", pv[h1].time, pv[i].time, top, neck,
                   InpBearColor, false, tfSlot);
      if(tfSlot<0)
        {
         string tag = "TT_neck_"+(string)pv[i].time;
         DrawTrend(tag, pv[v1].time, neck, pv[i].time, neck,
                   InpBearColor, STYLE_DASH, true);
        }
      return;
     }
  }

void DetectTripleBottom(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   for(int i=n-1;i>=4;i--)
     {
      if(pv[i].isHigh) continue;
      int l2=-1,l1=-1;
      for(int j=i-1;j>=0;j--) if(!pv[j].isHigh){ l2=j; break; }
      if(l2<0) continue;
      for(int j=l2-1;j>=0;j--) if(!pv[j].isHigh){ l1=j; break; }
      if(l1<0) continue;
      if(!Equalish(pv[i].price,pv[l2].price)) continue;
      if(!Equalish(pv[l2].price,pv[l1].price)) continue;
      int p1=-1,p2=-1;
      for(int j=l1+1;j<l2;j++) if(pv[j].isHigh){ p1=j; break; }
      for(int j=l2+1;j<i;j++) if(pv[j].isHigh){ p2=j; break; }
      if(p1<0||p2<0) continue;
      double neck = MathMax(pv[p1].price,pv[p2].price);
      double bot  = MathMin(MathMin(pv[l1].price,pv[l2].price),pv[i].price);
      EmphasizeBox("Triple Bottom", pv[l1].time, pv[i].time, neck, bot,
                   InpBullColor, true, tfSlot);
      if(tfSlot<0)
        {
         string tag = "TB_neck_"+(string)pv[i].time;
         DrawTrend(tag, pv[p1].time, neck, pv[i].time, neck,
                   InpBullColor, STYLE_DASH, true);
        }
      return;
     }
  }

void DetectHeadShoulders(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   for(int i=n-1;i>=4;i--)
     {
      if(!pv[i].isHigh) continue;        // right shoulder
      int head=-1, left=-1;
      for(int j=i-1;j>=0;j--) if(pv[j].isHigh){ head=j; break; }
      if(head<0) continue;
      for(int j=head-1;j>=0;j--) if(pv[j].isHigh){ left=j; break; }
      if(left<0) continue;
      if(pv[head].price <= pv[i].price)   continue;
      if(pv[head].price <= pv[left].price) continue;
      if(!Equalish(pv[left].price, pv[i].price)) continue;
      int v1=-1,v2=-1;
      for(int j=left+1;j<head;j++) if(!pv[j].isHigh){ v1=j; break; }
      for(int j=head+1;j<i;j++) if(!pv[j].isHigh){ v2=j; break; }
      if(v1<0||v2<0) continue;
      double neck = MathMin(pv[v1].price,pv[v2].price);
      EmphasizeBox("Head&Shoulders", pv[left].time, pv[i].time,
                   pv[head].price, neck, InpBearColor, false, tfSlot);
      if(tfSlot<0)
        {
         string tag = "HS_neck_"+(string)pv[i].time;
         DrawTrend(tag, pv[v1].time, pv[v1].price, pv[v2].time, pv[v2].price,
                   InpBearColor, STYLE_DASH, true);
        }
      return;
     }
  }

void DetectInverseHS(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   for(int i=n-1;i>=4;i--)
     {
      if(pv[i].isHigh) continue;
      int head=-1, left=-1;
      for(int j=i-1;j>=0;j--) if(!pv[j].isHigh){ head=j; break; }
      if(head<0) continue;
      for(int j=head-1;j>=0;j--) if(!pv[j].isHigh){ left=j; break; }
      if(left<0) continue;
      if(pv[head].price >= pv[i].price)   continue;
      if(pv[head].price >= pv[left].price) continue;
      if(!Equalish(pv[left].price, pv[i].price)) continue;
      int p1=-1,p2=-1;
      for(int j=left+1;j<head;j++) if(pv[j].isHigh){ p1=j; break; }
      for(int j=head+1;j<i;j++) if(pv[j].isHigh){ p2=j; break; }
      if(p1<0||p2<0) continue;
      double neck = MathMax(pv[p1].price,pv[p2].price);
      EmphasizeBox("Inverse H&S", pv[left].time, pv[i].time, neck,
                   pv[head].price, InpBullColor, true, tfSlot);
      if(tfSlot<0)
        {
         string tag = "IHS_neck_"+(string)pv[i].time;
         DrawTrend(tag, pv[p1].time, pv[p1].price, pv[p2].time, pv[p2].price,
                   InpBullColor, STYLE_DASH, true);
        }
      return;
     }
  }

// --- Rounding (saucer) top/bottom ---
void DetectRoundingTop(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(rates);
   int span = 40;
   if(n < span+5) return;
   int end = n-2;
   int start = end - span;
   double peak = rates[start].high; int peakIdx = start;
   for(int i=start;i<=end;i++) if(rates[i].high > peak){ peak = rates[i].high; peakIdx = i; }
   // peak should be in the middle third
   int third = span/3;
   if(peakIdx < start+third || peakIdx > end-third) return;
   // edges roughly equal & below peak
   if(!Equalish(rates[start].high, rates[end].high)) return;
   if(rates[start].high >= peak*0.999) return;
   // smoothness: count direction changes around peak should be few
   int flips = 0;
   for(int i=start+2;i<=end;i++)
     {
      double d1 = rates[i-1].high - rates[i-2].high;
      double d2 = rates[i].high   - rates[i-1].high;
      if(d1*d2 < 0) flips++;
     }
   if(flips > span/2) return;
   EmphasizeBox("Rounding Top", rates[start].time, rates[end].time,
                peak, MathMin(rates[start].low, rates[end].low),
                InpBearColor, false, tfSlot);
  }

void DetectRoundingBottom(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(rates);
   int span = 40;
   if(n < span+5) return;
   int end = n-2;
   int start = end - span;
   double trough = rates[start].low; int trIdx = start;
   for(int i=start;i<=end;i++) if(rates[i].low < trough){ trough = rates[i].low; trIdx = i; }
   int third = span/3;
   if(trIdx < start+third || trIdx > end-third) return;
   if(!Equalish(rates[start].low, rates[end].low)) return;
   if(rates[start].low <= trough*1.001) return;
   int flips=0;
   for(int i=start+2;i<=end;i++)
     {
      double d1 = rates[i-1].low - rates[i-2].low;
      double d2 = rates[i].low   - rates[i-1].low;
      if(d1*d2 < 0) flips++;
     }
   if(flips > span/2) return;
   EmphasizeBox("Rounding Bottom", rates[start].time, rates[end].time,
                MathMax(rates[start].high, rates[end].high), trough,
                InpBullColor, true, tfSlot);
  }

// --- V-Top / V-Bottom: sharp single pivot with strong opposite moves on each side ---
void DetectVTop(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   for(int i=n-2;i>=1;i--)
     {
      if(!pv[i].isHigh) continue;
      int back = MathMax(pv[i].idx - 8, 0);
      int fwd  = MathMin(pv[i].idx + 8, ArraySize(rates)-1);
      double leftLow  = rates[back].low;
      double rightLow = rates[fwd].low;
      double drop1 = (pv[i].price - leftLow)/pv[i].price*100.0;
      double drop2 = (pv[i].price - rightLow)/pv[i].price*100.0;
      if(drop1 > 1.0 && drop2 > 1.0)
        {
         EmphasizeBox("V-Top", rates[back].time, rates[fwd].time,
                      pv[i].price, MathMin(leftLow,rightLow),
                      InpBearColor, false, tfSlot);
         return;
        }
     }
  }
void DetectVBottom(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   for(int i=n-2;i>=1;i--)
     {
      if(pv[i].isHigh) continue;
      int back = MathMax(pv[i].idx - 8, 0);
      int fwd  = MathMin(pv[i].idx + 8, ArraySize(rates)-1);
      double leftHigh  = rates[back].high;
      double rightHigh = rates[fwd].high;
      double rise1 = (leftHigh  - pv[i].price)/pv[i].price*100.0;
      double rise2 = (rightHigh - pv[i].price)/pv[i].price*100.0;
      if(rise1 > 1.0 && rise2 > 1.0)
        {
         EmphasizeBox("V-Bottom", rates[back].time, rates[fwd].time,
                      MathMax(leftHigh,rightHigh), pv[i].price,
                      InpBullColor, true, tfSlot);
         return;
        }
     }
  }

// --- Diamond Top/Bottom: broadening then symmetrical contraction ---
void DetectDiamondTop(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   if(n < 7) return;
   // Look at last ~7 pivots and check broadening then contracting around a top
   int a=n-7, b=n-1;
   double hi1=-1,hi2=-1; // first/last high in range
   double lo1= 1e18, lo2=1e18;
   for(int i=a;i<=b;i++)
     {
      if(pv[i].isHigh){ if(hi1<0) hi1=pv[i].price; hi2=pv[i].price; }
      else            { if(lo1>1e17) lo1=pv[i].price; lo2=pv[i].price; }
     }
   // Middle highs/lows extremes
   double maxH=-1,minL=1e18;
   for(int i=a;i<=b;i++)
     {
      if(pv[i].isHigh && pv[i].price>maxH) maxH=pv[i].price;
      if(!pv[i].isHigh && pv[i].price<minL) minL=pv[i].price;
     }
   if(hi1<0||hi2<0||lo1>1e17||lo2>1e17||maxH<0||minL>1e17) return;
   if(!(maxH > hi1 && maxH > hi2 && minL < lo1 && minL < lo2)) return;
   EmphasizeBox("Diamond Top", pv[a].time, pv[b].time, maxH, minL,
                InpBearColor, false, tfSlot);
  }

void DetectDiamondBottom(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   if(n < 7) return;
   int a=n-7, b=n-1;
   double hi1=-1,hi2=-1, lo1=1e18,lo2=1e18, maxH=-1,minL=1e18;
   for(int i=a;i<=b;i++)
     {
      if(pv[i].isHigh){ if(hi1<0) hi1=pv[i].price; hi2=pv[i].price; if(pv[i].price>maxH) maxH=pv[i].price; }
      else            { if(lo1>1e17) lo1=pv[i].price; lo2=pv[i].price; if(pv[i].price<minL) minL=pv[i].price; }
     }
   if(hi1<0||lo1>1e17) return;
   if(!(maxH > hi1 && maxH > hi2 && minL < lo1 && minL < lo2)) return;
   EmphasizeBox("Diamond Bottom", pv[a].time, pv[b].time, maxH, minL,
                InpBullColor, true, tfSlot);
  }

// --- Broadening top/bottom (Megaphone) ---
void DetectBroadeningTop(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   if(n < 5) return;
   // need at least 3 highs ascending and 2 lows descending in last window
   int hCnt=0,lCnt=0;
   double prevH=-1, prevL=1e18;
   bool hAsc=true, lDesc=true;
   for(int i=MathMax(0,n-7);i<n;i++)
     {
      if(pv[i].isHigh)
        {
         if(prevH>0 && pv[i].price <= prevH) hAsc=false;
         prevH = pv[i].price; hCnt++;
        }
      else
        {
         if(prevL<1e17 && pv[i].price >= prevL) lDesc=false;
         prevL = pv[i].price; lCnt++;
        }
     }
   if(hCnt>=2 && lCnt>=2 && hAsc && lDesc)
     {
      int a = MathMax(0,n-7);
      EmphasizeBox("Broadening Top", pv[a].time, pv[n-1].time,
                   prevH, prevL, InpBearColor, false, tfSlot);
     }
  }

void DetectBroadeningBottom(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   // Same as broadening top, distinguishing by trend context is harder; reuse but mark bullish
   int n = ArraySize(pv);
   if(n < 5) return;
   int hCnt=0,lCnt=0;
   double prevH=-1, prevL=1e18, maxH=-1, minL=1e18;
   bool hAsc=true, lDesc=true;
   for(int i=MathMax(0,n-7);i<n;i++)
     {
      if(pv[i].isHigh)
        {
         if(prevH>0 && pv[i].price <= prevH) hAsc=false;
         prevH = pv[i].price; hCnt++;
         if(pv[i].price>maxH) maxH=pv[i].price;
        }
      else
        {
         if(prevL<1e17 && pv[i].price >= prevL) lDesc=false;
         prevL = pv[i].price; lCnt++;
         if(pv[i].price<minL) minL=pv[i].price;
        }
     }
   if(hCnt>=2 && lCnt>=2 && hAsc && lDesc)
     {
      // Context: preceding trend down → broadening bottom
      int n2 = ArraySize(rates);
      double before = rates[MathMax(0,n2-60)].close;
      double now    = rates[n2-1].close;
      if(now < before)
        {
         int a = MathMax(0,n-7);
         EmphasizeBox("Broadening Bottom", pv[a].time, pv[n-1].time,
                      maxH, minL, InpBullColor, true, tfSlot);
        }
     }
  }

//==================================================================
// PATTERN DETECTORS — CONTINUATION
//==================================================================

// --- Flags: strong pole then parallel channel against trend ---
void DetectBullFlag(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(rates);
   if(n < 30) return;
   int end = n-2;
   int flagBars = 12, poleBars = 12;
   int flagStart = end - flagBars;
   int poleStart = flagStart - poleBars;
   if(poleStart < 0) return;
   double poleLow  = rates[poleStart].low;
   double poleHigh = rates[flagStart].high;
   double poleGain = (poleHigh - poleLow)/poleLow*100.0;
   if(poleGain < 1.0) return;
   // Inside flag, slope of highs and lows should be negative & similar
   double sHi = LinearRegSlope(rates, flagStart, end, true);
   double sLo = LinearRegSlope(rates, flagStart, end, false);
   if(sHi >= 0 || sLo >= 0) return;
   if(MathAbs(sHi - sLo)/(MathAbs(sHi)+1e-9) > 0.6) return;
   EmphasizeBox("Bull Flag", rates[flagStart].time, rates[end].time,
                poleHigh, MathMin(rates[flagStart].low, rates[end].low),
                InpBullColor, true, tfSlot);
  }

void DetectBearFlag(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(rates);
   if(n < 30) return;
   int end = n-2;
   int flagBars = 12, poleBars = 12;
   int flagStart = end - flagBars;
   int poleStart = flagStart - poleBars;
   if(poleStart < 0) return;
   double poleHigh = rates[poleStart].high;
   double poleLow  = rates[flagStart].low;
   double poleDrop = (poleHigh - poleLow)/poleHigh*100.0;
   if(poleDrop < 1.0) return;
   double sHi = LinearRegSlope(rates, flagStart, end, true);
   double sLo = LinearRegSlope(rates, flagStart, end, false);
   if(sHi <= 0 || sLo <= 0) return;
   if(MathAbs(sHi - sLo)/(MathAbs(sHi)+1e-9) > 0.6) return;
   EmphasizeBox("Bear Flag", rates[flagStart].time, rates[end].time,
                MathMax(rates[flagStart].high, rates[end].high),
                poleLow, InpBearColor, false, tfSlot);
  }

double LinearRegSlope(const MqlRates &rates[], int from, int to, bool useHigh)
  {
   double sx=0,sy=0,sxx=0,sxy=0; int n=0;
   for(int i=from;i<=to;i++)
     {
      double x=(double)i, y= useHigh?rates[i].high:rates[i].low;
      sx+=x; sy+=y; sxx+=x*x; sxy+=x*y; n++;
     }
   if(n<2) return 0.0;
   double d = n*sxx - sx*sx;
   if(d==0) return 0.0;
   return (n*sxy - sx*sy)/d;
  }

// --- Pennants: pole then symmetrical triangle ---
void DetectBullPennant(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(rates);
   if(n < 30) return;
   int end = n-2;
   int pennBars = 12, poleBars = 10;
   int pStart = end - pennBars;
   int poleS  = pStart - poleBars;
   if(poleS < 0) return;
   double poleGain = (rates[pStart].high - rates[poleS].low)/rates[poleS].low*100.0;
   if(poleGain < 1.0) return;
   double sHi = LinearRegSlope(rates, pStart, end, true);
   double sLo = LinearRegSlope(rates, pStart, end, false);
   if(sHi >= 0 || sLo <= 0) return;
   EmphasizeBox("Bull Pennant", rates[pStart].time, rates[end].time,
                rates[pStart].high, rates[pStart].low,
                InpBullColor, true, tfSlot);
  }
void DetectBearPennant(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(rates);
   if(n < 30) return;
   int end = n-2;
   int pennBars = 12, poleBars = 10;
   int pStart = end - pennBars;
   int poleS  = pStart - poleBars;
   if(poleS < 0) return;
   double poleDrop = (rates[poleS].high - rates[pStart].low)/rates[poleS].high*100.0;
   if(poleDrop < 1.0) return;
   double sHi = LinearRegSlope(rates, pStart, end, true);
   double sLo = LinearRegSlope(rates, pStart, end, false);
   if(sHi >= 0 || sLo <= 0) return;
   EmphasizeBox("Bear Pennant", rates[pStart].time, rates[end].time,
                rates[pStart].high, rates[pStart].low,
                InpBearColor, false, tfSlot);
  }

// --- Rectangle: parallel horizontal support/resistance ---
void DetectRectangle(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   if(n < 4) return;
   // last 2 highs and 2 lows nearly equal
   int h2=-1,h1=-1,l2=-1,l1=-1;
   for(int i=n-1;i>=0;i--)
     {
      if(pv[i].isHigh){ if(h2<0) h2=i; else if(h1<0) h1=i; }
      else            { if(l2<0) l2=i; else if(l1<0) l1=i; }
      if(h1>=0&&h2>=0&&l1>=0&&l2>=0) break;
     }
   if(h1<0||h2<0||l1<0||l2<0) return;
   if(!Equalish(pv[h1].price,pv[h2].price)) return;
   if(!Equalish(pv[l1].price,pv[l2].price)) return;
   datetime t1 = MathMin(pv[h1].time,pv[l1].time);
   datetime t2 = MathMax(pv[h2].time,pv[l2].time);
   // Bullish if recent close near top, bearish if near bottom — neutral here
   double mid = (pv[h2].price+pv[l2].price)/2.0;
   bool bullish = rates[ArraySize(rates)-1].close > mid;
   EmphasizeBox("Rectangle", t1, t2, MathMax(pv[h1].price,pv[h2].price),
                MathMin(pv[l1].price,pv[l2].price),
                bullish?InpBullColor:InpBearColor, bullish, tfSlot);
  }

// --- Triangles ---
void DetectAscendingTri(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   if(n < 4) return;
   int h2=-1,h1=-1,l2=-1,l1=-1;
   for(int i=n-1;i>=0;i--)
     {
      if(pv[i].isHigh){ if(h2<0) h2=i; else if(h1<0) h1=i; }
      else            { if(l2<0) l2=i; else if(l1<0) l1=i; }
      if(h1>=0&&h2>=0&&l1>=0&&l2>=0) break;
     }
   if(h1<0||h2<0||l1<0||l2<0) return;
   if(!Equalish(pv[h1].price,pv[h2].price)) return;
   if(pv[l2].price <= pv[l1].price) return;
   datetime t1 = MathMin(pv[h1].time,pv[l1].time);
   datetime t2 = MathMax(pv[h2].time,pv[l2].time);
   EmphasizeBox("Asc Triangle", t1, t2, MathMax(pv[h1].price,pv[h2].price),
                MathMin(pv[l1].price,pv[l2].price),
                InpBullColor, true, tfSlot);
   if(tfSlot<0)
     {
      string tag = "AT_"+(string)pv[h2].time;
      DrawTrend("AT_top_"+tag, pv[h1].time, pv[h1].price, pv[h2].time, pv[h2].price,
                InpBullColor, STYLE_SOLID, true);
      DrawTrend("AT_bot_"+tag, pv[l1].time, pv[l1].price, pv[l2].time, pv[l2].price,
                InpBullColor, STYLE_SOLID, true);
     }
  }

void DetectDescendingTri(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   if(n < 4) return;
   int h2=-1,h1=-1,l2=-1,l1=-1;
   for(int i=n-1;i>=0;i--)
     {
      if(pv[i].isHigh){ if(h2<0) h2=i; else if(h1<0) h1=i; }
      else            { if(l2<0) l2=i; else if(l1<0) l1=i; }
      if(h1>=0&&h2>=0&&l1>=0&&l2>=0) break;
     }
   if(h1<0||h2<0||l1<0||l2<0) return;
   if(!Equalish(pv[l1].price,pv[l2].price)) return;
   if(pv[h2].price >= pv[h1].price) return;
   datetime t1 = MathMin(pv[h1].time,pv[l1].time);
   datetime t2 = MathMax(pv[h2].time,pv[l2].time);
   EmphasizeBox("Desc Triangle", t1, t2, MathMax(pv[h1].price,pv[h2].price),
                MathMin(pv[l1].price,pv[l2].price),
                InpBearColor, false, tfSlot);
   if(tfSlot<0)
     {
      string tag = "DT_"+(string)pv[h2].time;
      DrawTrend("DTT_top_"+tag, pv[h1].time, pv[h1].price, pv[h2].time, pv[h2].price,
                InpBearColor, STYLE_SOLID, true);
      DrawTrend("DTT_bot_"+tag, pv[l1].time, pv[l1].price, pv[l2].time, pv[l2].price,
                InpBearColor, STYLE_SOLID, true);
     }
  }

void DetectSymmetricalTri(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   if(n < 4) return;
   int h2=-1,h1=-1,l2=-1,l1=-1;
   for(int i=n-1;i>=0;i--)
     {
      if(pv[i].isHigh){ if(h2<0) h2=i; else if(h1<0) h1=i; }
      else            { if(l2<0) l2=i; else if(l1<0) l1=i; }
      if(h1>=0&&h2>=0&&l1>=0&&l2>=0) break;
     }
   if(h1<0||h2<0||l1<0||l2<0) return;
   if(pv[h2].price >= pv[h1].price) return;
   if(pv[l2].price <= pv[l1].price) return;
   datetime t1 = MathMin(pv[h1].time,pv[l1].time);
   datetime t2 = MathMax(pv[h2].time,pv[l2].time);
   EmphasizeBox("Sym Triangle", t1, t2, MathMax(pv[h1].price,pv[h2].price),
                MathMin(pv[l1].price,pv[l2].price),
                InpNeutralColor, true, tfSlot);
   if(tfSlot<0)
     {
      string tag = "ST_"+(string)pv[h2].time;
      DrawTrend("ST_top_"+tag, pv[h1].time, pv[h1].price, pv[h2].time, pv[h2].price,
                InpNeutralColor, STYLE_SOLID, true);
      DrawTrend("ST_bot_"+tag, pv[l1].time, pv[l1].price, pv[l2].time, pv[l2].price,
                InpNeutralColor, STYLE_SOLID, true);
     }
  }

// --- Wedges ---
void DetectRisingWedge(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   if(n < 5) return;
   int h2=-1,h1=-1,l2=-1,l1=-1;
   for(int i=n-1;i>=0;i--)
     {
      if(pv[i].isHigh){ if(h2<0) h2=i; else if(h1<0) h1=i; }
      else            { if(l2<0) l2=i; else if(l1<0) l1=i; }
      if(h1>=0&&h2>=0&&l1>=0&&l2>=0) break;
     }
   if(h1<0||h2<0||l1<0||l2<0) return;
   if(pv[h2].price <= pv[h1].price) return;
   if(pv[l2].price <= pv[l1].price) return;
   double sH = Slope(pv[h1].price,pv[h2].price,pv[h2].idx-pv[h1].idx);
   double sL = Slope(pv[l1].price,pv[l2].price,pv[l2].idx-pv[l1].idx);
   if(sL <= sH) return;
   datetime t1 = MathMin(pv[h1].time,pv[l1].time);
   datetime t2 = MathMax(pv[h2].time,pv[l2].time);
   EmphasizeBox("Rising Wedge", t1, t2, pv[h2].price, pv[l1].price,
                InpBearColor, false, tfSlot);
  }
void DetectFallingWedge(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   if(n < 5) return;
   int h2=-1,h1=-1,l2=-1,l1=-1;
   for(int i=n-1;i>=0;i--)
     {
      if(pv[i].isHigh){ if(h2<0) h2=i; else if(h1<0) h1=i; }
      else            { if(l2<0) l2=i; else if(l1<0) l1=i; }
      if(h1>=0&&h2>=0&&l1>=0&&l2>=0) break;
     }
   if(h1<0||h2<0||l1<0||l2<0) return;
   if(pv[h2].price >= pv[h1].price) return;
   if(pv[l2].price >= pv[l1].price) return;
   double sH = Slope(pv[h1].price,pv[h2].price,pv[h2].idx-pv[h1].idx);
   double sL = Slope(pv[l1].price,pv[l2].price,pv[l2].idx-pv[l1].idx);
   if(sH >= sL) return;
   datetime t1 = MathMin(pv[h1].time,pv[l1].time);
   datetime t2 = MathMax(pv[h2].time,pv[l2].time);
   EmphasizeBox("Falling Wedge", t1, t2, pv[h1].price, pv[l2].price,
                InpBullColor, true, tfSlot);
  }

// --- Cup & Handle / Inverse ---
void DetectCupHandle(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(rates);
   int span = 50;
   if(n < span+5) return;
   int end = n-2;
   int handleStart = end - 7;
   int cupEnd = handleStart;
   int cupStart = cupEnd - span + 7;
   if(cupStart < 0) return;
   double leftRim  = rates[cupStart].high;
   double rightRim = rates[cupEnd].high;
   if(!Equalish(leftRim, rightRim)) return;
   double trough = rates[cupStart].low; int trIdx = cupStart;
   for(int i=cupStart;i<=cupEnd;i++) if(rates[i].low < trough){ trough=rates[i].low; trIdx=i; }
   double depth = (leftRim - trough)/leftRim*100.0;
   if(depth < 1.0) return;
   // handle: small downward drift below rim
   double hMin=1e18, hMax=-1;
   for(int i=handleStart;i<=end;i++){ if(rates[i].low<hMin) hMin=rates[i].low; if(rates[i].high>hMax) hMax=rates[i].high; }
   if(hMax > leftRim) return;
   if(hMin < trough)  return;
   EmphasizeBox("Cup&Handle", rates[cupStart].time, rates[end].time,
                MathMax(leftRim,rightRim), trough,
                InpBullColor, true, tfSlot);
  }

void DetectInverseCupHandle(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(rates);
   int span = 50;
   if(n < span+5) return;
   int end = n-2;
   int handleStart = end - 7;
   int cupEnd = handleStart;
   int cupStart = cupEnd - span + 7;
   if(cupStart < 0) return;
   double leftRim  = rates[cupStart].low;
   double rightRim = rates[cupEnd].low;
   if(!Equalish(leftRim, rightRim)) return;
   double peak = rates[cupStart].high; int pkIdx = cupStart;
   for(int i=cupStart;i<=cupEnd;i++) if(rates[i].high > peak){ peak=rates[i].high; pkIdx=i; }
   double height = (peak - leftRim)/leftRim*100.0;
   if(height < 1.0) return;
   double hMin=1e18, hMax=-1;
   for(int i=handleStart;i<=end;i++){ if(rates[i].low<hMin) hMin=rates[i].low; if(rates[i].high>hMax) hMax=rates[i].high; }
   if(hMin < leftRim) return;
   if(hMax > peak)    return;
   EmphasizeBox("Inv Cup&Handle", rates[cupStart].time, rates[end].time,
                peak, MathMin(leftRim,rightRim),
                InpBearColor, false, tfSlot);
  }

//==================================================================
// CANDLESTICK PATTERNS (last few bars)
//==================================================================
void DetectCandlestickPatterns(const MqlRates &rates[], bool draw, int tfSlot)
  {
   int n = ArraySize(rates);
   if(n < 5) return;
   int last = n-2; // last closed bar

   // --- Engulfing ---
   if(InpEngulfing)
     {
      double o1=rates[last-1].open,c1=rates[last-1].close;
      double o2=rates[last].open,c2=rates[last].close;
      bool bullEng = (c1<o1) && (c2>o2) && (o2<=c1) && (c2>=o1);
      bool bearEng = (c1>o1) && (c2<o2) && (o2>=c1) && (c2<=o1);
      if(bullEng)
        {
         EmphasizeBox("Engulfing", rates[last-1].time, rates[last].time,
                      MathMax(rates[last-1].high,rates[last].high),
                      MathMin(rates[last-1].low,rates[last].low),
                      InpBullColor, true, tfSlot);
        }
      else if(bearEng)
        {
         EmphasizeBox("Engulfing", rates[last-1].time, rates[last].time,
                      MathMax(rates[last-1].high,rates[last].high),
                      MathMin(rates[last-1].low,rates[last].low),
                      InpBearColor, false, tfSlot);
        }
     }

   // --- Hammer ---
   if(InpHammer)
     {
      double body = MathAbs(rates[last].close - rates[last].open);
      double range = rates[last].high - rates[last].low;
      double lowerWick = MathMin(rates[last].open,rates[last].close) - rates[last].low;
      double upperWick = rates[last].high - MathMax(rates[last].open,rates[last].close);
      if(range>0 && body/range < 0.35 && lowerWick > body*2 && upperWick < body)
        {
         EmphasizeBox("Hammer", rates[last].time, rates[last].time,
                      rates[last].high, rates[last].low,
                      InpBullColor, true, tfSlot);
        }
     }

   // --- Shooting Star ---
   if(InpShootingStar)
     {
      double body = MathAbs(rates[last].close - rates[last].open);
      double range = rates[last].high - rates[last].low;
      double upperWick = rates[last].high - MathMax(rates[last].open,rates[last].close);
      double lowerWick = MathMin(rates[last].open,rates[last].close) - rates[last].low;
      if(range>0 && body/range < 0.35 && upperWick > body*2 && lowerWick < body)
        {
         EmphasizeBox("Shooting Star", rates[last].time, rates[last].time,
                      rates[last].high, rates[last].low,
                      InpBearColor, false, tfSlot);
        }
     }

   // --- Doji ---
   if(InpDoji)
     {
      double body = MathAbs(rates[last].close - rates[last].open);
      double range = rates[last].high - rates[last].low;
      if(range > 0 && body/range < 0.08)
        {
         EmphasizeBox("Doji", rates[last].time, rates[last].time,
                      rates[last].high, rates[last].low,
                      InpNeutralColor, true, tfSlot);
        }
     }

   // --- Morning / Evening Star ---
   if(n >= 5)
     {
      double o1=rates[last-2].open,c1=rates[last-2].close;
      double o2=rates[last-1].open,c2=rates[last-1].close;
      double o3=rates[last].open,  c3=rates[last].close;
      double mid = (o1+c1)/2.0;
      if(InpMorningStar && c1<o1 && MathAbs(c2-o2) < MathAbs(c1-o1)*0.4 && c3>o3 && c3>mid)
        {
         EmphasizeBox("Morning Star", rates[last-2].time, rates[last].time,
                      MathMax(rates[last-2].high,rates[last].high),
                      MathMin(rates[last-2].low,rates[last].low),
                      InpBullColor, true, tfSlot);
        }
      if(InpEveningStar && c1>o1 && MathAbs(c2-o2) < MathAbs(c1-o1)*0.4 && c3<o3 && c3<mid)
        {
         EmphasizeBox("Evening Star", rates[last-2].time, rates[last].time,
                      MathMax(rates[last-2].high,rates[last].high),
                      MathMin(rates[last-2].low,rates[last].low),
                      InpBearColor, false, tfSlot);
        }
     }

   // --- Three Soldiers / Three Crows ---
   if(n >= 5)
     {
      if(InpThreeSoldiers)
        {
         bool ok = true;
         for(int k=last-2;k<=last;k++)
            if(rates[k].close <= rates[k].open){ ok=false; break; }
         if(ok && rates[last].close > rates[last-1].close
               && rates[last-1].close > rates[last-2].close)
           {
            EmphasizeBox("Three Soldiers", rates[last-2].time, rates[last].time,
                         rates[last].high, rates[last-2].low,
                         InpBullColor, true, tfSlot);
           }
        }
      if(InpThreeCrows)
        {
         bool ok = true;
         for(int k=last-2;k<=last;k++)
            if(rates[k].close >= rates[k].open){ ok=false; break; }
         if(ok && rates[last].close < rates[last-1].close
               && rates[last-1].close < rates[last-2].close)
           {
            EmphasizeBox("Three Crows", rates[last-2].time, rates[last].time,
                         rates[last-2].high, rates[last].low,
                         InpBearColor, false, tfSlot);
           }
        }
     }

   // --- Tweezer Top/Bottom ---
   if(InpTweezer && n >= 3)
     {
      if(Equalish(rates[last].high, rates[last-1].high) &&
         rates[last-1].close > rates[last-1].open && rates[last].close < rates[last].open)
        {
         EmphasizeBox("Tweezer Top", rates[last-1].time, rates[last].time,
                      rates[last].high,
                      MathMin(rates[last-1].low,rates[last].low),
                      InpBearColor, false, tfSlot);
        }
      if(Equalish(rates[last].low, rates[last-1].low) &&
         rates[last-1].close < rates[last-1].open && rates[last].close > rates[last].open)
        {
         EmphasizeBox("Tweezer Bottom", rates[last-1].time, rates[last].time,
                      MathMax(rates[last-1].high,rates[last].high),
                      rates[last].low, InpBullColor, true, tfSlot);
        }
     }

   // --- Piercing Line ---
   if(InpPiercing && n >= 3)
     {
      double o1=rates[last-1].open,c1=rates[last-1].close;
      double o2=rates[last].open,  c2=rates[last].close;
      double mid = (o1+c1)/2.0;
      if(c1<o1 && o2<c1 && c2>mid && c2<o1)
        {
         EmphasizeBox("Piercing Line", rates[last-1].time, rates[last].time,
                      MathMax(rates[last-1].high,rates[last].high),
                      MathMin(rates[last-1].low,rates[last].low),
                      InpBullColor, true, tfSlot);
        }
     }

   // --- Dark Cloud Cover ---
   if(InpDarkCloud && n >= 3)
     {
      double o1=rates[last-1].open,c1=rates[last-1].close;
      double o2=rates[last].open,  c2=rates[last].close;
      double mid = (o1+c1)/2.0;
      if(c1>o1 && o2>c1 && c2<mid && c2>o1)
        {
         EmphasizeBox("Dark Cloud Cover", rates[last-1].time, rates[last].time,
                      MathMax(rates[last-1].high,rates[last].high),
                      MathMin(rates[last-1].low,rates[last].low),
                      InpBearColor, false, tfSlot);
        }
     }
  }

//==================================================================
// ALERT
//==================================================================
void FireAlert(string name, bool bullish)
  {
   string tag = _Symbol+"_"+name+"_"+(string)(int)Period();
   if(tag == g_lastAlertTag && TimeCurrent() - g_lastAlertTime < 60) return;
   g_lastAlertTag = tag;
   g_lastAlertTime = TimeCurrent();
   string display = LocalizedPatternName(name);
   string dir     = DirectionLabel(bullish);
   string msg = (InpLanguage == LANG_JA)
                ? StringFormat("[PatternScope] %s シグナル: %s (%s / %s)",
                               dir, display, _Symbol, TFShort(_Period))
                : StringFormat("[PatternScope] %s signal: %s (%s / %s)",
                               dir, display, _Symbol, TFShort(_Period));
   if(InpAlertPopup) Alert(msg);
   if(InpAlertSound) PlaySound(InpAlertSoundFile);
   if(InpAlertPush)  SendNotification(msg);
  }

//==================================================================
// DASHBOARD PANEL
//==================================================================
void BuildDashboardSkeleton()
  {
   string bg = PS_DASH+"BG";
   if(ObjectFind(0,bg) < 0) ObjectCreate(0,bg,OBJ_RECTANGLE_LABEL,0,0,0);
   int patN = ArraySize(g_patternNames);
   int w = 230 + 56*g_tfCount;
   int h = 26 + 14*patN + 10;
   ObjectSetInteger(0,bg,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,bg,OBJPROP_XDISTANCE,InpDashX);
   ObjectSetInteger(0,bg,OBJPROP_YDISTANCE,InpDashY);
   ObjectSetInteger(0,bg,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,bg,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,bg,OBJPROP_BGCOLOR,InpDashBgColor);
   ObjectSetInteger(0,bg,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,bg,OBJPROP_BORDER_COLOR,InpDashHeader);
   ObjectSetInteger(0,bg,OBJPROP_BACK,false);
   ObjectSetInteger(0,bg,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,bg,OBJPROP_HIDDEN,true);

   // Title
   CreateLabel(PS_DASH+"TITLE",
               Tr("PatternScope MTF パターン検出","PatternScope MTF Scanner"),
               InpDashX+10, InpDashY+6, InpDashHeader, InpDashFontSize+1);

   // Header: pattern column + TF columns
   CreateLabel(PS_DASH+"H_PATTERN", Tr("パターン","Pattern"),
               InpDashX+10, InpDashY+24, InpDashHeader, InpDashFontSize);
   for(int i=0;i<g_tfCount;i++)
     {
      CreateLabel(PS_DASH+"H_TF"+(string)i,
                  TFShort(g_tfStatus[i].tf),
                  InpDashX+230+56*i, InpDashY+24, InpDashHeader, InpDashFontSize);
     }

   // Rows
   for(int p=0;p<ArraySize(g_patternNames);p++)
     {
      CreateLabel(PS_DASH+"P"+(string)p, LocalizedPatternName(g_patternNames[p]),
                  InpDashX+10, InpDashY+40+14*p, InpDashText, InpDashFontSize);
      for(int t=0;t<g_tfCount;t++)
        {
         CreateLabel(PS_DASH+"C"+(string)p+"_"+(string)t, "-",
                     InpDashX+230+56*t, InpDashY+40+14*p,
                     InpDashText, InpDashFontSize);
        }
     }
  }

void CreateLabel(string name, string text, int x, int y, color clr, int fs)
  {
   if(ObjectFind(0,name) < 0) ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetString (0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fs);
   ObjectSetString (0,name,OBJPROP_FONT,InpLabelFont);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
  }

string TFShort(ENUM_TIMEFRAMES tf)
  {
   switch(tf)
     {
      case PERIOD_M1:  return "M1";
      case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";
      case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN";
      default:         return EnumToString(tf);
     }
  }

void UpdateDashboard()
  {
   for(int p=0;p<ArraySize(g_patternNames);p++)
     {
      for(int t=0;t<g_tfCount;t++)
        {
         string name = PS_DASH+"C"+(string)p+"_"+(string)t;
         string txt = "-";
         color  clr = InpDashText;
         if(g_tfStatus[t].active[p])
           {
            txt = DirectionLabel(g_tfStatus[t].bullish[p]);
            clr = g_tfStatus[t].bullish[p] ? InpBullColor : InpBearColor;
           }
         ObjectSetString (0,name,OBJPROP_TEXT,txt);
         ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
        }
     }
  }

//+------------------------------------------------------------------+
