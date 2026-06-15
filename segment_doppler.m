function [masks, RGB] = segment_doppler(VD, opt)
    if nargin < 2, opt = struct(); end
    if ~isfield(opt,'smooth'),       opt.smooth = 0.4;          end
    if ~isfield(opt,'postprocess'),  opt.postprocess = true;  end
    if ~isfield(opt,'kClusters'),    opt.kClusters = 3;       end
    if ~isfield(opt,'nSuperpixels'), opt.nSuperpixels = 200;  end

    RGB = doppler_to_rgb(VD);

    % --- pre-processamento gauss  --- %
    if opt.smooth > 0
        RGBp = im2uint8(imgaussfilt(im2double(RGB), opt.smooth));
    else
        RGBp = RGB;
    end
    % -- blue sample ---
    sample = imread("sample.png");
    % --- roda os metodos sobre a mesma imagem ---
    [masks.dist, Dm] = euclidia_limiar(RGBp,sample);
    masks.kmeans = seg_kmeans(RGBp, Dm,opt.kClusters);

    % --- pos-processamento comum (Aula 08) ---
    if opt.postprocess
        for f = fieldnames(masks)'
            masks.(f{1}) = postprocess_mask(masks.(f{1}));
        end
    end
end

%==========================================================================
function b = blueness_rgb(RGB)
    Rd = double(RGB(:,:,1));
    Gd = double(RGB(:,:,2));
    Bd = double(RGB(:,:,3));
    b = max(0, (Bd - max(Rd, Gd)) / 255);
end



%============================================================
% Segmentação por limiarização utilizando a distância Euclidiana
% from color_17.m[script]
function [R, Dm]= euclidia_limiar(RGB,sample)
    
    nr = size(RGB,1);
    nc = size(RGB,2);
    lab = RGB;
    % sample = rgb2lab(sample);
    % Color channel 1 da amostra
    sample_ch1 = sample(:,:,1);
    sample_ch1_v = sort(sample_ch1(:));
    % Interquartile mean do channel 1 da amostra
    N = length(sample_ch1_v); qL = round(N/4); qH = round(N/4*3);
    ch1_iqm = mean(sample_ch1_v(qL:qH));
    % Color channel 2 da amostra
    sample_ch2 = sample(:,:,2);
    sample_ch2_v = sort(sample_ch2(:));
    % Interquartile mean do channel 2 da amostra
    ch2_iqm = mean(sample_ch2_v(qL:qH));
    % Color channel 3 da amostra
    sample_ch3 = sample(:,:,3);
    sample_ch3_v = sort(sample_ch3(:));
    % Interquartile mean do channel 3 da amostra
    ch3_iqm = mean(sample_ch3_v(qL:qH));

    img_iqm = [ch1_iqm ch2_iqm ch3_iqm];
    img_iqm = repmat(img_iqm, nr*nc, 1);
    img_cols = reshape(lab, nr*nc, 3);
    img_cols = double(img_cols);
    s = (img_iqm - img_cols).^2;
    D = sqrt(sum(s,2));
    
    Dm = reshape(D,nr,nc);
    
    dmax = max(Dm(:));
    t = graythresh(Dm/dmax) * dmax; 
    R = Dm < t;
    %figure, imshow(R), title(['Segmentação usando dist Euclid no color space ']);


end
%==========================================================================
% Metodo K-means (Aula 10): agrupa as cores em K clusters no espaco Lab e
% escolhe o cluster de maior azulidade media.
function BW = seg_kmeans(RGB, Dm, K)
    lab = rgb2lab(RGB);
    L = imsegkmeans(single(lab), K);

    meanBlue = zeros(K,1);
    for k = 1:K
        meanBlue(k) = mean(Dm(L == k));
    end
    [~, kBlue] = min(meanBlue);
    BW = (L == kBlue);
end

%==========================================================================
% Pos-processamento comum (Aula 08): morfologia + componentes conexos.
% Fecha buracos e remove manchas espurias, mantendo os maiores blobs.
function BW = postprocess_mask(BW)
    if ~any(BW(:)), return; end
    se = strel('disk', 1);
    BW = imopen(BW, se);              % remove pontos isolados
    BW = imclose(BW, se);             % une falhas finas
    BW = imfill(BW, 'holes');         % fecha buracos internos
    BW = bwareaopen(BW, 15);          % descarta componentes muito pequenos
    if any(BW(:))
        BW = bwareafilt(BW, 2);       % mantem os 2 maiores componentes conexos
    end
end
