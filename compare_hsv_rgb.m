%----------------------------------------------------------
% COMPARE_HSV_RGB
% Compara, contra o ground truth, os dois metodos de segmentacao da
% imagem Doppler (azulidade RGB+Otsu vs HSV+Otsu) nos 20 casos.
%
% Para cada vd_signals_XX.mat:
%   - segmenta com seg_doppler_image (RGB e HSV)
%   - compara cada mascara com imgs/ground_truth/gt_XX.png
%     (Dice, IoU, precisao, revocacao)
%
% Saidas:
%   - tabela no console + comparison_hsv_rgb.csv
%   - veredito (qual metodo vence em Dice/IoU medios)
%   - paineis imgs/compare_methods/cmp_XX.png (GT | RGB | HSV)
%
% Rodar APOS make_ground_truth.m, com o MATLAB na pasta ProjetoFinal.
%----------------------------------------------------------

clc; clear; close all;

vddir = 'vd_signals';
gtdir = fullfile('imgs','ground_truth');
ovdir = fullfile('imgs','compare_methods');
if ~exist(ovdir,'dir'), mkdir(ovdir); end

L = dir(fullfile(vddir,'vd_signals_*.mat'));
n = numel(L);
if n == 0, error('Nenhum vd_signals_*.mat encontrado em %s', vddir); end

idx = zeros(n,1);
dice_rgb = zeros(n,1); iou_rgb = zeros(n,1); prec_rgb = zeros(n,1); rec_rgb = zeros(n,1);
dice_hsv = zeros(n,1); iou_hsv = zeros(n,1); prec_hsv = zeros(n,1); rec_hsv = zeros(n,1);

for i = 1:n
    idx(i) = sscanf(L(i).name,'vd_signals_%d.mat');

    data = load(fullfile(vddir,L(i).name));
    [BW_rgb, BW_hsv] = seg_doppler_image(data.Data);

    gtfile = fullfile(gtdir,sprintf('gt_%02d.png',idx(i)));
    if ~exist(gtfile,'file')
        error('Ground truth %s nao encontrado. Rode make_ground_truth.m antes.',gtfile);
    end
    gt = imread(gtfile) > 127;

    [dice_rgb(i),iou_rgb(i),prec_rgb(i),rec_rgb(i)] = metrics(BW_rgb,gt);
    [dice_hsv(i),iou_hsv(i),prec_hsv(i),rec_hsv(i)] = metrics(BW_hsv,gt);

    % painel GT | RGB | HSV
    fig = figure('Color','w','Visible','off','Position',[100 100 900 320]);
    t = tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
    title(t,sprintf('Simulacao %02d',idx(i)),'FontWeight','bold');
    nexttile; imshow(gt);     title('Ground truth');
    nexttile; imshow(BW_rgb); title(sprintf('RGB  (Dice %.2f)',dice_rgb(i)));
    nexttile; imshow(BW_hsv); title(sprintf('HSV  (Dice %.2f)',dice_hsv(i)));
    exportgraphics(fig,fullfile(ovdir,sprintf('cmp_%02d.png',idx(i))),'Resolution',130);
    close(fig);
end

T = table(idx, ...
    dice_rgb, iou_rgb, prec_rgb, rec_rgb, ...
    dice_hsv, iou_hsv, prec_hsv, rec_hsv, ...
    'VariableNames',{'simulacao', ...
        'Dice_RGB','IoU_RGB','Prec_RGB','Rec_RGB', ...
        'Dice_HSV','IoU_HSV','Prec_HSV','Rec_HSV'});
disp(T);

fprintf('\n=== Medias ===\n');
fprintf('RGB:  Dice %.3f | IoU %.3f | Prec %.3f | Rec %.3f\n', ...
    mean(dice_rgb),mean(iou_rgb),mean(prec_rgb),mean(rec_rgb));
fprintf('HSV:  Dice %.3f | IoU %.3f | Prec %.3f | Rec %.3f\n', ...
    mean(dice_hsv),mean(iou_hsv),mean(prec_hsv),mean(rec_hsv));

dDice = mean(dice_hsv) - mean(dice_rgb);
dIoU  = mean(iou_hsv)  - mean(iou_rgb);
if dDice > 0
    melhor = 'HSV';
else
    melhor = 'RGB';
end
fprintf('\n=== Veredito ===\n');
fprintf('Metodo melhor (Dice medio): %s  (diferenca %.3f em Dice, %.3f em IoU)\n', ...
    melhor, abs(dDice), abs(dIoU));
nwin_hsv = nnz(dice_hsv > dice_rgb);
fprintf('HSV venceu em %d de %d imagens (Dice por imagem).\n', nwin_hsv, n);

writetable(T,'comparison_hsv_rgb.csv');
fprintf('\nTabela salva em comparison_hsv_rgb.csv e paineis em %s\n',ovdir);

%----------------------------------------------------------
function [dice,iou,prec,rec] = metrics(BW,gt)
    TP = nnz(BW & gt);
    FP = nnz(BW & ~gt);
    FN = nnz(~BW & gt);
    dice = 2*TP/max(2*TP+FP+FN,1);
    iou  = TP/max(TP+FP+FN,1);
    prec = TP/max(TP+FP,1);
    rec  = TP/max(TP+FN,1);
end
