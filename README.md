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
(fluxo se afastando da sonda) é segmentado por dois caminhos, comparados entre si:

1. **RGB + Otsu** — azulidade = `max(0, (B − max(R,G))/255)`, limiarizada por Otsu.
2. **HSV + Otsu** — azulidade = `max(0, 1 − |H − 0.62|/0.15) · S`, limiarizada por Otsu.

Pré/pós-processamento comum aos dois (única diferença = o espaço de cor):
recorte das colunas centrais (FOV do phantom) → render `jet` 128×128 → Otsu
aplicado **só sobre os pixels não-nulos** (evita o colapso do limiar num fundo
quase todo zero).

## Arquivos

- `seg_doppler_image.m` — função: VD → máscaras `BW_rgb` e `BW_hsv` (128×128).
- `otsu_hue_rgb_seg.m` — demo de 1 imagem (Original | RGB | HSV).
- `make_ground_truth.m` — phantom: azul → branco, resto → preto → `imgs/ground_truth/gt_XX.png`.
- `compare_hsv_rgb.m` — compara RGB vs HSV contra o ground truth nos 20 casos.

## Como rodar (MATLAB, na pasta ProjetoFinal)

```matlab
make_ground_truth     % gera os gt_XX.png a partir dos phantoms
compare_hsv_rgb       % segmenta os 20 casos e avalia contra o GT
```

Saídas de `compare_hsv_rgb`:
- `comparison_hsv_rgb.csv` — Dice, IoU, precisão e revocação (RGB e HSV) por simulação;
- veredito no console (qual método vence em Dice/IoU médios);
- `imgs/compare_methods/cmp_XX.png` — painéis Ground truth | RGB | HSV.

Requer a Image Processing Toolbox (`graythresh`, `imbinarize`, `rgb2hsv`, `imresize`).
