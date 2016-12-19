function imOUT= drawFrame(im, pixels, model)
% NOTICE: model is a matrix odd*odd

% frame size
[imH imW color] = size(im);
nPixels = size(pixels, 1);


imOUT = double(im) ./ 255;
% imD = imOUT;


yRadius = size(model,1) / 2 - 0.5;
xRadius = size(model,2) / 2 - 0.5;

antiModel = 1 - model;

for p = 1:nPixels
    
        
%         plot(pixels(p,2), pixels(p,3), 'x', 'MarkerSize', 5, 'Color',  pixels(p, [7 8 9]));
        
    x = pixels(p,2);
    y = pixels(p,3);

    % Check borders
    if x < xRadius+1
        x = xRadius +1;
    end
    if x > imW - xRadius
        x = imW - xRadius;
    end
    if y < yRadius+1
        y = yRadius +1;
    end
    if y > imH - yRadius
        y = imH - yRadius;
    end

    vx = round(x-xRadius):round(x+xRadius);
    vy = round(y-yRadius):round(y+yRadius);

    modelAlpha = model .* (pixels(p,10));

    % Red
    imOUT( round(vy), round(vx), 1 ) = (imOUT( floor(vy), floor(vx), 1 ) .* (1-modelAlpha)) + (pixels(p,7) .* modelAlpha);
    % Blue
    imOUT( round(vy), round(vx), 2 ) = (imOUT( floor(vy), floor(vx), 2 ) .* (1-modelAlpha)) + (pixels(p,8) .* modelAlpha);
    % Green
    imOUT( round(vy), round(vx), 3 ) = (imOUT( floor(vy), floor(vx), 3 ) .* (1-modelAlpha)) + (pixels(p,9) .* modelAlpha);

end
    
    

% imshow(imOUT);