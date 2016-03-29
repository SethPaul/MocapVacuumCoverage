clear
promptForParameters=false; % use default values without prompting for change
% Prompt for file name
[FileName, PathName, FilterIndex] = uigetfile('*.txt', 'Select 3D Ascii File', 'partID_condNum_vacID.txt');

if promptForParameters
    prompt = {'Length of Vacuum head in cm:', ...
      'height cutoff in meters:'};
    defaultAnswer = {'35', '0.09'};
    conditions = inputdlg(prompt, 'Input Conditions', 1, defaultAnswer);
    lenHead = str2num(conditions{1}); % length of vacuum head
    heightCutoff = str2num(conditions{2});
end

disp('```Initializing parameters and reading .txt file 0% complete')
%% Create a 3D matrix: side 1 x side 2 x number of frames
%8 feet x 10 feet x number of frames=> 244 x 305 x number of frames (1 coverage square per cm^2)

subCMres = 1; %magification or shrinkage of grid i.e. subCMres = 2 turns it to a 5mm resolution grid
Side1 = ceil(244 * subCMres); %length of indexes for rows
Side2 = ceil(306 * subCMres); %length of indexes for cols
if promptForParameters
    lenHead = ceil(lenHead * subCMres);
else
    lenHead = ceil(70 * subCMres);
end
samplingRate = 1;

bufferLength = ceil(30 / samplingRate);% frames to clear after a pass to count as single pass

if ~promptForParameters
    heightCutoff = 0.09; %limit for useful vacuum head height
end


%% Read data & initialize 3-D matrix
numberTable = readtable([PathName, FileName], 'delimiter', 'tab', 'ReadVariableNames', false, 'HeaderLines', 5);

% numberTable = readtable('TestVacuumMarkers.txt', 'delimiter', 'tab', 'ReadVariableNames', false, 'HeaderLines', 5);
numberTable2 = numberTable{1:samplingRate:size(numberTable, 1), 1:7};
numberTable2 = numberTable2((numberTable2(:, 2) > 0 & ...
    numberTable2(:, 3) > 0&...
    numberTable2(:, 4) > 0&...
    numberTable2(:, 5) > 0&...
    numberTable2(:, 6) > 0&...
    numberTable2(:, 2) ~= numberTable2(:, 5)),:); % confirm markers within the capture space
numberTable2(:, 2:7) = numberTable2(:, 2:7) * subCMres;
%reduce to only frames with vacuum head markers near the floor
numberTable3 = numberTable2((numberTable2(:, 4) < heightCutoff & numberTable2(:, 7) < heightCutoff), :);

%fix frame indexing if sampling
if samplingRate ~= 1
    numberTable3(:, 1) = floor(numberTable3(:, 1) / samplingRate + 1);
end
numFrames = size(numberTable, 1);
superMatrix = zeros(Side1, Side2, numFrames);
clear numberTable numberTable2

%% interpolate values
disp('```Interpolating vacuum head ~25% complete')
% convert table to cell array frames x {frame values}
cellTable = mat2cell(numberTable3(:, :), ones(1, size(numberTable3, 1)), 7);

% determine slope and intercept
cellTable_lineVars = cellfun(@(x) [x (x(6)-x(3))/(x(5)-x(2)) x(6)-(x(6)-x(3))/(x(5)-x(2))*x(5)] , cellTable, 'UniformOutput', false);

% interpolate vacuum head x-vals
cellTable_passXs = cellfun(@(x)[x linspace(x(2), x(5), lenHead)], cellTable_lineVars, 'UniformOutput', false);
cellTable_newXs = cellfun(@(x)[linspace(x(2), x(5), lenHead)], cellTable_lineVars, 'UniformOutput', false);

% calculate vacuum head y-vals
cellTable_newYs = cellfun(@(x)[x([10:end])*x(8)+x(9)], cellTable_passXs, 'UniformOutput', false);

% create frame matrix in format to match new x- and y- vals [1xlenHead,
% 2xlenHead, etc.]
foo_newFrames=cellfun(@(x)[repmat(x(1), 1, lenHead)],cellTable_lineVars,'UniformOutput', false);

% expand from cell arrays to vectors
newXs=[cellTable_newXs{:}];
newYs=[cellTable_newYs{:}];
newFrames=[cellTable_newFrames{:}];

