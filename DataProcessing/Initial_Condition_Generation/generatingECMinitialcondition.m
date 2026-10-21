%% Part 1: Generate ECM Configuration
clear; clc;

% --- DIRECTORY CONFIGURATION ---
targetDir = 'C:\Users\nowas\Downloads\SCE CODE\SCE Initial Conditions\Alt wL3 Initial Condition';

fileOldECM_CFG = fullfile(targetDir, 'DataFileECM_N02G00_Resume.cfg');
fileNewECM_VTK = fullfile(targetDir, 'ECM_N02G00_25.vtk');
fileOutput     = fullfile(targetDir, 'DataFileECM_New_Resume.cfg');

% 1. Read labels and count from the old .cfg file
fidOld = fopen(fileOldECM_CFG, 'r');
if fidOld == -1, error('Could not open old .cfg file at %s', fileOldECM_CFG); end

% Get total node count from the first line
expectedNodeCount = fscanf(fidOld, '%d', 1);
fgetl(fidOld); % Consume the newline after the count

oldLabels = cell(expectedNodeCount, 1);
for i = 1:expectedNodeCount
    line = fgetl(fidOld);
    if ischar(line)
        % Extract the label (the last string in the tab-separated line)
        parts = strsplit(strtrim(line));
        oldLabels{i} = parts{end}; 
    end
end
fclose(fidOld);

fprintf('Target node count: %d. Labels loaded.\n', expectedNodeCount);

% 2. Read the new coordinates from the .vtk file
fidVtk = fopen(fileNewECM_VTK, 'r');
if fidVtk == -1, error('Could not open .vtk file at %s', fileNewECM_VTK); end

vtkCoords = [];
while ~feof(fidVtk)
    line = fgetl(fidVtk);
    if contains(line, 'POINTS')
        numVtkPts = sscanf(line, 'POINTS %d');
        % Read all points from the VTK (x, y, z triplets)
        vtkCoords = fscanf(fidVtk, '%f', [3, numVtkPts])';
        break;
    end
end
fclose(fidVtk);

% 3. Generate the new .cfg file using VTK positions + Old Labels
fidOut = fopen(fileOutput, 'w');
if fidOut == -1, error('Could not create output file at %s', fileOutput); end

% Write the header count
fprintf(fidOut, '%d\n', expectedNodeCount);

% Match VTK coordinates to Old Labels
for i = 1:expectedNodeCount
    % Format: X [tab] Y [tab] Label
    fprintf(fidOut, '%.4f\t%.4f\t%s\n', vtkCoords(i,1), vtkCoords(i,2), oldLabels{i});
end

fclose(fidOut);
fprintf('Success: Created %s with %d updated nodes.\n', fileOutput, expectedNodeCount);