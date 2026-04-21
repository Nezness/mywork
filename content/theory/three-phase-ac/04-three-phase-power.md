# 04. 三相電力と瞬時電力一定の証明

**位置づけ**: 三相の**本質的優位性**である「瞬時電力の時間一定性」を、フェーザ計算と瞬時値計算の両面から証明する節。電力系統の安定性・電動機トルク脈動の小ささという実務的帰結が、ここから一直線に出てくる。
**到達目標**:
- 三相合計電力 $P_{3\phi} = \sqrt 3 V_L I_L\cos\theta = 3 V_p I_p\cos\theta$ を導ける。
- **平衡時に** $p_a(t) + p_b(t) + p_c(t) = \text{const}$ を瞬時値で証明できる。
- 三相複素電力 $\dot S_{3\phi} = 3\dot V_p\,\overline{\dot I_p}$ と有効/無効/皮相電力の関係を書ける。

---

## 1. 三相合計電力の表現

### 1.1 有効電力

平衡三相では各相が同じ有効電力を消費するので、相電圧実効値 $V_p$、相電流実効値 $I_p$、力率 $\cos\theta$(= 各相の負荷インピーダンス位相)を用いて
$$
P_{3\phi} = 3\,V_p I_p\cos\theta.
$$

Y 結線では $V_L = \sqrt 3 V_p$、$I_L = I_p$ なので
$$
P_{3\phi} = 3 \cdot \frac{V_L}{\sqrt 3} \cdot I_L\cos\theta = \sqrt 3\,V_L I_L\cos\theta.
$$

Δ 結線では $V_L = V_p$、$I_L = \sqrt 3 I_p$ で同様に
$$
P_{3\phi} = 3\,V_L\cdot\frac{I_L}{\sqrt 3}\cos\theta = \sqrt 3\,V_L I_L\cos\theta.
$$

**結線形式によらず**
$$
\boxed{\;P_{3\phi} = \sqrt 3\,V_L I_L\cos\theta = 3\,V_p I_p\cos\theta\;}.
$$

### 1.2 無効/皮相/複素電力

同型の導出で
$$
Q_{3\phi} = \sqrt 3\,V_L I_L\sin\theta, \qquad |\dot S_{3\phi}| = \sqrt 3\,V_L I_L.
$$
複素電力としては
$$
\dot S_{3\phi} = 3\,\dot V_p\,\overline{\dot I_p} = P_{3\phi} + j Q_{3\phi}.
$$

> **Note(一種への伏線)**: 「 $\sqrt 3 V_L I_L\cos\theta$ 」の $\cos\theta$ は**負荷の力率角**であり、$V_L$ と $I_L$ の位相差ではない(Y 結線では $V_L$ と $I_L$ のあいだに 30° の構造的ずれがある)。一種電力では有効電力・無効電力を複素ベクトルのまま扱う PQ 平面解析、Stability / 潮流計算の入口になる。常に「どこで測った量か」を意識すること。

## 2. 瞬時電力一定の証明

### 2.1 瞬時値表現

平衡三相、各相の力率角 $\theta$、相電圧・相電流の最大値 $V_{pm} = \sqrt 2\,V_p$、$I_{pm} = \sqrt 2\,I_p$ とおくと
$$
\begin{aligned}
v_a(t) &= \sqrt 2\,V_p\cos\omega t, & i_a(t) &= \sqrt 2\,I_p\cos(\omega t - \theta), \\
v_b(t) &= \sqrt 2\,V_p\cos(\omega t - \tfrac{2\pi}{3}), & i_b(t) &= \sqrt 2\,I_p\cos(\omega t - \tfrac{2\pi}{3} - \theta), \\
v_c(t) &= \sqrt 2\,V_p\cos(\omega t + \tfrac{2\pi}{3}), & i_c(t) &= \sqrt 2\,I_p\cos(\omega t + \tfrac{2\pi}{3} - \theta).
\end{aligned}
$$

各相の瞬時電力 $p_k(t) = v_k(t) i_k(t)$。積和公式 $\cos A\cos B = \tfrac{1}{2}[\cos(A-B) + \cos(A+B)]$ を適用すると
$$
p_k(t) = V_p I_p\big[\cos\theta + \cos(2\omega t - 2\varphi_k - \theta)\big]
$$
ここで $\varphi_a = 0$、$\varphi_b = 2\pi/3$、$\varphi_c = -2\pi/3$。

