% to use it put
% MP_convert_nd2_to_h5('Yourfilename','MP_data.h5');  
% In the command window
% ex : MP_convert_nd2_to_h5('iSCAT_RAMcapture_60s_fov1.nd2', 'MP_data.h5');



function MP_convert_nd2_to_h5(nd2_path, output_h5_path)
    % Conversion d'un fichier ND2 en fichier HDF5
  

    % Lecture du fichier ND2
    reader = bfGetReader(nd2_path);
    nT = reader.getSizeT();      % nombre d'images (timepoints)
    dimX = reader.getSizeX();    % largeur
    dimY = reader.getSizeY();    % hauteur

    % Création du fichier HDF5
    h5create(output_h5_path, '/data', [dimX, dimY, 1, 1, nT], ...
        'Datatype', 'single', 'ChunkSize', [dimX, dimY, 1, 1, 1]);

    fprintf('Dimensions : %d x %d pixels - %d images.\n', dimX, dimY, nT);

    % Boucle sur chaque image
    for t = 1:nT
        frame = bfGetPlane(reader, t);   % Lecture 
        frame = single(frame);           % Conversion 

        h5write(output_h5_path, '/data', frame, ...
            [1, 1, 1, 1, t], [dimX, dimY, 1, 1, 1]);

        if mod(t, 100) == 0
            fprintf('Écrit %d / %d frames...\n', t, nT);
        end
    end

    reader.close();
    fprintf('Conversion terminée. Fichier sauvegardé : %s\n', output_h5_path);
end
