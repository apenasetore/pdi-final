%----------------------------------------------------------
% EVAL_METHODS
% Avaliacao PADRONIZADA dos metodos de segmentacao da imagem Doppler.
% Todos os metodos partem da mesma imagem renderizada, passam pelo mesmo
% pre/pos-processamento (definidos em segment_doppler) e sao medidos pelas
% mesmas metricas contra o mesmo ground truth -- isolando o passo de
% segmentacao para decidir, de forma justa, qual e o melhor.
%
% Metricas (Aula 05), com funcoes nativas: Dice (dice), IoU (jaccard),
% alem de precisao e revocacao a partir de TP/FP/FN.
%
% Saidas:
%   - comparison_methods.csv  (uma linha por simulacao e metodo)
%   - tabela-resumo por metodo (medias) no console
%   - veredito (melhor por Dice medio e nº de vitorias por imagem)
%   - paineis imgs/compare_methods/cmp_XX.png: Doppler | GT | mapa de erro de
%     cada metodo (verde=acerto, vermelho=falso+, azul=falso-)
%   - imgs/compare_methods/summary.png: barras das metricas medias + heatmap
%     de Dice por simulacao x metodo
%
% Rodar APOS make_ground_truth.m, com o MATLAB na pasta ProjetoFinal.
%----------------------------------------------------------

clc; clear; close all;

vddir = 'vd_signals';
gtdir = fullfile('imgs','ground_truth');
ovdir = fullfile('imgs','compare_methods');
if ~exist(ovdir,'dir'), mkdir(ovdir); end

% --- metodos avaliados (campo em masks, rotulo) -- facil de estender ---
methods = {'dist','Distancai_Euclidiana'; 'kmeans','K-means';};
nm = size(methods,1);

% --- opcoes padronizadas aplicadas a TODOS os metodos ---
opt.smooth      = 0;      % sigma do pre-filtro Gaussiano (0 = desligado)
opt.postprocess = true;   % morfologia + componentes conexos
opt.kClusters   = 3;
opt.nSuperpixels= 200;

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
    t = tiledlayout(fig,1,nm+2,'TileSpacing','compact','Padding','compact');
    title(t,sprintf('Simulacao %02d   (verde=acerto  vermelho=falso+  azul=falso-)',idx(i)), ...
        'FontWeight','bold');
    nexttile; imshow(RGB); title('Doppler');
    nexttile; imshow(gt);  title('Ground truth');
    for j = 1:nm
        nexttile; imshow(error_overlay(masks.(methods{j,1}), gt));
        title(sprintf('%s  (Dice %.2f / IoU %.2f)', methods{j,2}, dice(i,j), iou(i,j)));
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

% --- figura-resumo: barras das medias + heatmap de Dice por caso ---
fig = figure('Color','w','Visible','off','Position',[100 100 1100 440]);
t = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
title(t,'Resumo da comparacao entre metodos','FontWeight','bold');

% barras agrupadas: cada metodo com Dice/IoU/Prec/Rec medios
nexttile;
means = [mean(dice)' mean(iou)' mean(prec)' mean(rec)'];   % nm x 4
b = bar(means);
set(gca,'XTickLabel',methods(:,2));
ylim([0 1]); grid on;
ylabel('valor medio'); title('Metricas medias por metodo');
legend({'Dice','IoU','Precisao','Revocacao'},'Location','southoutside','Orientation','horizontal');

% heatmap: Dice por simulacao (linhas) x metodo (colunas)
nexttile;
imagesc(dice, [0 1]);
colormap(gca, parula); colorbar;
set(gca,'XTick',1:nm,'XTickLabel',methods(:,2));
set(gca,'YTick',1:n,'YTickLabel',compose('%02d',idx));
xlabel('metodo'); ylabel('simulacao');
title('Dice por simulacao (mais claro = melhor)');

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
