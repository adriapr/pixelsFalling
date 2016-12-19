function imageFall


% CONFIGURATION
cfg.motion.accY = 0.3;                        % acceleration of particles 
cfg.alphaDecreaseStep = 0.01;                % transparency step: 1 / nFramesPixelAlive
cfg.model = ones(4,4);                        % 2D patch of the pixels
cfg.saveFrameImages = true;

    % Configuration for function addPixelFrom Image.m
    cfgAddPixel.pixelProportion = 8;
    cfgAddPixel.noiseInitVelX = 1.5;
    cfgAddPixel.noiseInitVelY = 1.5;
    cfgAddPixel.upForce = -2;
    cfgAddPixel.minWeight = 0.1;
    cfgAddPixel.thd_binarization = 0.05;
    cfgAddPixel.debug = false;

if nargin == 0
    [tifFile tifFolder] = uigetfile('E:\visualArt\#IMAGES\', 'Select image', '*.*');
    im = imread(strcat(tifFolder, tifFile));

    saveFrames = false;
    saveVideo = true;
    nameString = 'tifFile';
end

% video size
[imH imW color] = size(im);

imBG = 125 .* ones(imH, imW, 3);

% Open OUTPUT video fle
[fileName fileFolder] = uiputfile('example.avi', 'Save AVI image', '');
mov = avifile(strcat(fileFolder, fileName), 'compression', 'none')

% Add 15 frames
fprintf('Adding inital frames... '); tic;
for i=1:10
    mov = addframe(mov, im);
end
fprintf('Done (%.3f sc)\n ', toc);

% init pixels
tic;
pixels = [];
pixels = addPixelsFromImage( im, cfgAddPixel );
nPixels = size(pixels,1);
fprintf('%d pixels segmented in: %.3f sc\n ', nPixels, toc);

f = 0;
while nPixels > 0
    f = f + 1;
    fprintf('frame %d', f);
    fprintf(' | Pixel Trajectories... ', f); tic;    
 
    % new speed [ oldSpeed + (acc * weight) ]
    pixels(:,5) = pixels(:,5) + (cfg.motion.accY .* pixels(:,1));

    % new position = position + velocity
    pixels(:,2) = pixels(:,2) + pixels(:,4); % x
    pixels(:,3) = pixels(:,3) + pixels(:,5); % y

    % new alpha
    pixels(:,10) = pixels(:,10) - cfg.alphaDecreaseStep;

    % if out of area or transparet
%     if (pixels(p,3) > imH-1 || pixels(p,3) < 2 || pixels(p,2) > imW-1 || pixels(p,2) < 2 || pixels(p,10) <= 0)
%         pixels(p,6) = 1; % dead pixel
%     end
    iPixelsAlive = ones(nPixels,1);
    
    iPixelsAlive( find(pixels(:,2) > imW-1) ) = 0;      % pixels out of area (left)
    iPixelsAlive( find(pixels(:,2) < 2)     ) = 0;      % pixels out of area (right)
    iPixelsAlive( find(pixels(:,3) > imH-1) ) = 0;      % pixels out of area (down)
    iPixelsAlive( find(pixels(:,3) < 2)     ) = 0;      % pixels out of area (up)
    iPixelsAlive( find(pixels(:,10) <= 0)   ) = 0;      % pixels out of area (up)
    
    iiPA = find(iPixelsAlive == 1);
    
    % update pixels matrix with only alive pixels
    pixelsNew = pixels(iiPA, :);
    clear pixels;
    pixels = pixelsNew;
    clear pixelsNew;
    nPixels = size( pixels, 1 );
    
    fprintf(' (%.3f sc)', toc);
    
    % Save frame into movie
    fprintf(' | Drawing frame... ', f); tic;    
%     if nPixels > 0
% 
%         if cfg.saveFrameImages
%             imFrame = drawFrame( imBG, pixels(1:nPixels,:), cfg.model );
%             mov = addframe(mov, imFrame);
%             nameFrame = strcat(strcat(fileName, num2str(f)), '.tif');
%             imwrite(imFrame, nameFrame, 'jpeg', 'Mode', 'lossless');
%         else
%             mov = addframe(mov, drawFrame( imBG, pixels(1:nPixels,:), cfg.model ));
%         end
%         
%     else
%         mov = addframe(mov, imBG);
%     end
    
    % nPixels history
    log_nPixels(f) = nPixels;

    fprintf('Done (%.3f sc) - %d pixels\n ', toc, nPixels);

end % frame

% Add 15 frames
fprintf('Adding end frames... '); tic;
for i=1:5
    mov = addframe(mov, imBG);
end
fprintf('Done (%.3f)\n ', toc);

% Close movie file
mov = close(mov);
fprintf('\nOutput File: %s\n', fileName);

% Read and show movie
% movOut = aviread(fileName);
% movie(movOut, 2);

% PLOT results
figure; plot(log_nPixels); grid on; xlabel('frame'); ylabel('nPixels');

