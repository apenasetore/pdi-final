function [BW_rgb, BW_hsv, RGB] = seg_doppler_image(VD)
%SEG_DOPPLER_IMAGE  Segmenta o vaso azul na imagem Doppler (RGB e HSV).
%   [BW_rgb, BW_hsv, RGB] = SEG_DOPPLER_IMAGE(VD) recebe o mapa Doppler de
%   velocidade VD, renderiza uma imagem colorida 128x128 (colormap jet) e
%   segmenta o "azul" (fluxo se afastando da sonda) por dois caminhos:
%   azulidade no espaco RGB e no espaco HSV, cada um limiarizado por Otsu.
%
%   A ideia do projeto e segmentar a IMAGEM (como se so houvesse a figura),
%   por isso a entrada VD e convertida para cor antes de segmentar.
%
%   Saidas:
%     BW_rgb - mascara logica 128x128 (metodo RGB + Otsu)
%     BW_hsv - mascara logica 128x128 (metodo HSV + Otsu)
%     RGB    - imagem Doppler renderizada (uint8, 128x128x3)

    VD(isnan(VD)) = 0;

    % --- recorte do FOV do phantom: colunas centrais (50%) ---
    % O VD cobre x em [-12.8,12.8] mm, mas o phantom/GT cobre [-6.4,6.4] mm.
    G = size(VD,2);
    c0 = round(G/4) + 1;
    c1 = round(3*G/4);
    VD = VD(:, c0:c1);

    % --- render VD -> imagem colorida (replica imagesc + caxis + jet) ---
    m = round(max(abs(VD(:))), 2);
    if m == 0, m = 0.01; end
    VD_clip = min(max(VD, -m), m);              % satura em [-m, m] (= caxis)
    idx = round(1 + 255*(VD_clip + m)/(2*m));   % mapeia [-m, m] -> [1, 256]

    RGB = ind2rgb(idx, jet(256));               % double [0,1]
    RGB = imresize(RGB, [128 128]);
    RGB = im2uint8(RGB);

    % --- metodo RGB: azulidade = quanto B domina sobre R e G ---
    Rd = double(RGB(:,:,1));
    Gd = double(RGB(:,:,2));
    Bd = double(RGB(:,:,3));
    blueness_rgb = max(0, (Bd - max(Rd, Gd)) / 255);
    BW_rgb = otsu_nonzero(blueness_rgb);

    % --- metodo HSV: proximidade do Hue ao azul do jet, ponderada por S ---
    HSV = rgb2hsv(im2double(RGB));
    H = HSV(:,:,1);
    S = HSV(:,:,2);
    blue_hue = 0.62;
    tol = 0.15;
    blueness_hsv = max(0, 1 - abs(H - blue_hue)/tol) .* S;
    BW_hsv = otsu_nonzero(blueness_hsv);
end

%----------------------------------------------------------
function BW = otsu_nonzero(feat)
%OTSU_NONZERO  Otsu sobre os pixels nao-nulos da feature.
%   Evita o colapso do limiar quando ~97% da imagem e fundo zero: o Otsu
%   global colocaria o limiar perto de 0 e pegaria ruido. Aqui o limiar e
%   calculado so onde ha sinal, e depois aplicado a imagem inteira.
    nz = feat(feat > 0);
    if isempty(nz)
        BW = false(size(feat));
        return;
    end
    vmax = max(nz);
    t = graythresh(nz / vmax) * vmax;   % limiar de Otsu nas escalas reais
    BW = feat > t;
end
