function struct2json(S, save_path)
    % STRUCT2JSON save a struct as a JSON file.
    %
    % Paramters
    % ---------
    % S: struct
    % save_path: path to JSON file

    % Pretty-print with indentation
    jsonStr = jsonencode(S, 'PrettyPrint', true);
    
    % Save to file
    fid = fopen(save_path, 'w');
    if fid == -1
        error('Cannot open file for writing.');
    end
    fwrite(fid, jsonStr, 'char');
    fclose(fid);
end