

clc; clear; close all;

vddir = 'vd_signals';
gtdir = fullfile('imgs','ground_truth');
ovdir = fullfile('imgs','compare_methods');
if ~exist(ovdir,'dir'), mkdir(ovdir); end

% --- metodos avaliados (campo em masks, rotulo) -- facil de estender ---
methods = {'dist','Distancai_Euclidiana'; 'kmeans','K-means';};
nm = size(methods,1);

% --- opcoes padronizadas aplicadas a TODOS os metodos ---
opt.smooth      = 0.4;      % sigma do pre-filtro Gaussiano (0 = desligado)
opt.kClusters   = 5;

L = dir(fullfile(vddir,'vd_signals_*.mat'));
n = numel(L);
if n == 0, error('Nenhum vd_signals_*.mat encontrado em %s', vddir); end

% acumuladores (n simulacoes x nm metodos)
idx  = zeros(n,1);
dice = zeros(n,nm); iou = zeros(n,nm); prec = zeros(n,nm); rec = zeros(n,nm);

for i = 1:n
    idx(i) = sscanf(L(i).name,'vd_signals_%d.mat');

    data = load(fullfile(vddir,L(i).name));
    [masks, RGB] = segment_doppler(data.Data, opt);

    gtfile = fullfile(gtdir,sprintf('gt_%02d.png',idx(i)));
    if ~exist(gtfile,'file')
        error('Ground truth %s nao encontrado. Rode make_ground_truth.m antes.',gtfile);
    end
    gt = imread(gtfile) > 127;

    for j = 1:nm
        BW = masks.(methods{j,1});
        [dice(i,j),iou(i,j),prec(i,j),rec(i,j)] = metrics(BW,gt);
    end

    % painel: Doppler | GT | mapas de erro por metodo
    % (verde = acerto, vermelho = falso positivo, azul = falso negativo)
    fig = figure('Color','w','Visible','off','Position',[100 100 300*(nm+2) 360]);
    try, theme(fig,'light'); catch, end          % evita tema escuro (texto branco)
    t = tiledlayout(fig,1,nm+2,'TileSpacing','compact','Padding','compact');
    title(t,sprintf('Simulacao %02d   (verde=acerto  vermelho=falso+  azul=falso-)',idx(i)), ...
        'FontWeight','bold','Color','k');
    nexttile; imshow(RGB); title('Doppler','Color','k');
    nexttile; imshow(gt);  title('Ground truth','Color','k');
    for j = 1:nm
        nexttile; imshow(error_overlay(masks.(methods{j,1}), gt));
        title(sprintf('%s  (Dice %.2f / IoU %.2f)', methods{j,2}, dice(i,j), iou(i,j)), ...
            'Color','k');
    end
    exportgraphics(fig,fullfile(ovdir,sprintf('cmp_%02d.png',idx(i))),'Resolution',130);
    close(fig);
end

% --- CSV por caso (formato largo: simulacao + metricas de cada metodo) ---
T = table(idx,'VariableNames',{'simulacao'});
for j = 1:nm
    lab = methods{j,2};
    T.(matlab.lang.makeValidName(['Dice_' lab])) = dice(:,j);
    T.(matlab.lang.makeValidName(['IoU_'  lab])) = iou(:,j);
    T.(matlab.lang.makeValidName(['Prec_' lab])) = prec(:,j);
    T.(matlab.lang.makeValidName(['Rec_'  lab])) = rec(:,j);
end
writetable(T,'comparison_methods.csv');

% --- tabela-resumo por metodo (medias) ---
Resumo = table(methods(:,2), mean(dice)', mean(iou)', mean(prec)', mean(rec)', ...
    'VariableNames',{'Metodo','Dice','IoU','Precisao','Revocacao'});
fprintf('\n=== Resumo (medias sobre %d simulacoes) ===\n', n);
disp(Resumo);

% --- veredito ---
[~, best] = max(mean(dice));
[~, dom]  = max(dice, [], 2);              % metodo vencedor por imagem
fprintf('=== Veredito ===\n');
fprintf('Melhor metodo (Dice medio): %s  (%.3f)\n', methods{best,2}, mean(dice(:,best)));
for j = 1:nm
    fprintf('  %-8s venceu em %2d de %d imagens\n', methods{j,2}, nnz(dom==j), n);
end

% --- figura-resumo: barras das metricas medias por metodo ---
fig = figure('Color','w','Visible','off','Position',[100 100 700 440]);
try, theme(fig,'light'); catch, end              % evita tema escuro (texto branco)
ax = axes(fig);
means = [mean(dice)' mean(iou)' mean(prec)' mean(rec)'];   % nm x 4
bar(ax, means);
set(ax,'XTickLabel',methods(:,2),'XColor','k','YColor','k');
ylim(ax,[0 1]); grid(ax,'on');
ylabel(ax,'valor medio','Color','k');
title(ax,'Metricas medias por metodo','Color','k');
lgd = legend(ax,{'Dice','IoU','Precisao','Revocacao'}, ...
    'Location','southoutside','Orientation','horizontal');
set(lgd,'TextColor','k');

exportgraphics(fig,fullfile(ovdir,'summary.png'),'Resolution',130);
close(fig);

fprintf('\nCSV em comparison_methods.csv | paineis em %s | resumo em %s\n', ...
    ovdir, fullfile(ovdir,'summary.png'));

%----------------------------------------------------------
function rgb = error_overlay(BW, gt)
% Mapa de erro colorido: verde = verdadeiro positivo, vermelho = falso
% positivo (sobre-segmentou), azul = falso negativo (perdeu vaso).
    R = zeros(size(BW)); G = R; B = R;
    G(BW & gt)  = 1;     % TP
    R(BW & ~gt) = 1;     % FP
    B(~BW & gt) = 1;     % FN
    rgb = cat(3, R, G, B);
end

%----------------------------------------------------------
function [dice,iou,prec,rec] = metrics(BW,gt)
% Dice e IoU com funcoes nativas (Aula 05); precisao/revocacao via TP/FP/FN.
    if any(BW(:)) || any(gt(:))
        dice = dice_safe(BW,gt);
        iou  = jaccard_safe(BW,gt);
    else
        dice = 1; iou = 1;   % ambos vazios = concordancia total
    end
    TP = nnz(BW & gt);
    FP = nnz(BW & ~gt);
    FN = nnz(~BW & gt);
    prec = TP/max(TP+FP,1);
    rec  = TP/max(TP+FN,1);
end

function d = dice_safe(BW,gt)
    if ~any(BW(:)) && ~any(gt(:)), d = 1; return; end
    d = dice(BW,gt);            % nativa (Image Processing Toolbox)
end

function j = jaccard_safe(BW,gt)
    if ~any(BW(:)) && ~any(gt(:)), j = 1; return; end
    j = jaccard(BW,gt);         % nativa (Image Processing Toolbox)
end