% clear cellTable cellTable_lineVars cellTable_passXs cellTable_newFrames
mappedSubscripts = [round(newXs' * 100) + 1 round(newYs' * 100) + 1 newFrames'];

%% fill 3-D matrix and clear buffer cells
disp('```Filling values and clearing buffer ~30% complete')
% convert i, j, k to linear index equivalent
lineIndices = sub2ind(size(superMatrix), mappedSubscripts(:, 1), mappedSubscripts(:, 2), mappedSubscripts(:, 3));
uniqueLineIndices = unique(lineIndices);
% clear lineIndexes newXs newYs newFrames mappedSubscripts
superMatrix(uniqueLineIndices) = 1;

%create clearing indices
%make repeating matrix, bufferLength x indices Matrix
[uniqueXs, uniqueYs, uniqueFrames] = ind2sub(size(superMatrix), uniqueLineIndices);
clearingSubscripts = repmat([uniqueXs, uniqueYs, uniqueFrames], bufferLength, 1);

%create the values to add to the frame indices, [1xlength(indices matrix);
%2xlength(indices matrix), etc.]
bufferFrames = reshape(repmat(1:bufferLength, length(uniqueFrames), 1), size(clearingSubscripts, 1), 1);

% add buffer values
clearingSubscripts(:, 3) = min(size(superMatrix, 3), clearingSubscripts(:, 3) + bufferFrames);

clearingLineIndices = sub2ind(size(superMatrix), clearingSubscripts(:, 1), clearingSubscripts(:, 2), clearingSubscripts(:, 3));
% clear clearingSubscripts bufferFrames

% clear the buffering indices
superMatrix(clearingLineIndices) = 0;

%% Calulate Passes
disp('```Calculating Passes ~33% complete')

% rotate and sum across frames for subsets of the superMatrix (superMatrix
% is too large to do all together)

passesMatrix=sum(superMatrix,3);
disp(['Max passes = ' num2str(max(max(passesMatrix))) ' passes'])
disp(['Min coverage = ' num2str(min(min(passesMatrix))) ' passes'])
figure; contourf(passesMatrix);
savefig([PathName, FileName(1:end-4), '_passes'])
print('-dpng', [PathName, FileName(1:end-4), '_passes'])
figure; noPass=(passesMatrix==0)*1; contourf(noPass)
savefig([PathName, FileName(1:end-4), '_noPasses'])
print('-dpng', [PathName, FileName(1:end-4), '_noPasses'])
clear clearingUniqueLineIndexes

%% Calculate coverage
disp('```Calculating coverage timeseries ~85% complete')

simpleMatrix = zeros(Side1, Side2);
percentCovered = zeros(max(uniqueFrames), 1);


% create cell arrays of the interpolated x and y indices
cellTable_newIs = cellfun(@(x) round(x' * 100) + 1, cellTable_newXs, 'UniformOutput', false);
cellTable_newJs = cellfun(@(x) round(x' * 100) + 1, cellTable_newYs, 'UniformOutput', false);

% iterate over each frame
for frameIndex = 1:numFrames
    if any(frameIndex == numberTable3(:, 1))
        frameUnshifted=find(numberTable3(:, 1) == frameIndex, 1);
        % update 2-D grid from indices in the cell arrays
        simpleMatrix(cellTable_newIs{frameUnshifted}, cellTable_newJs{frameUnshifted}) = 1;

        % update coverage
        percentCovered(frameIndex) = sum(sum(simpleMatrix));
    else
        %refer to last coverage if not a new frame
        if frameIndex > 1
            percentCovered(frameIndex) = percentCovered(frameIndex-1);
        else
            percentCovered(frameIndex) = 0;
        end
    end
end
% divide coverage by total area for percentage
percentCovered = percentCovered / (size(simpleMatrix, 1) * size(simpleMatrix, 2));

figure; area(percentCovered);
savefig([PathName, FileName(1:end - 4), '_percentCovered'])
print('-dpng', [PathName, FileName(1:end - 4), '_percentCovered'])
disp(['Final Coverage = ' num2str(max(percentCovered) * 100) '%'])

vacCoverageData={{FileName}, {percentCovered}, {passesMatrix}};
save([FileName(1:end - 4), '_vacCoverageData'], 'vacCoverageData')


%% Make Video of Passes- Takes several minutes
% testPasses3D = cumsum(superMatrix, 3);
% save('testPasses3D', 'testPasses3D', '-v7.3')
%
% load('testPasses3D.mat')
%
% writerObj = VideoWriter('vacTest1.avi');
% writerObj.FrameRate = 60;
% open(writerObj);
%
% clims = [0 max(max(passesMatrix))];
% % figure('units', 'normalized', 'position', [.1 .1 .8 .8])
% imagesc(testPasses3D(:, :, 1), clims);
% set(gca,'nextplot', 'replacechildren');
% set(gcf,'Renderer', 'zbuffer');
%
% for frameIndex = 1:numFrames
%    imagesc(testPasses3D(:, :, frameIndex), clims);
%    drawnow()
%    frame = getframe;
%    writeVideo(writerObj, frame);
% end
%
% close(writerObj);
