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

input group "=== Tolerance / Filters ==="
input double InpEqualTolPct      = 0.20;     // Equal-price tolerance (%)
input double InpEqualTolATR      = 0.50;     // Equal-price tolerance (xATR)
input double InpSlopeFlatPct     = 0.05;     // Slope considered flat (%/bar)
input int    InpMinPatternBars   = 8;        // Minimum pattern width (bars)
input int    InpATRPeriod        = 14;       // ATR period for volatility scaling
input double InpMinPatternATR    = 1.5;      // Min pattern depth/height (xATR)
input double InpPoleMinATR       = 2.0;      // Flag/Pennant pole minimum (xATR)
input int    InpMinTouches       = 3;        // Triangle/Rectangle min touches per line
input bool   InpRequireBreak     = false;    // Require neckline break for reversals
input bool   InpRequireTrend     = true;     // Require prior trend for candlesticks

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

input group "=== Confidence Score ==="
input bool   InpShowScore        = true;     // show 0-100 score in label
input int    InpMinScore         = 60;       // minimum score to draw / alert (0-100)

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
#define MAX_PATTERNS  40
#define MAX_ALERTS    40
#define MAX_ATR_CACHE 12

// Pattern catalog — internal English IDs (used as map keys).
// Display text is resolved at render time via LocalizedPatternName().
// IMPORTANT: every ID a detector passes to EmphasizeBox() must appear
// here, otherwise the dashboard row for it is missing.
const string g_patternNames[] = {
   "Double Top","Double Bottom","Triple Top","Triple Bottom",
   "Head&Shoulders","Inverse H&S","Rounding Top","Rounding Bottom",
   "V-Top","V-Bottom","Diamond Top","Diamond Bottom",
   "Broadening Top","Broadening Bottom",
   "Bull Flag","Bear Flag","Bull Pennant","Bear Pennant",
   "Rectangle","Asc Triangle","Desc Triangle","Sym Triangle",
   "Rising Wedge","Falling Wedge","Cup&Handle","Inv Cup&Handle",
   "Engulfing","Hammer","Shooting Star","Doji",
   "Morning Star","Evening Star",
   "Three Soldiers","Three Crows",
   "Tweezer Top","Tweezer Bottom",
   "Piercing Line","Dark Cloud Cover"
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
// VOLATILITY (ATR) — cached per timeframe
//==================================================================
double FetchATR(string symbol, ENUM_TIMEFRAMES tf, int shift=1)
  {
   ENUM_TIMEFRAMES realTF = (tf == PERIOD_CURRENT) ? _Period : tf;
   int h = INVALID_HANDLE;
   for(int i=0;i<g_atrCount;i++)
      if(g_atrTF[i] == realTF) { h = g_atrHandle[i]; break; }
   if(h == INVALID_HANDLE)
     {
      h = iATR(symbol, realTF, InpATRPeriod);
      if(h == INVALID_HANDLE) return 0.0;
      if(g_atrCount < MAX_ATR_CACHE)
        {
         g_atrTF[g_atrCount]     = realTF;
         g_atrHandle[g_atrCount] = h;
         g_atrCount++;
        }
     }
   double buf[];
   if(CopyBuffer(h, 0, shift, 1, buf) <= 0) return 0.0;
   return buf[0];
  }

//==================================================================
// SAFE DATETIME MIN / MAX (MathMin/Max overloads on datetime
// silently promote to double on some MQL5 builds → precision loss)
//==================================================================
datetime DTMin(datetime a, datetime b) { return (a < b) ? a : b; }
datetime DTMax(datetime a, datetime b) { return (a > b) ? a : b; }

//==================================================================
// EQUALITY — combines % and ATR tolerance for robustness across
// low-vol and high-vol instruments
//==================================================================
bool EqualishATR(double a, double b)
  {
   double base = (MathAbs(a)+MathAbs(b))*0.5;
   if(base <= 0.0) return false;
   double pctDiff = MathAbs(a-b)/base*100.0;
   if(pctDiff <= InpEqualTolPct) return true;
   if(g_curATR > 0.0 && MathAbs(a-b) <= InpEqualTolATR * g_curATR) return true;
   return false;
  }

//==================================================================
// PRIOR TREND CONTEXT (for candlestick patterns)
//   +1 = uptrend, -1 = downtrend, 0 = ranging
//==================================================================
int PriorTrend(const MqlRates &rates[], int idx, int lookback=20)
  {
   if(idx - lookback < 0) return 0;
   double prev = rates[idx-lookback].close;
   double now  = rates[idx].close;
   double diff = now - prev;
   if(g_curATR > 0.0)
     {
      if(diff >  0.8 * g_curATR) return  1;
      if(diff < -0.8 * g_curATR) return -1;
      return 0;
     }
   if(prev <= 0) return 0;
   double pct = diff / prev * 100.0;
   if(pct >  0.3) return  1;
   if(pct < -0.3) return -1;
   return 0;
  }

//==================================================================
// LINE-TOUCH COUNTER — counts pivots within ATR tolerance of the
// line defined by two anchor points (idx1,price1) → (idx2,price2)
//==================================================================
int CountTouches(const Pivot &pv[], int idx1, double p1, int idx2, double p2,
                 bool useHighs)
  {
   int span = idx2 - idx1;
   if(span == 0) return 0;
   double slope = (p2 - p1) / (double)span;
   double tol   = (g_curATR > 0.0)
                  ? 0.5 * g_curATR
                  : MathMax(p1, p2) * InpEqualTolPct / 100.0;
   int count = 0;
   int n = ArraySize(pv);
   for(int i=0;i<n;i++)
     {
      if(pv[i].isHigh != useHighs) continue;
      double expected = p1 + slope * (double)(pv[i].idx - idx1);
      if(MathAbs(pv[i].price - expected) <= tol) count++;
     }
   return count;
  }

//==================================================================
// PER-PATTERN ALERT COOLDOWN
//==================================================================
bool ShouldAlert(string key, int cooldownSec=60)
  {
   datetime now = TimeCurrent();
   for(int i=0;i<g_alertCount;i++)
     {
      if(g_alertNames[i] == key)
        {
         if(now - g_alertTimes[i] < cooldownSec) return false;
         g_alertTimes[i] = now;
         return true;
        }
     }
   if(g_alertCount < MAX_ALERTS)
     {
      g_alertNames[g_alertCount] = key;
      g_alertTimes[g_alertCount] = now;
      g_alertCount++;
     }
   return true;
  }

//==================================================================
// TREND-BREAK CONFIRMATION — used by reversal patterns when
// InpRequireBreak is on. For a bearish reversal, last close must
// be below neckline; for a bullish reversal, above.
//==================================================================
bool BreakConfirmed(const MqlRates &rates[], double neckline, bool bullish)
  {
   if(!InpRequireBreak) return true;
   int n = ArraySize(rates);
   if(n < 2) return true;
   double c = rates[n-1].close;
   return bullish ? (c > neckline) : (c < neckline);
  }

//==================================================================
// CONFIDENCE SCORE — 0-100 combining four normalized components.
//   trendAlign: +1 trend matches expected, 0 neutral, -1 against
//   tolDiffPct: relative difference (%) of "equal" anchor points (smaller = better)
//   depthATR:   pattern depth/height in ATR multiples (larger = better)
//   touches:    line touches for triangle/rectangle/wedge (0 if N/A)
//   breakConf:  true if InpRequireBreak satisfied (gives 5pt bonus)
//==================================================================
int ComputeScore(int trendAlign, double tolDiffPct, double depthATR,
                 int touches=0, bool breakConf=false)
  {
   int trendPts = (trendAlign > 0) ? 30 : ((trendAlign == 0) ? 15 : 0);
   int tolPts   = (int)MathMax(0.0, 30.0 - MathMin(30.0, tolDiffPct * 60.0));
   int atrPts   = (int)MathMin(30.0, MathMax(0.0, depthATR * 10.0));
   int touchPts = (int)MathMin(10.0, MathMax(0.0, (touches-2)*3.5));
   int bonus    = breakConf ? 5 : 0;
   int total    = trendPts + tolPts + atrPts + touchPts + bonus;
   if(total > 100) total = 100;
   if(total < 0)   total = 0;
   return total;
  }

// Convenience: relative diff (%) of two prices, used as tolDiffPct input
double RelDiffPct(double a, double b)
  {
   double base = (MathAbs(a)+MathAbs(b))*0.5;
   if(base <= 0) return 100.0;
   return MathAbs(a-b)/base*100.0;
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
   int      score;      // confidence 0-100
  };

// Dashboard scan result per TF
struct TFStatus
  {
   ENUM_TIMEFRAMES tf;
   bool   active[MAX_PATTERNS];
   bool   bullish[MAX_PATTERNS];
   int    score[MAX_PATTERNS];
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

// Per-pattern alert cooldown
string        g_alertNames[MAX_ALERTS];
datetime      g_alertTimes[MAX_ALERTS];
int           g_alertCount = 0;

// ATR handle cache (per timeframe)
ENUM_TIMEFRAMES g_atrTF[MAX_ATR_CACHE];
int             g_atrHandle[MAX_ATR_CACHE];
int             g_atrCount = 0;

// Per-scan context (set at start of ScanTimeframe)
double          g_curATR = 0.0;
ENUM_TIMEFRAMES g_curTF  = PERIOD_CURRENT;
string          g_curSym = "";

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
         g_tfStatus[g_tfCount].score[j]   = 0;
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

   // Per-scan context for tolerance / trend helpers
   g_curSym = symbol;
   g_curTF  = tf;
   g_curATR = FetchATR(symbol, tf, 1);

   // Detect pivots from this rate array
   Pivot pivots[];
   DetectPivots(rates, pivots);
   if(ArraySize(pivots) < 3) return;

   // Reset TF status slot
   if(tfSlot >= 0)
      for(int p=0;p<MAX_PATTERNS;p++)
        {
         g_tfStatus[tfSlot].active[p]  = false;
         g_tfStatus[tfSlot].bullish[p] = false;
         g_tfStatus[tfSlot].score[p]   = 0;
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
      // If both flags survive (very tight range with strict ≤/≥),
      // prefer the side with the larger range vs neighbors. Splitting
      // the bar into both a high and a low pivot at the same idx would
      // corrupt every "next high/low after i" scan downstream.
      if(isHigh && isLow)
        {
         double rangeH = h - rates[i-1].low;
         double rangeL = rates[i-1].high - l;
         if(rangeH >= rangeL) isLow = false;
         else                 isHigh = false;
        }
      if(isHigh)
        {
         Pivot p;
         p.idx = i; p.time = rates[i].time;
         p.price = h; p.isHigh = true;
         AppendPivot(out, p);
        }
      else if(isLow)
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
// Equality check that combines % tolerance with ATR tolerance.
// All detectors call this rather than raw == — see EqualishATR().
bool Equalish(double a, double b)
  {
   return EqualishATR(a, b);
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
              color clr, bool bullish, int tfSlot, int score)
  {
   if(tfSlot >= 0)
     {
      int idx = PatternIndexByName(name);
      if(idx >= 0)
        {
         g_tfStatus[tfSlot].active[idx]  = true;
         g_tfStatus[tfSlot].bullish[idx] = bullish;
         // Keep the best score per (TF, pattern) when multiple fire
         if(score > g_tfStatus[tfSlot].score[idx])
            g_tfStatus[tfSlot].score[idx] = score;
        }
      return; // MTF-only registration; no drawing
     }
   PatternRecord rec;
   rec.name = name; rec.t1 = t1; rec.t2 = t2;
   rec.p1 = p1; rec.p2 = p2; rec.clr = clr; rec.bullish = bullish;
   rec.tfMinutes = 0; rec.score = score;
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
// `score` (0-100) gates registration via InpMinScore and is appended to
// the chart label when InpShowScore is on.
void EmphasizeBox(string name, datetime t1, datetime t2, double pHigh, double pLow,
                  color clr, bool bullish, int tfSlot, int score=70)
  {
   if(score < InpMinScore) return;
   Register(name,t1,t2,pHigh,pLow,clr,bullish,tfSlot,score);
   if(tfSlot >= 0) return;
   string tag = name + "_" + (string)t1;
   StringReplace(tag," ","_");
   StringReplace(tag,"&","_");
   string labelText = LocalizedPatternName(name);
   if(InpShowScore) labelText = labelText + " (" + (string)score + ")";
   DrawBox(tag,t1,pHigh,t2,pLow,clr);
   DrawLabel(tag+"_lbl", t2, pHigh, labelText, clr, true);
   FireAlert(name,bullish,score);
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
      int prevH = -1;
      for(int j=i-1;j>=0;j--) if(pv[j].isHigh){ prevH=j; break; }
      if(prevH<0) continue;
      int valley = -1;
      for(int j=prevH+1;j<i;j++) if(!pv[j].isHigh){ valley=j; break; }
      if(valley<0) continue;
      if(!Equalish(pv[i].price, pv[prevH].price)) continue;

      double depth = pv[i].price - pv[valley].price;
      double base  = pv[i].price;
      // Require meaningful depth: %-of-price AND multiple-of-ATR
      if(depth/base*100.0 < 0.30) continue;
      if(g_curATR > 0 && depth < InpMinPatternATR * g_curATR) continue;
      int span = pv[i].idx - pv[prevH].idx;
      if(span < InpMinPatternBars) continue;

      // Optional neckline break confirmation (close below valley)
      if(!BreakConfirmed(rates, pv[valley].price, false)) continue;

      int trend = PriorTrend(rates, pv[prevH].idx, 30);
      int score = ComputeScore(trend > 0 ? 1 : (trend == 0 ? 0 : -1),
                               RelDiffPct(pv[i].price, pv[prevH].price),
                               (g_curATR > 0) ? depth/g_curATR : 1.0,
                               0, InpRequireBreak);
      EmphasizeBox("Double Top", pv[prevH].time, pv[i].time,
                   MathMax(pv[i].price,pv[prevH].price), pv[valley].price,
                   InpBearColor, false, tfSlot, score);
      if(tfSlot<0)
        {
         string tag = "DT_neck_"+(string)pv[i].time;
         DrawTrend(tag, pv[valley].time, pv[valley].price,
                   pv[i].time, pv[valley].price, InpBearColor, STYLE_DASH, true);
        }
      return;
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
      if(g_curATR > 0 && height < InpMinPatternATR * g_curATR) continue;
      int span = pv[i].idx - pv[prevL].idx;
      if(span < InpMinPatternBars) continue;

      // Optional neckline break confirmation (close above peak)
      if(!BreakConfirmed(rates, pv[peak].price, true)) continue;

      int trend = PriorTrend(rates, pv[prevL].idx, 30);
      int score = ComputeScore(trend < 0 ? 1 : (trend == 0 ? 0 : -1),
                               RelDiffPct(pv[i].price, pv[prevL].price),
                               (g_curATR > 0) ? height/g_curATR : 1.0,
                               0, InpRequireBreak);
      EmphasizeBox("Double Bottom", pv[prevL].time, pv[i].time,
                   pv[peak].price, MathMin(pv[i].price,pv[prevL].price),
                   InpBullColor, true, tfSlot, score);
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
      double depth = top - neck;
      // Same depth + span gating as Double Top
      if(top > 0 && depth/top*100.0 < 0.30) continue;
      if(g_curATR > 0 && depth < InpMinPatternATR * g_curATR) continue;
      if(pv[i].idx - pv[h1].idx < InpMinPatternBars) continue;
      if(!BreakConfirmed(rates, neck, false)) continue;

      int trend = PriorTrend(rates, pv[h1].idx, 30);
      double avgTolPct = (RelDiffPct(pv[h1].price,pv[h2].price)
                        + RelDiffPct(pv[h2].price,pv[i].price)) * 0.5;
      int score = ComputeScore(trend > 0 ? 1 : (trend == 0 ? 0 : -1),
                               avgTolPct,
                               (g_curATR > 0) ? depth/g_curATR : 1.0,
                               0, InpRequireBreak) + 5;  // triple is rarer → bonus
      if(score > 100) score = 100;
      EmphasizeBox("Triple Top", pv[h1].time, pv[i].time, top, neck,
                   InpBearColor, false, tfSlot, score);
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
      double height = neck - bot;
      if(neck > 0 && height/neck*100.0 < 0.30) continue;
      if(g_curATR > 0 && height < InpMinPatternATR * g_curATR) continue;
      if(pv[i].idx - pv[l1].idx < InpMinPatternBars) continue;
      if(!BreakConfirmed(rates, neck, true)) continue;

      int trend = PriorTrend(rates, pv[l1].idx, 30);
      double avgTolPct = (RelDiffPct(pv[l1].price,pv[l2].price)
                        + RelDiffPct(pv[l2].price,pv[i].price)) * 0.5;
      int score = ComputeScore(trend < 0 ? 1 : (trend == 0 ? 0 : -1),
                               avgTolPct,
                               (g_curATR > 0) ? height/g_curATR : 1.0,
                               0, InpRequireBreak) + 5;
      if(score > 100) score = 100;
      EmphasizeBox("Triple Bottom", pv[l1].time, pv[i].time, neck, bot,
                   InpBullColor, true, tfSlot, score);
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

      // Head must be meaningfully higher than shoulders (not just barely)
      double shoulderAvg = (pv[left].price + pv[i].price) * 0.5;
      double headLift = pv[head].price - shoulderAvg;
      if(g_curATR > 0 && headLift < 0.5 * g_curATR) continue;

      // Time symmetry: left-span vs right-span within 50% of each other
      int leftSpan  = pv[head].idx - pv[left].idx;
      int rightSpan = pv[i].idx    - pv[head].idx;
      if(leftSpan <= 0 || rightSpan <= 0) continue;
      double ratio = (double)MathMin(leftSpan,rightSpan)
                   / (double)MathMax(leftSpan,rightSpan);
      if(ratio < 0.50) continue;

      int v1=-1,v2=-1;
      for(int j=left+1;j<head;j++) if(!pv[j].isHigh){ v1=j; break; }
      for(int j=head+1;j<i;j++)    if(!pv[j].isHigh){ v2=j; break; }
      if(v1<0||v2<0) continue;
      double neck = MathMin(pv[v1].price,pv[v2].price);

      if(!BreakConfirmed(rates, neck, false)) continue;

      int trend = PriorTrend(rates, pv[left].idx, 30);
      double depth = pv[head].price - neck;
      int baseScore = ComputeScore(trend > 0 ? 1 : (trend == 0 ? 0 : -1),
                                   RelDiffPct(pv[left].price, pv[i].price),
                                   (g_curATR > 0) ? depth/g_curATR : 1.0,
                                   0, InpRequireBreak);
      int score = baseScore + (int)(ratio * 10) - 5;  // symmetry bonus
      if(score < 0)   score = 0;
      if(score > 100) score = 100;
      EmphasizeBox("Head&Shoulders", pv[left].time, pv[i].time,
                   pv[head].price, neck, InpBearColor, false, tfSlot, score);
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

      double shoulderAvg = (pv[left].price + pv[i].price) * 0.5;
      double headDrop = shoulderAvg - pv[head].price;
      if(g_curATR > 0 && headDrop < 0.5 * g_curATR) continue;

      int leftSpan  = pv[head].idx - pv[left].idx;
      int rightSpan = pv[i].idx    - pv[head].idx;
      if(leftSpan <= 0 || rightSpan <= 0) continue;
      double ratio = (double)MathMin(leftSpan,rightSpan)
                   / (double)MathMax(leftSpan,rightSpan);
      if(ratio < 0.50) continue;

      int p1=-1,p2=-1;
      for(int j=left+1;j<head;j++) if(pv[j].isHigh){ p1=j; break; }
      for(int j=head+1;j<i;j++)    if(pv[j].isHigh){ p2=j; break; }
      if(p1<0||p2<0) continue;
      double neck = MathMax(pv[p1].price,pv[p2].price);

      if(!BreakConfirmed(rates, neck, true)) continue;

      int trend = PriorTrend(rates, pv[left].idx, 30);
      double depth = neck - pv[head].price;
      int baseScore = ComputeScore(trend < 0 ? 1 : (trend == 0 ? 0 : -1),
                                   RelDiffPct(pv[left].price, pv[i].price),
                                   (g_curATR > 0) ? depth/g_curATR : 1.0,
                                   0, InpRequireBreak);
      int score = baseScore + (int)(ratio * 10) - 5;
      if(score < 0)   score = 0;
      if(score > 100) score = 100;
      EmphasizeBox("Inverse H&S", pv[left].time, pv[i].time, neck,
                   pv[head].price, InpBullColor, true, tfSlot, score);
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

// --- V-Top / V-Bottom: sharp single pivot with strong opposite moves on each side.
//     Threshold is ATR-relative (>= InpMinPatternATR * ATR drop on BOTH sides),
//     so calm pairs don't trigger and volatile pairs don't drown out the signal.
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
      double drop1 = pv[i].price - leftLow;
      double drop2 = pv[i].price - rightLow;
      double need  = (g_curATR > 0)
                     ? InpMinPatternATR * g_curATR
                     : pv[i].price * 0.01;
      if(drop1 > need && drop2 > need)
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
      double rise1 = leftHigh  - pv[i].price;
      double rise2 = rightHigh - pv[i].price;
      double need  = (g_curATR > 0)
                     ? InpMinPatternATR * g_curATR
                     : pv[i].price * 0.01;
      if(rise1 > need && rise2 > need)
        {
         EmphasizeBox("V-Bottom", rates[back].time, rates[fwd].time,
                      MathMax(leftHigh,rightHigh), pv[i].price,
                      InpBullColor, true, tfSlot);
         return;
        }
     }
  }

// --- Diamond: broadening phase followed by symmetrical contraction.
//     Split last 7 pivots into older half (broadening) and newer half
//     (contracting). Each half must have ≥2 highs and ≥2 lows whose
//     sequence respects the expected direction. Trend context selects
//     Top vs Bottom so the two detectors never double-fire.
bool DiamondShape(const Pivot &pv[], int a, int b)
  {
   int mid = (a + b) / 2;
   double prevH=-1, prevL=1e18;
   int hCount=0, lCount=0;
   bool bHi=true, bLo=true;
   for(int i=a;i<=mid;i++)
     {
      if(pv[i].isHigh)
        {
         if(prevH>0 && pv[i].price <= prevH) bHi=false;
         prevH = pv[i].price; hCount++;
        }
      else
        {
         if(prevL<1e17 && pv[i].price >= prevL) bLo=false;
         prevL = pv[i].price; lCount++;
        }
     }
   if(hCount<2 || lCount<2 || !bHi || !bLo) return false;

   prevH=-1; prevL=1e18; hCount=0; lCount=0;
   bool cHi=true, cLo=true;
   for(int i=mid+1;i<=b;i++)
     {
      if(pv[i].isHigh)
        {
         if(prevH>0 && pv[i].price >= prevH) cHi=false;
         prevH = pv[i].price; hCount++;
        }
      else
        {
         if(prevL<1e17 && pv[i].price <= prevL) cLo=false;
         prevL = pv[i].price; lCount++;
        }
     }
   return (hCount>=2 && lCount>=2 && cHi && cLo);
  }

void DetectDiamondTop(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   if(n < 7) return;
   int a=n-7, b=n-1;
   if(!DiamondShape(pv,a,b)) return;
   // Only register as TOP after preceding uptrend
   if(InpRequireTrend && PriorTrend(rates, ArraySize(rates)-2, 30) <= 0) return;
   double maxH=-1, minL=1e18;
   for(int i=a;i<=b;i++)
     {
      if(pv[i].isHigh && pv[i].price>maxH) maxH=pv[i].price;
      if(!pv[i].isHigh && pv[i].price<minL) minL=pv[i].price;
     }
   if(maxH<0||minL>1e17) return;
   EmphasizeBox("Diamond Top", pv[a].time, pv[b].time, maxH, minL,
                InpBearColor, false, tfSlot);
  }

void DetectDiamondBottom(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   if(n < 7) return;
   int a=n-7, b=n-1;
   if(!DiamondShape(pv,a,b)) return;
   if(InpRequireTrend && PriorTrend(rates, ArraySize(rates)-2, 30) >= 0) return;
   double maxH=-1, minL=1e18;
   for(int i=a;i<=b;i++)
     {
      if(pv[i].isHigh && pv[i].price>maxH) maxH=pv[i].price;
      if(!pv[i].isHigh && pv[i].price<minL) minL=pv[i].price;
     }
   if(maxH<0||minL>1e17) return;
   EmphasizeBox("Diamond Bottom", pv[a].time, pv[b].time, maxH, minL,
                InpBullColor, true, tfSlot);
  }

// --- Broadening / Megaphone: highs ascending AND lows descending.
//     Top vs Bottom resolved by preceding trend so the two detectors
//     are mutually exclusive — they cannot both fire on the same shape.
bool BroadeningShape(const Pivot &pv[], int a, int b, double &maxH, double &minL)
  {
   int hCnt=0, lCnt=0;
   double prevH=-1, prevL=1e18;
   bool hAsc=true, lDesc=true;
   maxH = -1; minL = 1e18;
   for(int i=a;i<=b;i++)
     {
      if(pv[i].isHigh)
        {
         if(prevH>0 && pv[i].price <= prevH) hAsc=false;
         prevH = pv[i].price; hCnt++;
         if(pv[i].price > maxH) maxH = pv[i].price;
        }
      else
        {
         if(prevL<1e17 && pv[i].price >= prevL) lDesc=false;
         prevL = pv[i].price; lCnt++;
         if(pv[i].price < minL) minL = pv[i].price;
        }
     }
   return (hCnt>=2 && lCnt>=2 && hAsc && lDesc);
  }

void DetectBroadeningTop(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   if(n < 5) return;
   int a = MathMax(0,n-7);
   double maxH, minL;
   if(!BroadeningShape(pv,a,n-1,maxH,minL)) return;
   // Top only after preceding uptrend
   if(PriorTrend(rates, ArraySize(rates)-2, 30) <= 0) return;
   EmphasizeBox("Broadening Top", pv[a].time, pv[n-1].time,
                maxH, minL, InpBearColor, false, tfSlot);
  }

void DetectBroadeningBottom(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(pv);
   if(n < 5) return;
   int a = MathMax(0,n-7);
   double maxH, minL;
   if(!BroadeningShape(pv,a,n-1,maxH,minL)) return;
   if(PriorTrend(rates, ArraySize(rates)-2, 30) >= 0) return;
   EmphasizeBox("Broadening Bottom", pv[a].time, pv[n-1].time,
                maxH, minL, InpBullColor, true, tfSlot);
  }

//==================================================================
// PATTERN DETECTORS — CONTINUATION
//==================================================================

// --- Flags: strong pole then parallel channel against trend.
//     Pole magnitude required as a multiple of ATR rather than a flat %,
//     so the threshold adapts across timeframes and instruments.
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
   double poleGain = poleHigh - poleLow;
   double need     = (g_curATR > 0) ? InpPoleMinATR * g_curATR : poleLow*0.01;
   if(poleGain < need) return;
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
   double poleDrop = poleHigh - poleLow;
   double need     = (g_curATR > 0) ? InpPoleMinATR * g_curATR : poleHigh*0.01;
   if(poleDrop < need) return;
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
   double poleGain = rates[pStart].high - rates[poleS].low;
   double need     = (g_curATR > 0) ? InpPoleMinATR * g_curATR : rates[poleS].low*0.01;
   if(poleGain < need) return;
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
   double poleDrop = rates[poleS].high - rates[pStart].low;
   double need     = (g_curATR > 0) ? InpPoleMinATR * g_curATR : rates[poleS].high*0.01;
   if(poleDrop < need) return;
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

   // Rectangle is taken seriously only with multiple touches per rail
   int hT = CountTouches(pv, pv[h1].idx, pv[h1].price, pv[h2].idx, pv[h2].price, true);
   int lT = CountTouches(pv, pv[l1].idx, pv[l1].price, pv[l2].idx, pv[l2].price, false);
   if(MathMin(hT,lT) < 2 || (hT + lT) < InpMinTouches + 1) return;

   double resistance = (pv[h1].price + pv[h2].price) * 0.5;
   double support    = (pv[l1].price + pv[l2].price) * 0.5;
   double last = rates[ArraySize(rates)-1].close;
   // Direction is decided by an actual breakout above resistance or
   // below support, not by which half of the box price sits in.
   bool bullish    = last > resistance;
   bool bearish    = last < support;
   if(!bullish && !bearish) return;

   datetime t1 = DTMin(pv[h1].time,pv[l1].time);
   datetime t2 = DTMax(pv[h2].time,pv[l2].time);
   double height = resistance - support;
   double avgTolPct = (RelDiffPct(pv[h1].price, pv[h2].price)
                     + RelDiffPct(pv[l1].price, pv[l2].price)) * 0.5;
   int score = ComputeScore(0, avgTolPct,
                            (g_curATR > 0) ? height/g_curATR : 1.0,
                            hT + lT);
   EmphasizeBox("Rectangle", t1, t2, MathMax(pv[h1].price,pv[h2].price),
                MathMin(pv[l1].price,pv[l2].price),
                bullish?InpBullColor:InpBearColor, bullish, tfSlot, score);
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

   // Require ≥InpMinTouches touches on at least one line, ≥2 on the other
   int hT = CountTouches(pv, pv[h1].idx, pv[h1].price, pv[h2].idx, pv[h2].price, true);
   int lT = CountTouches(pv, pv[l1].idx, pv[l1].price, pv[l2].idx, pv[l2].price, false);
   if(MathMax(hT,lT) < InpMinTouches || MathMin(hT,lT) < 2) return;

   datetime t1 = DTMin(pv[h1].time,pv[l1].time);
   datetime t2 = DTMax(pv[h2].time,pv[l2].time);
   double height = pv[h2].price - pv[l1].price;
   int trend = PriorTrend(rates, pv[l1].idx, 30);
   int score = ComputeScore(trend >= 0 ? 1 : -1,
                            RelDiffPct(pv[h1].price, pv[h2].price),
                            (g_curATR > 0) ? height/g_curATR : 1.0,
                            hT + lT);
   EmphasizeBox("Asc Triangle", t1, t2, MathMax(pv[h1].price,pv[h2].price),
                MathMin(pv[l1].price,pv[l2].price),
                InpBullColor, true, tfSlot, score);
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

   int hT = CountTouches(pv, pv[h1].idx, pv[h1].price, pv[h2].idx, pv[h2].price, true);
   int lT = CountTouches(pv, pv[l1].idx, pv[l1].price, pv[l2].idx, pv[l2].price, false);
   if(MathMax(hT,lT) < InpMinTouches || MathMin(hT,lT) < 2) return;

   datetime t1 = DTMin(pv[h1].time,pv[l1].time);
   datetime t2 = DTMax(pv[h2].time,pv[l2].time);
   double height = pv[h1].price - pv[l1].price;
   int trend = PriorTrend(rates, pv[h1].idx, 30);
   int score = ComputeScore(trend <= 0 ? 1 : -1,
                            RelDiffPct(pv[l1].price, pv[l2].price),
                            (g_curATR > 0) ? height/g_curATR : 1.0,
                            hT + lT);
   EmphasizeBox("Desc Triangle", t1, t2, MathMax(pv[h1].price,pv[h2].price),
                MathMin(pv[l1].price,pv[l2].price),
                InpBearColor, false, tfSlot, score);
   if(tfSlot<0)
     {
      string tag = "DSC_"+(string)pv[h2].time;
      DrawTrend("DSC_top_"+tag, pv[h1].time, pv[h1].price, pv[h2].time, pv[h2].price,
                InpBearColor, STYLE_SOLID, true);
      DrawTrend("DSC_bot_"+tag, pv[l1].time, pv[l1].price, pv[l2].time, pv[l2].price,
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

   int hT = CountTouches(pv, pv[h1].idx, pv[h1].price, pv[h2].idx, pv[h2].price, true);
   int lT = CountTouches(pv, pv[l1].idx, pv[l1].price, pv[l2].idx, pv[l2].price, false);
   if(MathMax(hT,lT) < InpMinTouches || MathMin(hT,lT) < 2) return;

   datetime t1 = DTMin(pv[h1].time,pv[l1].time);
   datetime t2 = DTMax(pv[h2].time,pv[l2].time);
   double height = pv[h1].price - pv[l1].price;
   // Sym triangle is neutral — score uses neutral trend alignment
   int score = ComputeScore(0,
                            0.0,  // no equality constraint to fit
                            (g_curATR > 0) ? height/g_curATR : 1.0,
                            hT + lT);
   EmphasizeBox("Sym Triangle", t1, t2, MathMax(pv[h1].price,pv[h2].price),
                MathMin(pv[l1].price,pv[l2].price),
                InpNeutralColor, true, tfSlot, score);
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

   int hT = CountTouches(pv, pv[h1].idx, pv[h1].price, pv[h2].idx, pv[h2].price, true);
   int lT = CountTouches(pv, pv[l1].idx, pv[l1].price, pv[l2].idx, pv[l2].price, false);
   if(MathMax(hT,lT) < InpMinTouches || MathMin(hT,lT) < 2) return;

   datetime t1 = DTMin(pv[h1].time,pv[l1].time);
   datetime t2 = DTMax(pv[h2].time,pv[l2].time);
   double height = pv[h2].price - pv[l1].price;
   int trend = PriorTrend(rates, pv[l1].idx, 30);
   int score = ComputeScore(trend > 0 ? 1 : 0, 0.0,
                            (g_curATR > 0) ? height/g_curATR : 1.0,
                            hT + lT);
   EmphasizeBox("Rising Wedge", t1, t2, pv[h2].price, pv[l1].price,
                InpBearColor, false, tfSlot, score);
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

   int hT = CountTouches(pv, pv[h1].idx, pv[h1].price, pv[h2].idx, pv[h2].price, true);
   int lT = CountTouches(pv, pv[l1].idx, pv[l1].price, pv[l2].idx, pv[l2].price, false);
   if(MathMax(hT,lT) < InpMinTouches || MathMin(hT,lT) < 2) return;

   datetime t1 = DTMin(pv[h1].time,pv[l1].time);
   datetime t2 = DTMax(pv[h2].time,pv[l2].time);
   double height = pv[h1].price - pv[l2].price;
   int trend = PriorTrend(rates, pv[h1].idx, 30);
   int score = ComputeScore(trend < 0 ? 1 : 0, 0.0,
                            (g_curATR > 0) ? height/g_curATR : 1.0,
                            hT + lT);
   EmphasizeBox("Falling Wedge", t1, t2, pv[h1].price, pv[l2].price,
                InpBullColor, true, tfSlot, score);
  }

// --- Cup & Handle / Inverse.
//     Adaptive sizing: cup span scales with available bars; handle is
//     ~15% of cup span. Cup depth must be >= InpMinPatternATR x ATR.
//     Handle retrace must not exceed 50% of cup depth (classical rule).
void DetectCupHandle(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(rates);
   int span = MathMin(80, n - 10);
   if(span < 25) return;
   int end = n-2;
   int handleLen = MathMax(5, span/7);
   int handleStart = end - handleLen;
   int cupEnd = handleStart;
   int cupStart = cupEnd - (span - handleLen);
   if(cupStart < 0) return;

   double leftRim  = rates[cupStart].high;
   double rightRim = rates[cupEnd].high;
   if(!Equalish(leftRim, rightRim)) return;

   double trough = rates[cupStart].low;
   for(int i=cupStart;i<=cupEnd;i++) if(rates[i].low < trough) trough = rates[i].low;
   double depth = leftRim - trough;
   if(leftRim > 0 && depth/leftRim*100.0 < 1.0) return;
   if(g_curATR > 0 && depth < InpMinPatternATR * g_curATR) return;

   // Handle constraints: stays below rim, above trough, and retraces
   // no more than ~50% of cup depth.
   double hMin=1e18, hMax=-1;
   for(int i=handleStart;i<=end;i++)
     {
      if(rates[i].low<hMin) hMin=rates[i].low;
      if(rates[i].high>hMax) hMax=rates[i].high;
     }
   if(hMax > leftRim) return;
   if(hMin < trough)  return;
   if(rightRim - hMin > 0.5 * depth) return;

   EmphasizeBox("Cup&Handle", rates[cupStart].time, rates[end].time,
                MathMax(leftRim,rightRim), trough,
                InpBullColor, true, tfSlot);
  }

void DetectInverseCupHandle(const MqlRates &rates[], const Pivot &pv[], bool draw, int tfSlot)
  {
   int n = ArraySize(rates);
   int span = MathMin(80, n - 10);
   if(span < 25) return;
   int end = n-2;
   int handleLen = MathMax(5, span/7);
   int handleStart = end - handleLen;
   int cupEnd = handleStart;
   int cupStart = cupEnd - (span - handleLen);
   if(cupStart < 0) return;

   double leftRim  = rates[cupStart].low;
   double rightRim = rates[cupEnd].low;
   if(!Equalish(leftRim, rightRim)) return;

   double peak = rates[cupStart].high;
   for(int i=cupStart;i<=cupEnd;i++) if(rates[i].high > peak) peak = rates[i].high;
   double height = peak - leftRim;
   if(leftRim > 0 && height/leftRim*100.0 < 1.0) return;
   if(g_curATR > 0 && height < InpMinPatternATR * g_curATR) return;

   double hMin=1e18, hMax=-1;
   for(int i=handleStart;i<=end;i++)
     {
      if(rates[i].low<hMin) hMin=rates[i].low;
      if(rates[i].high>hMax) hMax=rates[i].high;
     }
   if(hMin < leftRim) return;
   if(hMax > peak)    return;
   if(hMax - rightRim > 0.5 * height) return;

   EmphasizeBox("Inv Cup&Handle", rates[cupStart].time, rates[end].time,
                peak, MathMin(leftRim,rightRim),
                InpBearColor, false, tfSlot);
  }

//==================================================================
// CANDLESTICK PATTERNS (last few bars)
//==================================================================
// Helper: trend gate. Returns true when the prior trend matches what
// the candlestick pattern needs. If InpRequireTrend is off, always true.
bool TrendOK(const MqlRates &rates[], int idx, int wantDir)
  {
   if(!InpRequireTrend) return true;
   int dir = PriorTrend(rates, idx-1, 20);
   return (wantDir > 0) ? (dir > 0) : (dir < 0);
  }

void DetectCandlestickPatterns(const MqlRates &rates[], bool draw, int tfSlot)
  {
   int n = ArraySize(rates);
   if(n < 5) return;
   int last = n-2; // last closed bar

   // --- Engulfing (strict: second body must STRICTLY exceed first) ---
   if(InpEngulfing)
     {
      double o1=rates[last-1].open, c1=rates[last-1].close;
      double o2=rates[last].open,   c2=rates[last].close;
      bool bullEng = (c1<o1) && (c2>o2) && (o2 < c1) && (c2 > o1) && TrendOK(rates,last,-1);
      bool bearEng = (c1>o1) && (c2<o2) && (o2 > c1) && (c2 < o1) && TrendOK(rates,last,+1);
      if(bullEng)
         EmphasizeBox("Engulfing", rates[last-1].time, rates[last].time,
                      MathMax(rates[last-1].high,rates[last].high),
                      MathMin(rates[last-1].low,rates[last].low),
                      InpBullColor, true, tfSlot);
      else if(bearEng)
         EmphasizeBox("Engulfing", rates[last-1].time, rates[last].time,
                      MathMax(rates[last-1].high,rates[last].high),
                      MathMin(rates[last-1].low,rates[last].low),
                      InpBearColor, false, tfSlot);
     }

   // --- Hammer (bullish reversal; needs prior downtrend) ---
   if(InpHammer)
     {
      double body = MathAbs(rates[last].close - rates[last].open);
      double range = rates[last].high - rates[last].low;
      double lowerWick = MathMin(rates[last].open,rates[last].close) - rates[last].low;
      double upperWick = rates[last].high - MathMax(rates[last].open,rates[last].close);
      if(range>0 && body/range < 0.35 && lowerWick > body*2 && upperWick < body
         && TrendOK(rates,last,-1))
         EmphasizeBox("Hammer", rates[last].time, rates[last].time,
                      rates[last].high, rates[last].low,
                      InpBullColor, true, tfSlot);
     }

   // --- Shooting Star (bearish reversal; needs prior uptrend) ---
   if(InpShootingStar)
     {
      double body = MathAbs(rates[last].close - rates[last].open);
      double range = rates[last].high - rates[last].low;
      double upperWick = rates[last].high - MathMax(rates[last].open,rates[last].close);
      double lowerWick = MathMin(rates[last].open,rates[last].close) - rates[last].low;
      if(range>0 && body/range < 0.35 && upperWick > body*2 && lowerWick < body
         && TrendOK(rates,last,+1))
         EmphasizeBox("Shooting Star", rates[last].time, rates[last].time,
                      rates[last].high, rates[last].low,
                      InpBearColor, false, tfSlot);
     }

   // --- Doji (indecision; trend-agnostic so no gate) ---
   if(InpDoji)
     {
      double body = MathAbs(rates[last].close - rates[last].open);
      double range = rates[last].high - rates[last].low;
      if(range > 0 && body/range < 0.08)
         EmphasizeBox("Doji", rates[last].time, rates[last].time,
                      rates[last].high, rates[last].low,
                      InpNeutralColor, true, tfSlot);
     }

   // --- Morning / Evening Star (3-bar reversal) ---
   if(n >= 5)
     {
      double o1=rates[last-2].open,c1=rates[last-2].close;
      double o2=rates[last-1].open,c2=rates[last-1].close;
      double o3=rates[last].open,  c3=rates[last].close;
      double mid = (o1+c1)/2.0;
      if(InpMorningStar
         && c1<o1 && MathAbs(c2-o2) < MathAbs(c1-o1)*0.4 && c3>o3 && c3>mid
         && TrendOK(rates,last-2,-1))
         EmphasizeBox("Morning Star", rates[last-2].time, rates[last].time,
                      MathMax(rates[last-2].high,rates[last].high),
                      MathMin(rates[last-2].low,rates[last].low),
                      InpBullColor, true, tfSlot);
      if(InpEveningStar
         && c1>o1 && MathAbs(c2-o2) < MathAbs(c1-o1)*0.4 && c3<o3 && c3<mid
         && TrendOK(rates,last-2,+1))
         EmphasizeBox("Evening Star", rates[last-2].time, rates[last].time,
                      MathMax(rates[last-2].high,rates[last].high),
                      MathMin(rates[last-2].low,rates[last].low),
                      InpBearColor, false, tfSlot);
     }

   // --- Three Soldiers / Three Crows (require similar bodies, small upper/lower wicks) ---
   if(n >= 5)
     {
      if(InpThreeSoldiers)
        {
         bool ok = true;
         double bodies[3];
         for(int k=last-2;k<=last;k++)
           {
            if(rates[k].close <= rates[k].open){ ok=false; break; }
            bodies[k-(last-2)] = rates[k].close - rates[k].open;
           }
         if(ok)
           {
            // upper wicks small (< 30% of body)
            for(int k=last-2;k<=last;k++)
              {
               double uw = rates[k].high - rates[k].close;
               if(uw > (rates[k].close - rates[k].open) * 0.3) { ok=false; break; }
              }
           }
         // bodies of similar size (smallest >= 50% of largest)
         double bMax = MathMax(bodies[0], MathMax(bodies[1], bodies[2]));
         double bMin = MathMin(bodies[0], MathMin(bodies[1], bodies[2]));
         if(bMax > 0 && bMin / bMax < 0.5) ok = false;
         if(ok && rates[last].close > rates[last-1].close
               && rates[last-1].close > rates[last-2].close
               && TrendOK(rates,last-2,-1))
            EmphasizeBox("Three Soldiers", rates[last-2].time, rates[last].time,
                         rates[last].high, rates[last-2].low,
                         InpBullColor, true, tfSlot);
        }
      if(InpThreeCrows)
        {
         bool ok = true;
         double bodies[3];
         for(int k=last-2;k<=last;k++)
           {
            if(rates[k].close >= rates[k].open){ ok=false; break; }
            bodies[k-(last-2)] = rates[k].open - rates[k].close;
           }
         if(ok)
           {
            for(int k=last-2;k<=last;k++)
              {
               double lw = rates[k].close - rates[k].low;
               if(lw > (rates[k].open - rates[k].close) * 0.3) { ok=false; break; }
              }
           }
         double bMax = MathMax(bodies[0], MathMax(bodies[1], bodies[2]));
         double bMin = MathMin(bodies[0], MathMin(bodies[1], bodies[2]));
         if(bMax > 0 && bMin / bMax < 0.5) ok = false;
         if(ok && rates[last].close < rates[last-1].close
               && rates[last-1].close < rates[last-2].close
               && TrendOK(rates,last-2,+1))
            EmphasizeBox("Three Crows", rates[last-2].time, rates[last].time,
                         rates[last-2].high, rates[last].low,
                         InpBearColor, false, tfSlot);
        }
     }

   // --- Tweezer Top/Bottom (2-bar reversal; needs prior trend) ---
   if(InpTweezer && n >= 3)
     {
      if(Equalish(rates[last].high, rates[last-1].high) &&
         rates[last-1].close > rates[last-1].open && rates[last].close < rates[last].open
         && TrendOK(rates,last-1,+1))
         EmphasizeBox("Tweezer Top", rates[last-1].time, rates[last].time,
                      rates[last].high,
                      MathMin(rates[last-1].low,rates[last].low),
                      InpBearColor, false, tfSlot);
      if(Equalish(rates[last].low, rates[last-1].low) &&
         rates[last-1].close < rates[last-1].open && rates[last].close > rates[last].open
         && TrendOK(rates,last-1,-1))
         EmphasizeBox("Tweezer Bottom", rates[last-1].time, rates[last].time,
                      MathMax(rates[last-1].high,rates[last].high),
                      rates[last].low, InpBullColor, true, tfSlot);
     }

   // --- Piercing Line (bullish reversal; needs prior downtrend) ---
   if(InpPiercing && n >= 3)
     {
      double o1=rates[last-1].open,c1=rates[last-1].close;
      double o2=rates[last].open,  c2=rates[last].close;
      double mid = (o1+c1)/2.0;
      if(c1<o1 && o2<c1 && c2>mid && c2<o1 && TrendOK(rates,last-1,-1))
         EmphasizeBox("Piercing Line", rates[last-1].time, rates[last].time,
                      MathMax(rates[last-1].high,rates[last].high),
                      MathMin(rates[last-1].low,rates[last].low),
                      InpBullColor, true, tfSlot);
     }

   // --- Dark Cloud Cover (bearish reversal; needs prior uptrend) ---
   if(InpDarkCloud && n >= 3)
     {
      double o1=rates[last-1].open,c1=rates[last-1].close;
      double o2=rates[last].open,  c2=rates[last].close;
      double mid = (o1+c1)/2.0;
      if(c1>o1 && o2>c1 && c2<mid && c2>o1 && TrendOK(rates,last-1,+1))
         EmphasizeBox("Dark Cloud Cover", rates[last-1].time, rates[last].time,
                      MathMax(rates[last-1].high,rates[last].high),
                      MathMin(rates[last-1].low,rates[last].low),
                      InpBearColor, false, tfSlot);
     }
  }

//==================================================================
// ALERT
//==================================================================
void FireAlert(string name, bool bullish, int score)
  {
   string key = _Symbol+"_"+(string)(int)_Period+"_"+name;
   if(!ShouldAlert(key, 60)) return;
   string display = LocalizedPatternName(name);
   string dir     = DirectionLabel(bullish);
   string msg = (InpLanguage == LANG_JA)
                ? StringFormat("[PatternScope] %s シグナル: %s スコア%d (%s / %s)",
                               dir, display, score, _Symbol, TFShort(_Period))
                : StringFormat("[PatternScope] %s signal: %s score=%d (%s / %s)",
                               dir, display, score, _Symbol, TFShort(_Period));
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
   int w = 230 + 68*g_tfCount;
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
                  InpDashX+230+68*i, InpDashY+24, InpDashHeader, InpDashFontSize);
     }

   // Rows
   for(int p=0;p<ArraySize(g_patternNames);p++)
     {
      CreateLabel(PS_DASH+"P"+(string)p, LocalizedPatternName(g_patternNames[p]),
                  InpDashX+10, InpDashY+40+14*p, InpDashText, InpDashFontSize);
      for(int t=0;t<g_tfCount;t++)
        {
         CreateLabel(PS_DASH+"C"+(string)p+"_"+(string)t, "-",
                     InpDashX+230+68*t, InpDashY+40+14*p,
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
      default:         return "?";  // unknown TF — avoid overflowing dashboard column
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
            int sc = g_tfStatus[t].score[p];
            txt = DirectionLabel(g_tfStatus[t].bullish[p]) + " " + (string)sc;
            clr = g_tfStatus[t].bullish[p] ? InpBullColor : InpBearColor;
           }
         ObjectSetString (0,name,OBJPROP_TEXT,txt);
         ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
        }
     }
  }

//+------------------------------------------------------------------+
