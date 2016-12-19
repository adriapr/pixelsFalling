function pixels = addPixelsFromImage(imIN, cfg)

if nargin < 2
    cfg.pixelProportion = 3;
    cfg.noiseInitVelX = 0.4;
    cfg.noiseInitVelY = 1;
    cfg.upForce = 3;
    cfg.minWeight = 0.01;
    cfg.thd_binarization = 0.01;
    cfg.debug = false;
end

if nargin == 0
    load ims;
end

imBin = im2bw(255-imIN, cfg.thd_binarization);

% show segmentations
if cfg.debug
    figure; imshow(imFG);
    figure; imshow(imBin);
end

% get pixels
[y x ps] = find(imBin > 0);

nPixels = length(x);


% Random pixel selection
step = cfg.pixelProportion;

pIndex = round(1:step:nPixels);
nPixels = length(pIndex);
x = x(pIndex);
y = y(pIndex);
clear pIndex; clear step;    

% if no pixels return empty
if nPixels == 0
    pixels = [];
    return
end

% show selected pixels
if cfg.debug
    hold on;
    plot(y, x, 'g.');
end


% Pixels initalization
% [Wieght, posX, posY, velX, velY, boolDown, R, G, B, alpha]
pixels = zeros(nPixels, 10);

% initial random velocity in X
pixels(:,4) = cfg.noiseInitVelX .* (randn(nPixels, 1));
pixels(:,5) = cfg.noiseInitVelY .* (randn(nPixels, 1)) + (ones(nPixels,1) .* cfg.upForce);

% initial alpha to 1 (opaque) 
pixels(:,10) = ones(nPixels, 1);

% RGB values
for p = 1:nPixels
    pixels(p,7) = double(imIN(y(p),x(p),1)) / 255;
    pixels(p,8) = double(imIN(y(p),x(p),2)) / 255;
    pixels(p,9) = double(imIN(y(p),x(p),3)) / 255;
    
%    pixels(p,[7 8 9]) = (pixels(p,[7 8 9]) + [1 1 1]) ./ 2;

    % Weight (Dark points are heavier)
    pixels(p,1) = 1 - (pixels(p,7) + pixels(p,8) + pixels(p,9) )/3 + cfg.minWeight;

    % position
    pixels(p,2) = x(p);
    pixels(p,3) = y(p);

    % initial velocity
%   pixels(p,4) = cfg.noiseInitVelX*(randn(1));
%   pixels(p,5) = cfg.noiseInitVelY*(randn(1)) + cfg.upForce;
end