### 2.2 合計

$$
p_{3\phi}(t) = \sum_k p_k(t) = 3\,V_p I_p\cos\theta + V_p I_p\sum_k\cos(2\omega t - 2\varphi_k - \theta).
$$

**第 2 項の和**: $2\varphi_k$ は $0, 4\pi/3, -4\pi/3$(mod $2\pi$ で $0, -2\pi/3, 2\pi/3$)と再び 120° 等配分になっている。対称性から
$$
\sum_k\cos(2\omega t - 2\varphi_k - \theta) = 0.
$$

(証明: 3 つのフェーザ $e^{-j2\varphi_k}$ は $1, e^{-j4\pi/3}, e^{+j4\pi/3}$ で和は $0$。その実部をとっただけ。)

したがって
$$
\boxed{\;p_{3\phi}(t) = 3\,V_p I_p\cos\theta = P_{3\phi} = \text{const.}\;}
$$

### 2.3 帰結

- **単相では** 瞬時電力は $V_p I_p\cos\theta + V_p I_p\cos(2\omega t - \theta)$ となり、倍周波で脈動する(電動機なら 2$\omega$ のトルク脈動、電源なら電源平滑キャパシタが必要になる)。
- **三相では** この脈動が 3 相で打ち消しあい、瞬時電力が直流並みに平坦になる。電動機ではトルク脈動が原理的にゼロ、電源では平滑用 DC リンクの要求が劇的に緩む。

これが三相が回転機と送電の両方で支配的な理由の**根本**。

> **Note(一種への伏線)**: 瞬時電力一定性は「三相平衡かつ負荷対称」のとき成立。不平衡・非正弦波(高調波含む)では破れる。高調波次数 $h$ に対し、零相成分($h = 3, 6, 9, \ldots$)と正相/逆相成分($h \ne 3k$)で挙動が異なる — これが一種電力で扱う**高調波解析**の出発点。

## 3. 例題

**問**: Y 結線平衡負荷、相インピーダンス $\dot Z = 6 + j8\,\Omega$、線間電圧 $V_L = 200$ V。三相合計の有効電力・無効電力を求めよ。

**解**: 相電圧 $V_p = 200/\sqrt 3$、相電流 $I_p = V_p/|\dot Z| = 200/(10\sqrt 3) = 20/\sqrt 3$ A。力率 $\cos\theta = 6/10 = 0.6$、$\sin\theta = 0.8$。
$$
P_{3\phi} = 3 V_p I_p\cos\theta = 3 \cdot \frac{200}{\sqrt 3}\cdot\frac{20}{\sqrt 3}\cdot 0.6 = 3\cdot\frac{4000}{3}\cdot 0.6 = 2400 \text{ W}.
$$
同様に $Q_{3\phi} = 2400\cdot(0.8/0.6) = 3200$ var。検算: $\sqrt 3 V_L I_L\cos\theta = \sqrt 3 \cdot 200 \cdot (20/\sqrt 3)\cdot 0.6 = 200\cdot 20\cdot 0.6 = 2400$。✓

## 4. ミニ確認問

三相 Δ 結線平衡負荷、相インピーダンス $\dot Z = 8 - j6\,\Omega$(容量性)、線間電圧 $V_L = 400$ V。三相合計の有効電力と無効電力(符号含む)を求めよ。

<details>
<summary>解答</summary>

Δ なので相電圧 = 線間電圧 = 400 V、相電流 $I_p = 400/10 = 40$ A、線電流 $I_L = 40\sqrt 3$ A。
力率角 $\theta = \arctan(-6/8) = -36.87^\circ$、$\cos\theta = 0.8$、$\sin\theta = -0.6$。

$P_{3\phi} = 3 V_p I_p\cos\theta = 3\cdot 400\cdot 40\cdot 0.8 = 38\,400$ W = 38.4 kW。
$Q_{3\phi} = 3 V_p I_p\sin\theta = -28\,800$ var = $-28.8$ kvar(容量性で $Q<0$、無効電力を**供給**している側)。

</details>

## 5. 次セクションへの接続

三相電力の合計式と瞬時電力一定性を確立した。次節 [`05-balanced-circuits.md`](./05-balanced-circuits.md) では、これらの結果を使って**平衡三相回路を 1 相分等価に還元**する解法を定式化する。3 相フル回路を書かずに「a 相だけ」で全情報が取れる理由を、中性点の対称性から丁寧に押さえる。
