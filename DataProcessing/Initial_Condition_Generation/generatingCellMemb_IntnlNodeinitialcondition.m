%% Part 3: Generate Internal and Membrane Node Configurations
clear; clc;

% --- DIRECTORY CONFIGURATION ---
targetDir = 'C:\Users\nowas\Downloads\SCE CODE\SCE Initial Conditions\Alt wL3 Initial Condition';

% Input filenames
fileStat        = fullfile(targetDir, 'detailedStat_N02G00_00025.txt');
fileWing_VTK    = fullfile(targetDir, 'WingDisc_N02G00_00025.vtk');
fileOldMem_CFG  = fullfile(targetDir, 'DataFileMembrane_N02G00_Resume.cfg');

% Output filenames
fileOutInternal = fullfile(targetDir, 'DataFileInternal_New_Resume.cfg');
fileOutMembrane = fullfile(targetDir, 'DataFileMembrane_New_Resume.cfg');
% -------------------------------

% 1. Read all coordinates from the WingDisc VTK (31597 total points)
fidVtk = fopen(fileWing_VTK, 'r');
if fidVtk == -1, error('Could not open WingDisc VTK.'); end
while ~feof(fidVtk)
    line = fgetl(fidVtk);
    if contains(line, 'POINTS')
        numPts = sscanf(line, 'POINTS %d');
        vtkNodes = fscanf(fidVtk, '%f', [3, numPts])';
        break;
    end
end
fclose(fidVtk);

% 2. Pre-load Membrane metadata (Parameters and Labels) from old .cfg
fidOldMem = fopen(fileOldMem_CFG, 'r');
memMetadata = {}; 
while ~feof(fidOldMem)
    line = fgetl(fidOldMem);
    if ischar(line) && ~isempty(strtrim(line))
        parts = strsplit(strtrim(line));
        if length(parts) >= 5
            % Store {Parameter, Label}
            memMetadata{end+1} = {parts{4}, parts{5}}; 
        end
    end
end
fclose(fidOldMem);

% 3. Parse detailedStat to get the list of counts per cell
fidStat = fopen(fileStat, 'r');
cellCounts = []; % To store [numInt, numMem] for each cell
while ~feof(fidStat)
    line = fgetl(fidStat);
    if contains(line, 'CellRank:')
        nI = 0; nM = 0;
        while true
            L = fgetl(fidStat);
            if contains(L, 'CurrentActiveIntnlNode:'), nI = str2double(regexp(L,'\d+','match','once')); end
            if contains(L, 'CurrentActiveMembrNodes:'), nM = str2double(regexp(L,'\d+','match','once')); break; end
        end
        cellCounts = [cellCounts; nI, nM];
    end
end
fclose(fidStat);

% 4. Partition based on Strategy C (All Membrane nodes first, then Internal)
fidInt = fopen(fileOutInternal, 'w');
fidMem = fopen(fileOutMembrane, 'w');

% Step A: Process all Membrane Nodes (Starting from VTK index 1)
nodeIdx = 1;
memMetaIdx = 1;
for cellID = 0:(size(cellCounts, 1) - 1)
    numMem = cellCounts(cellID + 1, 2);
    for i = 1:numMem
        param = memMetadata{memMetaIdx}{1};
        label = memMetadata{memMetaIdx}{2};
        fprintf(fidMem, '%d\t%.4f\t%.4f\t%s\t%s\n', ...
            cellID, vtkNodes(nodeIdx,1), vtkNodes(nodeIdx,2), param, label);
        nodeIdx = nodeIdx + 1;
        memMetaIdx = memMetaIdx + 1;
    end
end

% Step B: Process all Internal Nodes (Continuing from where Membrane nodes ended)
for cellID = 0:(size(cellCounts, 1) - 1)
    numInt = cellCounts(cellID + 1, 1);
    for i = 1:numInt
        fprintf(fidInt, '%d\t%.4f\t%.4f\t0.0000\t\n', ...
            cellID, vtkNodes(nodeIdx,1), vtkNodes(nodeIdx,2));
        nodeIdx = nodeIdx + 1;
    end
end

fclose(fidInt);
fclose(fidMem);
fprintf('Success: Node files generated using Strategy C partitioning.\n');