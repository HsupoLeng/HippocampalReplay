function [accuracy, samples, incorrect_decision_ratio] = predict_location_with_place_cell_firing_map(animal, day, epoch, predict_opt_str, start_choice_idx, only_correct_trials)
    data_dir= fullfile('../dataset', animal);
    % name='bon';
    %day=4;
    %epoch=4;
    [pos_t,pos_p,pos_v,sp_all]=load_data(data_dir,animal,day,epoch);

    load(sprintf('../results/%schoice%d-%d.mat', animal, day, epoch), 'choice');
    load(sprintf('../results/%sspikes_in_ripple_all-day_%d-epoch_%d.mat', animal, day, epoch), 'spikes_in_ripple_all');
    load(sprintf('../results/%sspatial_firing_rate_by_unit-day_%d-epoch_%d.mat', animal, day, epoch), 'spatial_firing_rate_by_unit', 'p_min');

    % Convert time unit in choice to seconds
    for i=1:size(choice, 1)
        choice(i, 2) = pos_t(choice(i, 2));
        choice(i, 3) = pos_t(choice(i, 3));
    end

    % Uncomment this if you want to predict on part of epoch
    choice = choice(start_choice_idx:end, :);
    %% Predict decision in outbound or inbound trials
    regions = [-1, 0, 1];
    % predict_opt_str = 'outbound';
    xleft=round(55-p_min(1))+1;    % x<55 is left
    xright=round(90-p_min(1))+1;   % x>90 is right
    ycheck=round(110-p_min(2))+1; % check region if y>110

    if strcmp(predict_opt_str, 'outbound')
        trial_start = 0;
        predictor_small = @(fr_map) sum(sum(fr_map(1:xleft, :)));
        predictor_large = @(fr_map) sum(sum(fr_map(xright:end, :)));
    elseif strcmp(predict_opt_str, 'inbound_from_left')
        trial_start = -1;
        predictor_small = @(fr_map) sum(sum(fr_map(xleft:xright, :)));
        predictor_large = @(fr_map) sum(sum(fr_map(xright:end, :)));
    elseif strcmp(predict_opt_str, 'inbound_from_right')
        trial_start = 1;
        predictor_small = @(fr_map) sum(sum(fr_map(1:xleft, :)));
        predictor_large = @(fr_map) sum(sum(fr_map(xleft:xright, :)));
    else % default to outbound
        trial_start = 0;
        predictor_small = @(fr_map) sum(sum(fr_map(1:xleft, :)));
        predictor_large = @(fr_map) sum(sum(fr_map(xright:end, :)));
    end
    candidates = regions(regions~=trial_start);

    num_samples = 300;
    t_period_abs_idxs = find(choice(:,1)==7);
    t_idxs_to_remove = [];
    incorrect_decision_count = 0;
    outbound_trial_count = 0;
    inbound_trial_count = 0;
    discarded_trial_count = 0;
    for i=1:length(t_period_abs_idxs)
        prev_region_idxs = find(choice(1:t_period_abs_idxs(i), 1) ~= 7, 3, 'last');
        next_region_idx = find(choice(t_period_abs_idxs(i):end, 1) ~= 7, 1, 'first');
        if length(prev_region_idxs) < 3  || isempty(next_region_idx)
            t_idxs_to_remove = [t_idxs_to_remove, i];
            discarded_trial_count = discarded_trial_count + 1;
            continue;
        end
        
        if choice(prev_region_idxs(3), 1) ~= trial_start
            t_idxs_to_remove = [t_idxs_to_remove, i];
        end
        
        if choice(t_period_abs_idxs(i)+next_region_idx-1, 1) == trial_start
            t_idxs_to_remove = [t_idxs_to_remove, i]; 
        end
        
        if choice(prev_region_idxs(3), 1) == 0
            outbound_trial_count = outbound_trial_count + 1;
            if (length(unique(choice([prev_region_idxs(2:3); t_period_abs_idxs(i)+next_region_idx-1], 1))) ~=3) || ...
                    choice(prev_region_idxs(1), 1) ~= 0
                incorrect_decision_count = incorrect_decision_count + 1;
                if trial_start == 0 && only_correct_trials
                    t_idxs_to_remove = [t_idxs_to_remove, i]; 
                end
            end         
        else
            inbound_trial_count = inbound_trial_count + 1;
            if choice(t_period_abs_idxs(i)+next_region_idx-1, 1) ~= 0
                % incorrect_decision_count = incorrect_decision_count + 1;
                if trial_start ~= 0 && only_correct_trials
                    t_idxs_to_remove = [t_idxs_to_remove, i]; 
                end
            end
        end
    end
    
    if trial_start == 0
        other_trial_count = inbound_trial_count;
    else
        other_trial_count = outbound_trial_count;
    end
    
    t_idxs_to_remove = unique(t_idxs_to_remove);
    incorrect_decision_ratio = incorrect_decision_count/(length(t_period_abs_idxs) - discarded_trial_count - other_trial_count);
    t_period_abs_idxs(t_idxs_to_remove) = [];
    t_boundaries = choice(t_period_abs_idxs, 2:3);
    t_periods = cellfun(@(boundary) boundary(1):(1/30):boundary(2), num2cell(t_boundaries, 2), 'UniformOutput', false);
    t_periods_all = horzcat(t_periods{:});

    samples = struct('timestamp', nan, 'prev_region', nan, 'next_region', nan, 'pred_region', nan, 't_abs_idx', nan, 'prev_region_abs_idx', nan);
    rand_timestamps = randi(length(t_periods_all), num_samples, 1);
    for i=1:length(rand_timestamps)
        samples(i).timestamp = t_periods_all(rand_timestamps(i));
        t_idx = find(cellfun(@(period) any(ismember(samples(i).timestamp, period)), t_periods)); 
        t_abs_idx = t_period_abs_idxs(t_idx);
        samples(i).t_abs_idx = t_abs_idx;
        prev_region_idx = find(choice(1:t_abs_idx, 1) ~= 7, 1, 'last');
        samples(i).prev_region = choice(prev_region_idx, 1);
        samples(i).prev_region_abs_idx = prev_region_idx;
        next_region_idx = find(choice(t_abs_idx:end, 1) ~= 7, 1, 'first');
        samples(i).next_region = choice(t_abs_idx + next_region_idx -1, 1);    
    end 

    for i=1:length(samples)
        prev_spike_mask = bitand([spikes_in_ripple_all(:).start_sec] < samples(i).timestamp, ...
            [spikes_in_ripple_all(:).start_sec] > choice(samples(i).t_abs_idx, 2));
        if ~any(prev_spike_mask)
            samples(i).pred_region = nan;
            continue; 
        else
            spiking_neuron_mat = [spikes_in_ripple_all(prev_spike_mask).tetrode; spikes_in_ripple_all(prev_spike_mask).neuron]';
            [spiking_neuron_unique_mat, ~, neuron_idxs] = unique(spiking_neuron_mat, 'rows');
            num_spikes = histcounts(neuron_idxs, 'BinMethod', 'integers');
            weight_factor = num_spikes./sum(num_spikes);
            weighted_map = zeros(size(spatial_firing_rate_by_unit(1).firing_rate_map));
            for j=1:length(weight_factor)
                idx = find(bitand([spatial_firing_rate_by_unit(:).tetrode]==spiking_neuron_unique_mat(j, 1), ...
                    [spatial_firing_rate_by_unit(:).neuron]==spiking_neuron_unique_mat(j, 2)));
                weighted_map = weighted_map + weight_factor(j).*spatial_firing_rate_by_unit(idx).firing_rate_map;
            end
            [~, pred_idx] = max([predictor_small(weighted_map), predictor_large(weighted_map)]);
            samples(i).pred_region = candidates(pred_idx);
    %         figure(1);
    %         imagesc(weighted_map');
    %         colormap gray;
    %         set(gca,'YDir','normal');
        end
    end
    
    % samples()
    samples(isnan([samples(:).pred_region])) = [];
    accuracy = sum([samples(:).next_region] == [samples(:).pred_region])/length(samples);
end