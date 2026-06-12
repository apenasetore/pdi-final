%----------------------------------------------------------
% MAKE_GROUND_TRUTH
% Gera as mascaras de referencia a partir dos phantoms:
% pixels azuis (vasos com fluxo se afastando da sonda) viram
% branco e todo o resto (fundo e vasos vermelhos) vira preto.
% Salva em imgs/ground_truth/gt_XX.png (128x128, binario).
%----------------------------------------------------------

clc; clear; close all;

indir  = fullfile('imgs','phantom');
outdir = fullfile('imgs','ground_truth');
if ~exist(outdir,'dir'), mkdir(outdir); end

L = dir(fullfile(indir,'vessels_*.png'));

for i = 1:numel(L)
    idx = sscanf(L(i).name,'vessels_%d.png');
    I = imread(fullfile(indir,L(i).name));

    R = double(I(:,:,1));
    G = double(I(:,:,2));
    B = double(I(:,:,3));

    % azul: canal B alto e dominante sobre R e G
    mask = B > 128 & B > R + 50 & B > G + 50;

    gt = uint8(mask)*255;
    outname = fullfile(outdir,sprintf('gt_%02d.png',idx));
    imwrite(gt,outname);
    fprintf('Salvo %s (%d pixels de vaso)\n',outname,nnz(mask));
end

fprintf('\n%d ground truths salvos em %s\n',numel(L),outdir);
