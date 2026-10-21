%% Part 2: Generate Cell Center Configuration
clear; clc;

% --- DIRECTORY CONFIGURATION ---
targetDir = 'C:\Users\nowas\Downloads\SCE CODE\SCE Initial Conditions\Alt wL3 Initial Condition';

% Input filenames
fileOldCell_CFG = fullfile(targetDir, 'DataFileCell_N02G00_Resume.cfg');
fileStat        = fullfile(targetDir, 'detailedStat_N02G00_00025.txt');
% Output filename
fileOutput      = fullfile(targetDir, 'DataFileCell_New_Resume.cfg');
% -------------------------------

% 1. Read labels and count from the old .cfg file
fidOld = fopen(fileOldCell_CFG, 'r');
if fidOld == -1, error('Could not open old cell .cfg file.'); end

numExpectedCells = fscanf(fidOld, '%d', 1);
fgetl(fidOld); % Consume newline

oldLabels = cell(numExpectedCells, 1);
for i = 1:numExpectedCells
    line = fgetl(fidOld);
    if ischar(line)
        % Extract the label (e.g., 'pouch') which is the last column
        parts = strsplit(strtrim(line));
        oldLabels{i} = parts{end};
    end
end
fclose(fidOld);

% 2. Parse the detailedStat file for updated coordinates
fidStat = fopen(fileStat, 'r');
newCoords = [];
while ~feof(fidStat)
    line = fgetl(fidStat);
    if contains(line, 'CellCenter:')
        % Capture numbers in (x,y,z)
        tokens = regexp(line, '(-?\d+\.?\d*)', 'match');
        if length(tokens) >= 2
            newCoords = [newCoords; str2double(tokens{1}), str2double(tokens{2})];
        end
    end
end
fclose(fidStat);

% Verify counts match
if size(newCoords, 1) ~= numExpectedCells
    warning('Stat file has %d cells but old .cfg expected %d. Using count from stat file.', ...
        size(newCoords, 1), numExpectedCells);
    finalCount = size(newCoords, 1);
else
    finalCount = numExpectedCells;
end

% 3. Generate the new .cfg file
fidOut = fopen(fileOutput, 'w');
fprintf(fidOut, '%d\n', finalCount);

for i = 1:finalCount
    % Handle potential label mismatch if counts differed
    if i <= length(oldLabels)
        currentLabel = oldLabels{i};
    else
        currentLabel = 'pouch'; % Default fallback
    end
    
    % Format: X [tab] Y [tab] Z [tab] Label
    fprintf(fidOut, '%.4f\t%.4f\t0.0000\t%s\n', newCoords(i,1), newCoords(i,2), currentLabel);
end

fclose(fidOut);
fprintf('Success: Created %s with %d cells and original labels.\n', fileOutput, finalCount);