function videoFall


% CONFIGURATION
cfg.nFrames = 100;                          % number of captured and processed frames
cfg.motion.accY = 0.4;                        % acceleration of particles 
cfg.alphaDecreaseStep = 0.03;               % transparency step: 1 / nFramesPixelAlive
cfg.model = ones(2,2);                      % 2D patch of the pixels
cfg.device = 'winvideo';                    % device name (use imaqhwinfo for get string in your PC)
cfg.deviceVideoFormat = 'YUY2_640x480';     % device video format (use imaqhwinfo for get string in your PC)

    % Configuration for function addPixel.m
    cfgAddPixel.nPixels = 600;                  % max amount of pixels to add per frame
    cfgAddPixel.noiseInitVelX = 0.4;              % noise in velocity in X axis
    cfgAddPixel.noiseInitVelY = 0.4;              % noise in velocity in Y axis
    cfgAddPixel.upForce = -0.5;                   % Force in top direction (Y axis)
    cfgAddPixel.minWeight = 0.1;               % minim weight of a new particle (add to 1-Intensity)
    cfgAddPixel.thd_binarization = 0.10;        % threshold for binarization
    cfgAddPixel.debug = false;                  % show debug intermediate images
    

%% - Video Capture
% infovid = imaqhwinfo(cfg.device);
% infovid.DeviceInfo.SupportedFormats;
vidobj = videoinput(cfg.device, 1, cfg.deviceVideoFormat);

% force algorith to trust that camera is given frames in RGB
if strcmp(cfg.deviceVideoFormat, 'YUY2_640x480');
    set(vidobj, 'ReturnedColorSpace', 'rgb'); % Forced to RGB
end

% get background
imBG = getsnapshot(vidobj);

% video size
[imH imW color] = size(imBG);

%if cfg.useBG
    figure; imshow(imBG); title('- Background -');
    pause(0.2);
%end

% Open OUTPUT video fle
fileName = uiputfile('example.avi', 'Save AVI image', '');
mov = avifile(fileName, 'compression', 'Cinepak')

% start logging to memory
fprintf('Taking video from cam... '); tic;
set(vidobj, 'FramesPerTrigger', cfg.nFrames);
start(vidobj);
fprintf('DONE (%.3f)\n', toc);

% wait until have nFrames on memory
pause(cfg.nFrames / 25);
numAvail = 0;
while numAvail < cfg.nFrames
    numAvail = vidobj.FramesAvailable;
    pause(0.1);
end

% get frames and clear device
fprintf('Getting frames from memory... '); tic;
frameData = getdata(vidobj);
delete(vidobj); clear('vidobj');
fprintf('DONE (%.3f)\n', toc);

% init pixels
pixels = [];
pixelsNew = [];

% for f = 1:1
for f = 1:cfg.nFrames
    fprintf('frame %d', f);
    fprintf(' | Pixel Trajectories... ', f); tic;    
   
    % obtain new pixels
    newPixels = addPixels( imBG,                 frameData(:,:,:,f), cfgAddPixel ); 
    
    pixels = [pixels; newPixels];
    
    nPixels = size(pixels,1);

    if nPixels > 0
        % new speed [ oldSpeed + (acc * weight) ]
        pixels(:,5) = pixels(:,5) + (cfg.motion.accY .* pixels(:,1));

        % new position = position + velocity
        pixels(:,2) = pixels(:,2) + pixels(:,4); % x
        pixels(:,3) = pixels(:,3) + pixels(:,5); % y

        % new alpha
        pixels(:,10) = pixels(:,10) - cfg.alphaDecreaseStep;

        iPixelsAlive = ones(nPixels,1);

        % check dead pixels
        iPixelsAlive( find(pixels(:,2) > imW-1) ) = 0;      % pixels out of area (left)
        iPixelsAlive( find(pixels(:,2) < 2)     ) = 0;      % pixels out of area (right)
        iPixelsAlive( find(pixels(:,3) > imH-1) ) = 0;      % pixels out of area (down)
        iPixelsAlive( find(pixels(:,3) < 2)     ) = 0;      % pixels out of area (up)
        iPixelsAlive( find(pixels(:,10) <= 0)   ) = 0;      % pixels with alga = 0 (transparent)

        iiPA = find(iPixelsAlive == 1);

        % copy alive pixels in the same variable
        pixelsNew = pixels(iiPA, :);
        clear pixels;
        pixels = pixelsNew;
        clear pixelsNew;
        nPixels = size( pixels, 1 );
    end
    
    fprintf(' (%.3f sc)', toc);
    
    % Save frame into movie
    fprintf(' | Drawing frame... ', f); tic;    
    if nPixels > 0
        mov = addframe(mov, drawFrame( imBG, pixels(1:nPixels,:), cfg.model ));
    else
        mov = addframe(mov, imBG);
    end
    
    % nPixels history
    log_nPixels(f) = nPixels;

    fprintf('Done (%.3f sc) - %d pixels\n ', toc, nPixels);

end % frame

% Close movie file
mov = close(mov);
fprintf('\nOutput File: %s\n', fileName);

% Read and show movie
% movOut = aviread(fileName);
% movie(movOut, 2);

% PLOT results
figure; plot(log_nPixels); grid on; xlabel('frame'); ylabel('nPixels');

