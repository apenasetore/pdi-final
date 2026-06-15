# Projeto Final — Segmentação de artérias em Doppler colorido

Disciplina IF69D (PDI). O objetivo é **segmentar os vasos a partir da imagem
Doppler colorida** — como se só houvesse a figura na tela, sem acesso ao campo de
velocidade bruto — e avaliar a precisão contra um *ground truth*.

Os dados vêm de simulações de ultrassom Doppler (toolbox MUST) sobre os phantoms
em `imgs/phantom` (vasos azuis e vermelhos sobre fundo preto, 128×128). Cada
`vd_signals/vd_signals_XX.mat` guarda o mapa Doppler de velocidade `Data`
(256×256, m/s, `NaN` fora do feixe), cobrindo x ∈ [−12.8, 12.8] mm — o dobro da
largura do phantom (x ∈ [−6.4, 6.4] mm), por isso o método recorta as colunas
centrais antes de comparar.

## Método

A entrada é convertida numa **imagem colorida** (mapa `jet`) e o vaso azul
(fluxo se afastando da sonda) é segmentado por **quatro métodos**, todos partindo
da mesma imagem renderizada e com o mesmo pré/pós-processamento — a comparação
isola apenas o passo de segmentação:

1. **RGB + Otsu** (Aula 08/09) — azulidade = `max(0, (B − max(R,G))/255)`, limiar de Otsu.
2. **HSV + Otsu** (Aula 09) — azulidade = `max(0, 1 − |H − 0.62|/0.15) · S`, limiar de Otsu.
3. **K-means** (Aula 10) — `imsegkmeans` no espaço Lab (K=3); escolhe automaticamente o cluster de maior azulidade média.
4. **SLIC** (Aula 10) — `superpixels` + Otsu sobre a azulidade média de cada superpixel.

Pipeline padronizado (em `segment_doppler.m`):
recorte das colunas centrais (FOV do phantom) → render `jet` 128×128 →
**pré-suavização Gaussiana opcional** (Aula 04) → segmentação → **pós-processamento
comum** (Aula 08): `imopen`/`imclose`, `imfill`, `bwareaopen`, `bwareafilt` (mantém
os maiores componentes conexos). O Otsu é aplicado **só sobre os pixels não-nulos**
(evita o colapso do limiar num fundo quase todo zero).

## Arquivos

- `doppler_to_rgb.m` — renderização comum: VD → imagem `jet` 128×128 (uint8).
- `segment_doppler.m` — função: VD → struct de máscaras (`rgb`, `hsv`, `kmeans`, `slic`); aceita `opt` (suavização, pós-processamento, K, nº de superpixels).
- `otsu_hue_rgb_seg.m` — demo de 1 imagem (Original | os 4 métodos).
- `make_ground_truth.m` — phantom: azul → branco, resto → preto → `imgs/ground_truth/gt_XX.png`.
- `eval_methods.m` — avaliação padronizada dos 4 métodos contra o ground truth nos 20 casos.

## Como rodar (MATLAB, na pasta ProjetoFinal)

```matlab
make_ground_truth     % gera os gt_XX.png a partir dos phantoms
eval_methods          % segmenta os 20 casos e avalia contra o GT
```

Saídas de `eval_methods`:
- `comparison_methods.csv` — Dice, IoU, precisão e revocação de cada método por simulação;
- tabela-resumo (médias por método) e **veredito** no console (melhor por Dice médio + nº de vitórias por imagem);
- `imgs/compare_methods/cmp_XX.png` — por caso: Doppler | Ground truth | **mapa de erro** de cada método (verde = acerto, vermelho = falso-positivo, azul = falso-negativo);
- `imgs/compare_methods/summary.png` — barras das métricas médias por método + **heatmap** de Dice por simulação×método.

Requer a Image Processing Toolbox (`graythresh`, `rgb2hsv`, `imsegkmeans`,
`superpixels`, `imgaussfilt`, `bwareafilt`, `dice`, `jaccard`, `imresize`).
