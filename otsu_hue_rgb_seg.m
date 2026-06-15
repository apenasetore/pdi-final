%----------------------------------------------------------
% OTSU_HUE_RGB_SEG  (demo de 1 imagem)
% Renderiza um mapa Doppler para imagem colorida e segmenta o vaso azul
% pelos quatro metodos (RGB+Otsu, HSV+Otsu, K-means, SLIC).
% A logica esta em segment_doppler.m (reutilizada por eval_methods.m).
%
% Rodar com o MATLAB na pasta ProjetoFinal.
%----------------------------------------------------------

clc; clear; close all;

file = fullfile('vd_signals','vd_signals_01.mat');
data = load(file);

[masks, RGB] = segment_doppler(data.Data);

methods = {'rgb','RGB + Otsu'; 'hsv','HSV + Otsu'; 'kmeans','K-means'; 'slic','SLIC'};
nm = size(methods,1);

figure('Color','w', 'Position',[100 100 320*(nm+1) 320]);
subplot(1,nm+1,1); imshow(RGB); title('Original (Doppler)');
for j = 1:nm
    subplot(1,nm+1,j+1);
    imshow(masks.(methods{j,1}));
    title(methods{j,2});
end

total = numel(RGB(:,:,1));
fprintf('=== Area segmentada por metodo (1 imagem) ===\n');
for j = 1:nm
    a = nnz(masks.(methods{j,1}));
    fprintf('%-12s: %5d px (%.1f%%)\n', methods{j,2}, a, 100*a/total);
end
