function [pos_x_out, pos_y_out, success] = jiggle_spots_dam(frame, pos_x, pos_y, varargin)
    % Ajuste les positions de spots en les centrant sur le minimum local
    % (ou maximum selon le contraste). Utilisé dans le pipeline iSCAT.
    
    if isempty(pos_x) || isempty(pos_y)
        pos_x_out = pos_x;
        pos_y_out = pos_y;
        success = false;
        return
    end

    % Valeurs par défaut
    brightness = 1;
    max_dist = 3;
    remove_duplicates = false;
    snap_to = 'highest_contrast';

    % Lecture des arguments optionnels
    for i = 1:2:nargin-3-1
        switch varargin{i}
            case 'brightness'
                brightness = varargin{i+1};
            case 'max_dist'
                max_dist = varargin{i+1};
            case 'remove_duplicates'
                remove_duplicates = varargin{i+1};
            case 'snap_to'
                snap_to = varargin{i+1};
        end
    end

    % Détection des extrema
    if brightness == 0
        local_extrema = or(imregionalmin(frame), imregionalmax(frame));
    elseif brightness == -1
        local_extrema = imregionalmin(frame);
    elseif brightness == 1
        local_extrema = imregionalmax(frame);
    end

    [dim_x, dim_y] = size(frame);

    spots_lin = sub2ind([dim_x, dim_y], pos_x, pos_y);
    spots_lin = spots_lin(spots_lin > 0 & spots_lin <= numel(frame));  % sécurité

    % Offsets des voisins dans une fenêtre carrée
    [x, y] = meshgrid(-max_dist:max_dist, -max_dist:max_dist);
    neighbor_offsets = x + y * dim_x;
    neighbor_offsets = neighbor_offsets(:)';  % vecteur ligne

    % --- Méthode 1 : snap au minimum le plus proche ---
    if strcmp(snap_to, 'nearest')
        distance = zeros([2*max_dist+1, 2*max_dist+1]);
        distance(ceil((2*max_dist+1)^2 / 2)) = 1;  % centre
        distance = bwdist(distance);
        [~, dist_idx] = sort(distance(:));
        neighbor_offsets_sorted = neighbor_offsets(dist_idx);

        search_ROI = spots_lin(:) + neighbor_offsets_sorted;
        valid_extrema = local_extrema(search_ROI);

        for i = 1:size(valid_extrema, 1)
            io = find(valid_extrema(i,:) == 1, 1, 'first');
            if io
                spots_lin(i) = spots_lin(i) + neighbor_offsets_sorted(io);
            end
        end

    % --- Méthode 2 : snap au plus fort contraste ---
    elseif strcmp(snap_to, 'highest_contrast')
        search_ROI = spots_lin(:) + neighbor_offsets;
        valid_extrema = local_extrema(search_ROI);
        px_vals = frame(search_ROI);
        extrema_vals = px_vals .* valid_extrema;

        if brightness == 0
            [~, I_max] = max(abs(extrema_vals - median(frame(:))), [], 2);
        elseif brightness == -1
            extrema_vals(extrema_vals == 0) = 2;
            [~, I_max] = min(extrema_vals, [], 2);
        elseif brightness == 1
            [~, I_max] = max(extrema_vals, [], 2);
        end

        % Sécurité : filtrer les indices invalides
        I_max = I_max(:);
        valid_idx = find(I_max > 0 & I_max <= length(neighbor_offsets));
        if isempty(valid_idx)
            warning('Aucun spot validé par jiggle_spots');
            pos_x_out = [];
            pos_y_out = [];
            success = false;
            return
        end

        spots_lin = spots_lin(valid_idx);
        disp('taille spots_lin'); disp(size(spots_lin));
        disp('taille I_max'); disp(size(I_max));
        disp('taille neighbor_offsets'); disp(size(neighbor_offsets));

        I_max = I_max(valid_idx);
        spots_lin = spots_lin(:) + neighbor_offsets(I_max(:))';
        fprintf('Premier I_max = %d → décalage = %d\n', I_max(1), neighbor_offsets(I_max(1)));
    end

    % Sécurité finale
    spots_lin = spots_lin(spots_lin > 0 & spots_lin <= numel(frame));
    success = ~isempty(spots_lin);

    % Conversion en coordonnées (x, y)
    [pos_x_out, pos_y_out] = ind2sub(size(frame), spots_lin);
end
