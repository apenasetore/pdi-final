function RGB = doppler_to_rgb(VD)
%DOPPLER_TO_RGB  Renderiza o mapa Doppler de velocidade como imagem colorida.
%   RGB = DOPPLER_TO_RGB(VD) recebe o mapa Doppler VD (velocidade, m/s, com
%   NaN fora do feixe), recorta o FOV central (as colunas que correspondem ao
%   phantom/ground truth) e o transforma numa imagem RGB 128x128 (uint8)
%   replicando o PlotDoppler do TCC: imagesc + caxis([-m m]) + dopplermap.
%   No dopplermap, velocidade ~0 vira PRETO (fundo), fluxo negativo (afastando)
%   vira azul/ciano e positivo (aproximando) vira vermelho/amarelo.
%
%   Esta etapa e COMUM a todos os metodos de segmentacao, garantindo que a
%   comparacao entre eles isole apenas o passo de segmentacao.

    VD(isnan(VD)) = 0;

    % --- recorte do FOV do phantom: colunas centrais (50%) ---
    % O VD cobre x em [-12.8,12.8] mm, mas o phantom/GT cobre [-6.4,6.4] mm.
    G = size(VD,2);
    c0 = round(G/4) + 1;
    c1 = round(3*G/4);
    VD = VD(:, c0:c1);

    % --- render VD -> imagem colorida (caxis + dopplermap) ---
    m = round(max(abs(VD(:))), 2);
    if m == 0, m = 0.01; end
    VD_clip = max(VD, -m);                       % satura em [-m, m] (= caxis)
    idx = round(1 + 255*(VD_clip + m)/(2*m));    % mapeia [-m, m] -> [1, 256]

    RGB = ind2rgb(idx, dopplermap(256));         % double [0,1]
    RGB = imresize(RGB, [128 128]);
    RGB = im2uint8(RGB);
end
