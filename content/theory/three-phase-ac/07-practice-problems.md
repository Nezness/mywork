# 07. 確認問題

**位置づけ**: 二種一次理論レベルの演習で本トピックの運用力を固める節。1 相分等価、三相電力公式、対称座標の初歩分解を総動員する。
**到達目標**: 03〜06 節で獲得した手順を、見直しなしに一気通貫で回せる状態にする。

---

## 問 1(平衡 Y 負荷の基本)

三相平衡電源(正相順)、線間電圧 $V_L = 200$ V。相インピーダンス $\dot Z_Y = 6 + j8\,\Omega$ の Y 負荷を接続。線路インピーダンスは無視する。

(1) 線電流 $|\dot I_a|$ を求めよ。
(2) 負荷が消費する三相合計の有効電力 $P_{3\phi}$ を求めよ。
(3) 力率 $\cos\theta$(遅れ/進みも明記)を求めよ。

<details>
<summary>解答</summary>

(1) 相電圧 $E_p = V_L/\sqrt 3 = 200/\sqrt 3$ V、$|\dot Z_Y| = \sqrt{6^2 + 8^2} = 10$ Ω。Y 結線では線電流 = 相電流なので
$$
|\dot I_a| = \frac{200/\sqrt 3}{10} = \frac{20}{\sqrt 3} \approx 11.55 \text{ A}.
$$

(2) $\cos\theta = 6/10 = 0.6$ を使って
$$
P_{3\phi} = \sqrt 3\,V_L I_L\cos\theta = \sqrt 3\cdot 200\cdot\tfrac{20}{\sqrt 3}\cdot 0.6 = 2\,400 \text{ W}.
$$
検算: $3|\dot I_a|^2 R = 3\cdot(400/3)\cdot 6 = 2\,400$ W。✓

(3) $\cos\theta = 0.6$、**遅れ**($X > 0$、誘導性)。

</details>

---

## 問 2(Δ 負荷 + 線路インピーダンス)

Y 電源、相電圧 $\dot E_a = \frac{200}{\sqrt 3}\angle 0^\circ$ V(正相平衡)。各線に線路インピーダンス $\dot z = 0.5 + j0.5\,\Omega$。負荷は平衡 Δ、相インピーダンス $\dot Z_\Delta = 15 + j15\,\Omega$。

(1) Δ 負荷を Y 等価に書き換えたときの相インピーダンスを示せ。
(2) 1 相分等価から $|\dot I_a|$ を求めよ。
(3) 負荷(Δ)が消費する有効電力 $P_{\text{load}}$ を求めよ。

<details>
<summary>解答</summary>

(1) $\dot Z_Y = \dot Z_\Delta/3 = 5 + j5\,\Omega$。

(2) 1 相分等価のループインピーダンス
$$
\dot z + \dot Z_Y = (0.5 + 5) + j(0.5 + 5) = 5.5 + j5.5\,\Omega.
$$
$|\dot z + \dot Z_Y| = 5.5\sqrt 2 \approx 7.778$ Ω。相電圧 $E_p = 200/\sqrt 3 \approx 115.47$ V より
$$
|\dot I_a| = \frac{115.47}{7.778} \approx 14.85 \text{ A}.
$$

(3) 負荷消費は Y 等価の抵抗 $R_Y = 5\,\Omega$ で三相合計
$$
P_{\text{load}} = 3\,|\dot I_a|^2 R_Y = 3\cdot 14.85^2\cdot 5 \approx 3\,306 \text{ W}.
$$

(参考)線路損失は $P_{\text{line}} = 3|\dot I_a|^2\cdot 0.5 \approx 331$ W。電源供給 $P_s = 3\cdot E_p\cdot|\dot I_a|\cdot\cos\theta_s$(電源電圧と線電流の位相差 $\theta_s$)と一致することを検算してほしい。

</details>

---

## 問 3(対称座標分解、不平衡率)

不平衡三相電圧 $\dot V_a = 100\angle 0^\circ$、$\dot V_b = 80\angle{-120^\circ}$、$\dot V_c = 120\angle{+120^\circ}$(単位 V)。

(1) 正相・逆相・零相成分 $\dot V_1, \dot V_2, \dot V_0$ を求めよ。
(2) 電圧不平衡率を $|\dot V_2|/|\dot V_1|$ で定義し、数値を求めよ。
(3) 零相が発生しているか判定せよ。

<details>
<summary>解答</summary>

$\alpha = e^{j2\pi/3}$ として、
$$
\dot V_0 = \tfrac{1}{3}(\dot V_a + \dot V_b + \dot V_c), \;
\dot V_1 = \tfrac{1}{3}(\dot V_a + \alpha\dot V_b + \alpha^2\dot V_c), \;
\dot V_2 = \tfrac{1}{3}(\dot V_a + \alpha^2\dot V_b + \alpha\dot V_c).
$$

**$\dot V_1$**(正相): $\alpha\dot V_b = 80\angle(120^\circ - 120^\circ) = 80\angle 0^\circ = 80$、$\alpha^2\dot V_c = 120\angle(240^\circ + 120^\circ) = 120\angle 0^\circ = 120$。よって
$$
\dot V_1 = \tfrac{1}{3}(100 + 80 + 120) = 100 \text{ V(角 0°)}.
$$

**$\dot V_2$**(逆相): $\alpha^2\dot V_b = 80\angle 120^\circ$、$\alpha\dot V_c = 120\angle 240^\circ$。座標で和を取ると
$$
\dot V_2 = \tfrac{1}{3}\big[100 + (-40 + j40\sqrt 3) + (-60 - j60\sqrt 3)\big] = -j\tfrac{20\sqrt 3}{3}.
$$
$|\dot V_2| = 20\sqrt 3/3 \approx 11.55$ V、位相 $-90^\circ$。

**$\dot V_0$**(零相): $\dot V_b$、$\dot V_c$ を直交表示で足すと
$$
\dot V_0 = \tfrac{1}{3}\big[100 + (-40 - j40\sqrt 3) + (-60 + j60\sqrt 3)\big] = j\tfrac{20\sqrt 3}{3}.
$$
$|\dot V_0| = 20\sqrt 3/3 \approx 11.55$ V、位相 $+90^\circ$。

(2) 不平衡率 $|\dot V_2|/|\dot V_1| = 11.55/100 \approx 11.55\%$。

(3) 零相成分は $11.55$ V で、3 相電圧の総和が $3\dot V_0 \ne 0$ になっている。これは「中性点に対する対称性が崩れている」ことの直接的な指標(接地故障や非対称負荷で実測される量)。

**味わいたい点**: (a) 平衡ケース(問 1、問 2)では $\dot V_2 = \dot V_0 = 0$ で、正相だけが全情報を持っていた。(b) 不平衡ケース(問 3)では正相・逆相・零相の 3 つが独立に情報を持ち、それぞれが別々の等価回路で解かれる(対称座標法の要)。一種電力の故障計算は (b) の側を徹底的に深掘りする。

</details>

---

## 次セクションへの接続

3 問を通して、平衡側の機械的手順と不平衡側の最小感覚を確認した。次節 [`08-summary-and-next.md`](./08-summary-and-next.md) で本トピックを俯瞰し、機械・電力・法規の各科目への接続点を整理する。
