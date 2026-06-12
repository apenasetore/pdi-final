%----------------------------------------------------------
% OTSU_HUE_RGB_SEG  (demo de 1 imagem)
% Renderiza um mapa Doppler para imagem colorida e segmenta o vaso azul
% por dois caminhos: azulidade no RGB e no HSV, cada um com Otsu.
% A logica esta em seg_doppler_image.m (reutilizada por compare_hsv_rgb.m).
%
% Rodar com o MATLAB na pasta ProjetoFinal.
%----------------------------------------------------------

clear; close all; clc;

file = fullfile('vd_signals','vd_signals_01.mat');
data = load(file);
VD = data.Data;

[BW_rgb, BW_hsv, RGB] = seg_doppler_image(VD);

figure('Color','w', 'Position',[100 100 1200 400]);

subplot(1,3,1);
imshow(RGB);
title("Original (Doppler)");

subplot(1,3,2);
imshow(BW_rgb);
title("Azul via RGB + Otsu");

subplot(1,3,3);
imshow(BW_hsv);
title("Azul via HSV + Otsu");

area_rgb = sum(BW_rgb(:));
area_hsv = sum(BW_hsv(:));
total = numel(BW_rgb);

fprintf("=== Comparacao das tecnicas (1 imagem) ===\n");
fprintf("Area azul (RGB): %d px (%.1f%%)\n", area_rgb, 100*area_rgb/total);
fprintf("Area azul (HSV): %d px (%.1f%%)\n", area_hsv, 100*area_hsv/total);

% Concordancia entre as mascaras (IoU)
inter = sum(BW_rgb(:) & BW_hsv(:));
uni   = sum(BW_rgb(:) | BW_hsv(:));
if uni > 0
    fprintf("IoU entre as mascaras RGB x HSV: %.2f\n", inter/uni);
end
