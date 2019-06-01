function spikes_in_ripple_all = detect_ripple_demo(day, epoch)
    %% Detect ripple and spikes in ripples from specified EEG file(s)
    animal_data_path = '../dataset/Bon';
    % day = 4; epoch = 4; % tetrode = 18; 
    eeg_data_path = fullfile(animal_data_path, 'EEG');
    eeg_file_all = dir(eeg_data_path);
    eeg_file_all = {eeg_file_all(~[eeg_file_all(:).isdir]).name};
    eeg_file_chosen = eeg_file_all(contains(eeg_file_all, sprintf('%02d-%d', day, epoch)));

    animal_file_all = dir(fullfile(animal_data_path));
    animal_file_all = {animal_file_all(~[animal_file_all(:).isdir]).name};
    spike_file_chosen = animal_file_all(contains(animal_file_all, sprintf('spikes%02d', day)));
    if length(spike_file_chosen) ~= 1
        fprintf('Spike file not unique!');
    end
    load(fullfile(animal_data_path, spike_file_chosen{1}), 'spikes');
    tetrode_file = animal_file_all(contains(animal_file_all,'tetinfo'));
    load(fullfile(animal_data_path, tetrode_file{1}), 'tetinfo');

    ripples_by_tetrode = struct('tetrode', nan, 'area', '', 'depth', nan, 'ripples', []);
    lfp_ripple_band_by_tetrode = struct('tetrode', nan, 'lfp_ripple_band', []);
    for i=1:length(eeg_file_chosen)
        load(fullfile(eeg_data_path, eeg_file_chosen{i}), 'eeg');
        lfp_data_idxs = regexp(eeg_file_chosen{i}, '\d*','match');
        lfp_data_idxs = cellfun(@str2num, lfp_data_idxs);
        smpl_rate = eeg{lfp_data_idxs(1)}{lfp_data_idxs(2)}{lfp_data_idxs(3)}.samprate;
        start_time = eeg{lfp_data_idxs(1)}{lfp_data_idxs(2)}{lfp_data_idxs(3)}.starttime;

        lfp_data_idxs = regexp(eeg_file_chosen{i}, '\d*','match');
        lfp_data_idxs = cellfun(@str2num, lfp_data_idxs);
        ripples_by_tetrode(i).tetrode = lfp_data_idxs(3);
        lfp_ripple_band_by_tetrode(i).tetrode = lfp_data_idxs(3);
        if isempty(tetinfo{lfp_data_idxs(1)}{lfp_data_idxs(2)}{lfp_data_idxs(3)})
            continue;
        elseif ~tetinfo{lfp_data_idxs(1)}{lfp_data_idxs(2)}{lfp_data_idxs(3)}.numcells
            continue;
        elseif strcmp(tetinfo{lfp_data_idxs(1)}{lfp_data_idxs(2)}{lfp_data_idxs(3)}.area, 'Reference')
            continue;
        end
        ripples_by_tetrode(i).area = tetinfo{lfp_data_idxs(1)}{lfp_data_idxs(2)}{lfp_data_idxs(3)}.area;
        ripples_by_tetrode(i).depth = tetinfo{lfp_data_idxs(1)}{lfp_data_idxs(2)}{lfp_data_idxs(3)}.depth{1} * 0.0265; % depth in mm

        % Detect ripples on the tetrode
        lfp_data = eeg{lfp_data_idxs(1)}{lfp_data_idxs(2)}{lfp_data_idxs(3)}.data;
        [lfp_ripple_band, ripples] = detect_ripple(lfp_data, smpl_rate, start_time, 'karlsson09', false);

        % Examine number of spikes during the ripples on the same tetrode
        putative_neurons = spikes{lfp_data_idxs(1)}{lfp_data_idxs(2)}{lfp_data_idxs(3)};
        for k=1:length(ripples)
            spike_locs_cell = cell(length(putative_neurons), 1);
            neuron_id_mat = zeros(length(putative_neurons), 2);
            for j=1:length(putative_neurons)
                if isempty(putative_neurons{j}) || isempty(putative_neurons{j}.data)
                    spike_locs_cell{j} = [];
                    neuron_id_mat(j, :) = [lfp_data_idxs(3), j];
                else
                    spike_locs = putative_neurons{j}.data(:, 1);
                    spike_locs = spike_locs(bitand(spike_locs>=ripples(k).start_sec, spike_locs<ripples(k).end_sec));
                    spike_locs_cell{j} = spike_locs;
                    neuron_id_mat(j, :) = [lfp_data_idxs(3), j];
                end
            end 
            ripples(k).spike_locs = spike_locs_cell(~cellfun(@isempty, spike_locs_cell));
            ripples(k).neuron_ids = neuron_id_mat(~cellfun(@isempty, spike_locs_cell), :); % First col tetrode, second col neuron index
        end
        ripples_by_tetrode(i).ripples = ripples;
        lfp_ripple_band_by_tetrode(i).lfp_ripple_band = lfp_ripple_band;
    end

    ripples_by_tetrode(cellfun(@isempty,{ripples_by_tetrode(:).ripples})) = []; % Remove tetrodes where there is no ripple

    % Combine ripples on different tetrodes
    ripples_by_tetrode_table = struct2table(ripples_by_tetrode);
    ripples_by_tetrode_table = sortrows(ripples_by_tetrode_table, 'depth');
    ripples_by_tetrode = table2struct(ripples_by_tetrode_table);

    tetrode_dist = diff([ripples_by_tetrode(:).depth]);
    ripples_by_group_tetrode = struct('tetrodes', [], 'depths', [], 'area', {}, 'ripples', []);
    ripples_by_group_tetrode(1).tetrodes = ripples_by_tetrode(1).tetrode; 
    ripples_by_group_tetrode(1).depths = ripples_by_tetrode(1).depth; 
    ripples_by_group_tetrode(1).ripples = ripples_by_tetrode(1).ripples; 
    ripples_by_group_tetrode(1).area = ripples_by_tetrode(1).area; 
    num_tetrode_group = length(ripples_by_group_tetrode);
    for i=1:length(tetrode_dist)
        if tetrode_dist(i) > 3*0.0265 % depth in mm
            num_tetrode_group = num_tetrode_group + 1;
            ripples_by_group_tetrode(num_tetrode_group).tetrodes = ripples_by_tetrode(i+1).tetrode; 
            ripples_by_group_tetrode(num_tetrode_group).depths = ripples_by_tetrode(i+1).depth; 
            ripples_by_group_tetrode(num_tetrode_group).ripples = ripples_by_tetrode(i+1).ripples; 
            ripples_by_group_tetrode(num_tetrode_group).area = ripples_by_tetrode(i+1).area; 
        else
            ripples_by_group_tetrode(num_tetrode_group).tetrodes = [ripples_by_group_tetrode(num_tetrode_group).tetrodes, ripples_by_tetrode(i+1).tetrode];
            ripples_by_group_tetrode(num_tetrode_group).depths = [ripples_by_group_tetrode(num_tetrode_group).depths, ripples_by_tetrode(i+1).depth];
            ripples_by_group_tetrode(num_tetrode_group).ripples = [ripples_by_group_tetrode(num_tetrode_group).ripples, ripples_by_tetrode(i+1).ripples]; 
            ripples_by_group_tetrode(num_tetrode_group).area = [ripples_by_group_tetrode(num_tetrode_group).area, {ripples_by_tetrode(i+1).area}]; 
        end
    end

    for i=1:length(ripples_by_group_tetrode)
        ripples_table = struct2table(ripples_by_group_tetrode(i).ripples);
        ripples_table = sortrows(ripples_table, 'start_idx');
        ripples_struct = table2struct(ripples_table);
        rows_to_remove = [];
        for j=length(ripples_struct):-1:2
            if (ripples_struct(j).start_idx >= ripples_struct(j-1).start_idx && ripples_struct(j).start_idx < ripples_struct(j-1).end_idx)
                ripples_struct(j-1).end_idx = max(ripples_struct(j-1).end_idx, ripples_struct(j).end_idx);
                ripples_struct(j-1).end_sec = max(ripples_struct(j-1).end_sec, ripples_struct(j).end_sec);
                ripples_struct(j-1).length_idx = ripples_struct(j-1).end_idx - ripples_struct(j-1).start_idx; 
                ripples_struct(j-1).length_sec = ripples_struct(j-1).end_sec - ripples_struct(j-1).start_sec; 
                ripples_struct(j-1).spike_locs = [ripples_struct(j-1).spike_locs;ripples_struct(j).spike_locs];
                ripples_struct(j-1).neuron_ids = [ripples_struct(j-1).neuron_ids; ripples_struct(j).neuron_ids];
                rows_to_remove = [rows_to_remove, j];
            end
        end
        ripples_struct(rows_to_remove) = [];
        ripples_by_group_tetrode(i).ripples = ripples_struct; 
    end

    % Remove ripples that are too long (currently, >200ms)
    for i=1:length(ripples_by_group_tetrode)
        rows_to_remove = [];
        ripples_struct = ripples_by_group_tetrode(i).ripples;
        for j=1:length(ripples_struct)
            if ripples_struct(j).length_sec > 0.2
                rows_to_remove = [rows_to_remove, j];
            end
        end
        ripples_struct(rows_to_remove) = [];
        ripples_by_group_tetrode(i).ripples = ripples_struct; 
    end
    save(sprintf('../results/ripples-day_%d-epoch_%d.mat', day, epoch), 'ripples_by_group_tetrode');

    spikes_in_ripple_all = convert_ripple_mat(ripples_by_group_tetrode);
    save(sprintf('../results/spikes_in_ripple_all-day_%d-epoch_%d.mat', day, epoch), 'spikes_in_ripple_all');
    %% Visualize ripples during which there are several neurons firing together
    %{
    plot_window_offset = 0.5;
    num_neuron_thres = 3;
    for j=1:length(ripples_by_group_tetrode)
        ripples = ripples_by_group_tetrode(j).ripples;
        ripple_sel_mask = find(arrayfun(@(s) length(s.spike_locs)>=num_neuron_thres, ripples));
        for k=1:length(ripple_sel_mask)
            i = ripple_sel_mask(k);
            figure();
            subplot(2,1,1);
            hold on;
            for l=1:length(ripples_by_group_tetrode(j).tetrodes)
                tetrode_idx = find([lfp_ripple_band_by_tetrode(:).tetrode]==ripples_by_group_tetrode(j).tetrodes(l));
                plot(linspace(ripples(i).start_sec-plot_window_offset, ripples(i).end_sec+plot_window_offset, ripples(i).length_idx+1), ...
                    lfp_ripple_band_by_tetrode(tetrode_idx).lfp_ripple_band(ripples(i).start_idx:ripples(i).end_idx));
            end
            hold off
            xlim([ripples(i).start_sec-plot_window_offset, ripples(i).end_sec+plot_window_offset]);
            legend(strcat('Tetrode ', cellstr(num2str(ripples_by_group_tetrode(j).tetrodes'))));
            xlabel('Time (sec)');
            ylabel('Voltage ')
            subplot(2,1,2);
            hold on;
            for l=1:length(ripples(i).spike_locs)
                raster(ripples(i).spike_locs{l}, l-1, 'k', []);
            end
            hold off;
            xlim([ripples(i).start_sec-plot_window_offset, ripples(i).end_sec+plot_window_offset]);
            ylim([0, length(ripples(i).spike_locs)]);
            yticks((1:length(ripples(i).spike_locs))-0.5);
            yticklabels(cellfun(@(p) sprintf('Tet.%dNeu.%d', p(1), p(2)), num2cell(ripples(i).neuron_ids, 2), 'UniformOutput', false));
            xlabel('Time (sec)');
            ylabel('Putative neuron')
        end
    end
    %}
end