# Segmentação de Vasos em Doppler Colorido

Projeto final da disciplina **IF69D — Processamento Digital de Imagens (PDI)**, UTFPR
(Prof. Gustavo B. Borba).

**Autores:** Étore Maloso Tronconi e Henrique Gomes Pinto Bubniak.

## Objetivo

Segmentar o **vaso azul** — fluxo se afastando da sonda — em imagens de **Doppler
colorido** geradas por simulação, e comparar duas abordagens clássicas de
segmentação por cor avaliando-as contra um *ground truth*.

A base é composta por 15 casos simulados (numerados `01`..`15`) de phantoms
vasculares 128×128, produzidos com o [MUST (Matlab UltraSound Toolbox)](https://www.biomecardio.com/MUST/).

## Métodos comparados

Ambos partem da mesma imagem RGB renderizada e do mesmo pré-filtro Gaussiano,
padronizados em `segment_doppler.m`:

1. **Distância Euclidiana + Otsu** (`euclidia_limiar`)
   Calcula a média interquartil de uma amostra de referência (`sample.png`) e
   limiariza a distância de cor de cada pixel a essa cor por Otsu (`graythresh`).
   Limitação: uma cor única não separa bem o azul do fundo/vermelho.

2. **K-means** (`seg_kmeans`, via `imsegkmeans`, K=3)
   Agrupa os pixels em K clusters e seleciona o cluster mais próximo da cor-alvo.
   Mais robusto e, em geral, com melhor Dice/IoU.

A avaliação (`eval_methods.m`) calcula **Dice**, **IoU**, **Precisão** e **Recall**
por imagem, gera painéis de mapa de erro (verde = acerto, vermelho = falso
positivo, azul = falso negativo) e um resumo com as médias por método. O K-means
apresenta o melhor desempenho médio na maioria dos casos.

## Estrutura do repositório

```
.
├── segment_doppler.m      # pipeline de segmentação (os dois métodos)
├── doppler_to_rgb.m       # converte sinal Doppler (VD) em imagem RGB
├── dopplermap.m           # colormap Doppler do MUST (Damien Garcia, LGPL-3.0)
├── make_ground_truth.m    # gera as máscaras de referência a partir dos phantoms
├── eval_methods.m         # executa e avalia os métodos, gera painéis e resumo
├── sample.png             # amostra de cor-alvo (azul) usada na limiarização
├── vd_signals/            # sinais Doppler simulados (vd_signals_01..15.mat)
├── imgs/
│   ├── phantom/           # phantoms de entrada (vessels_01..15.png)
│   ├── ground_truth/      # máscaras de referência (gt_01..15.png)
│   └── compare_methods/   # saídas: painéis cmp_XX.png e summary.png
├── relatorio_pdi_final.pdf
└── apresentacao.pdf
```

## Como executar

Requer MATLAB com a **Image Processing Toolbox** (`imsegkmeans`, `dice`,
`jaccard`, `graythresh`).

```matlab
% (opcional) regerar as máscaras de referência a partir dos phantoms
make_ground_truth

% executar e avaliar os dois métodos sobre os 15 casos
eval_methods
```

Os painéis de comparação e o gráfico-resumo são salvos em
`imgs/compare_methods/`.

## Créditos

`dopplermap.m` faz parte do MUST (Matlab UltraSound Toolbox), © 2020 Damien
Garcia, licença LGPL-3.0-or-later.
