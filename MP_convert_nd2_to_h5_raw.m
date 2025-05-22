function MP_convert_nd2_to_h5_raw(nd2_path, output_h5_path)
    % Conversion brute d'un fichier ND2 en fichier .h5 sans traitement

    % Lecture du fichier ND2
    reader = bfGetReader(nd2_path);
    nT = reader.getSizeT();  % nombre de timepoints
    dimX = reader.getSizeX();
    dimY = reader.getSizeY();
    
    % Création du .h5
    h5create(output_h5_path, '/data', [dimX, dimY, 1, 1, nT], ...
        'Datatype', 'single', 'ChunkSize', [dimX, dimY, 1, 1, 1]);
    
    fprintf('Dimensions : %d x %d pixels - %d images.\n', dimX, dimY, nT);
    
    % Boucle sur chaque frame sans traitement
    for t = 1:nT
        frame = bfGetPlane(reader, t);
        frame = single(frame);  % conversion en simple précision sans normalisation

        % Écriture brute dans le .h5
        h5write(output_h5_path, '/data', frame, [1, 1, 1, 1, t], [dimX, dimY, 1, 1, 1]);

        % Affichage de progression
        if mod(t, 100) == 0
            fprintf('Écrit %d / %d images...\n', t, nT);
        end
    end
    
    reader.close();
    fprintf('Fichier sauvegardé sans traitement : %s\n', output_h5_path);
end
