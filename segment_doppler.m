function [masks, RGB] = segment_doppler(VD, opt)
    if nargin < 2, opt = struct(); end
    if ~isfield(opt,'smooth'),       opt.smooth = 0.4;        end
    if ~isfield(opt,'kClusters'),    opt.kClusters = 3;       end

    RGB = doppler_to_rgb(VD);
   
    if opt.smooth > 0
        RGBp = im2uint8(imgaussfilt(im2double(RGB), opt.smooth));
    else
        RGBp = RGB;
    end
    sample = imread("sample.png");

    [masks.dist, Dm] = euclidia_limiar(RGBp,sample);
    masks.kmeans = seg_kmeans(RGBp, Dm,opt.kClusters);

end


%============================================================
% Segmentação por limiarização utilizando a distância Euclidiana
% from color_17.m[script]
function [R, Dm]= euclidia_limiar(RGB,sample)
    
    nr = size(RGB,1);
    nc = size(RGB,2);
    lab = RGB;

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
    Dm = reshape(D, nr, nc);

    dmax   = max(Dm(:));
    Dn     = Dm / dmax;
    t = graythresh(Dn);
    
    t = t * dmax;
    R = Dm < t;                     


end
%==========================================================================
% Metodo K-means agrupa as cores em K clusters no espaco Lab e
function BW = seg_kmeans(RGB, Dm, K)
    
    rgb = RGB;

    % K-means no RGB
    labels = imsegkmeans(rgb,K);
    dmax   = max(Dm(:));
    Dn = Dm/dmax;
    less_mean = 10000;
    idx = 1;
    
    for i=1:K
        mask = labels == i;
        aux=mean(Dn(mask));
        if aux < less_mean
            less_mean = aux;
            idx = i;
        end
    end
    BW = labels == idx;
    
end

