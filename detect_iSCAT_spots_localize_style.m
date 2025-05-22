function detect_iSCAT_spots_localize_style(input_h5, output_h5, contrast_thresh)
% Spot detection sur une seule image, façon localize_iSCAT_v5_3 (filtrage, minima, jiggle)

    if exist(output_h5, 'file')
        delete(output_h5);
        pause(0.1);
    end

    % Lecture de l'image
    info = h5info(input_h5, '/data');
    dimX = info.Dataspace.Size(1);
    dimY = info.Dataspace.Size(2);
    im2 = h5read(input_h5, '/data', [1 1 1 1 1], [dimX dimY 1 1 1]);
    im2 = squeeze(im2);

    % Image 1 = fond uniforme
    im1 = ones(size(im2));

    % Calcul du contraste différentiel
    imdiff = im2 - im1;

    % Filtrage doux (sigma = 1, comme localize)
    imdiff = imgaussfilt(imdiff, 1);

    % CRUD = bordure de 10 pixels
    crud = false(size(im2));
    border = 10;
    crud(1:border,:) = true;
    crud(end-border+1:end,:) = true;
    crud(:,1:border) = true;
    crud(:,end-border+1:end) = true;

    % Sélection des candidats : minima locaux en dehors du CRUD
    mask = imregionalmin(imdiff) & ~crud;

    % Appliquer seuil cubé comme dans localize
    mask = mask & (imdiff < -contrast_thresh^3);

    % Extraction des positions
    [pos_y, pos_x] = find(mask);

    disp('Nombre de minima avant jiggle_spots :');
    disp(nnz(mask));
    % Filtrer les coordonnées qui seraient hors limites
    valid_idx = pos_x > 2 & pos_y > 2 & ...
                pos_x < dimX - 2 & pos_y < dimY - 2;
    pos_x = pos_x(valid_idx);
    pos_y = pos_y(valid_idx);
    fprintf('Spots après nettoyage : %d\n', numel(pos_x));


    % Ajustement sous-pixel avec jiggle_spots_dam
    if ~isempty(pos_x)
        [pos_x, pos_y] = jiggle_spots_dam(imdiff, pos_x, pos_y, ...
            'brightness', -1, 'max_dist', 2);
        fprintf('Spots après jiggle_spots : %d\n', numel(pos_x));
    end

    % Éliminer les doublons trop proches
    min_dist = 10;  % distance minimale entre deux spots (en pixels)
    coords = [pos_x, pos_y];
    keep = true(size(pos_x));
    
    for i = 1:length(pos_x)
        if ~keep(i)
            continue;
        end
        dists = sqrt(sum((coords - coords(i,:)).^2, 2));
        close_idx = find(dists < min_dist);
        close_idx(close_idx == i) = [];  % ne pas se supprimer soi-même
        keep(close_idx) = false;
    end
    
    % Appliquer le filtrage
    pos_x = pos_x(keep);
    pos_y = pos_y(keep);


    if numel(pos_x) > 1e5
        warning('Trop de spots détectés, affichage désactivé.');
        return;
    end

    % Affichage
    figure;
    imshow(im2, [0.9 1.1]); hold on;
    fprintf('Nombre de spots candidats : %d\n', numel(pos_x));
    plot(pos_y, pos_x, 'ro', 'MarkerSize', 6, 'LineWidth', 1);
    title(sprintf('%d spots détectés (style localize)', numel(pos_x)));

    % % Sauvegarde dans le fichier h5 (optionnel mais utile)
    % group = '/spots/tp1';
    % h5create(output_h5, [group '/x'], size(pos_x));
    % h5write(output_h5, [group '/x'], pos_x);
    % h5create(output_h5, [group '/y'], size(pos_y));
    % h5write(output_h5, [group '/y'], pos_y);
    % fprintf('Spots enregistrés dans %s\n', output_h5);
end
