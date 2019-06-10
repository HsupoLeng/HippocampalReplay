clear; close all; 
animal = 'bon';
days = 3:10;
epoches = [2,4];

%% Compile number of ripples, number of ripples with concurring spikes, number of spikes in ripple across days
ripple_total_count = zeros(length(days), length(epoches));
ripple_with_spike_count = zeros(length(days), length(epoches));
spike_in_ripple_count = zeros(length(days), length(epoches));
spike_in_ripple_all_cell = cell(length(days), length(epoches));
for i=1:length(days)
    day = days(i);
    for j=1:length(epoches)
        epoch = epoches(j); 
        load(sprintf('../results/%sripples-day_%d-epoch_%d.mat', animal, day, epoch), 'ripples_by_group_tetrode');
        ripple_total_count(i, j) = sum(arrayfun(@(tet) length(tet.ripples), ripples_by_group_tetrode));
        ripple_with_spike_count(i, j) = sum(arrayfun(@(tet) sum(arrayfun(@(r) ~isempty(r.spike_locs), tet.ripples)), ripples_by_group_tetrode));
        spike_in_ripple_count(i, j) = sum(arrayfun(@(tet) sum(arrayfun(@(r) length(r.spike_locs), tet.ripples)), ripples_by_group_tetrode));
        spike_in_ripple_by_tetrode = arrayfun(@(tet) arrayfun(@(r) length(r.spike_locs), tet.ripples), ripples_by_group_tetrode, 'UniformOutput', false);
        spike_in_ripple_all_cell{i, j} = vertcat(spike_in_ripple_by_tetrode{:});
    end
end

% Visualize the result
for i=1:size(ripple_total_count, 2)
    figure();
    bar([ripple_total_count(:, i), ripple_with_spike_count(:, i), spike_in_ripple_count(:, i)]);
    xlabel('Day');
    xticklabels(cellstr(num2str(days')));
    ylabel('Number of ripples or spikes');
    legend('Total number of ripples', 'Number of ripples with concurring spikes', 'Total number of spikes in ripples');
    saveas(gcf, sprintf('../results/%sripple_spike_count_bar-epoch_%d.png', animal, epoches(i)));
end

spikes_in_ripple_all = vertcat(spike_in_ripple_all_cell{:});
histogram(spikes_in_ripple_all, 'BinLimits', [0.5, 5], 'BinMethod', 'integers');
xticks(1:5);
xlabel('Number of spikes in a ripple');
ylabel('Number of ripples');
saveas(gcf, sprintf('../results/%snum_spike_in_one_ripple-hist-epoch_%d.png', animal, epoches(i)));

%% Compile number of outbound decision regions across days
trial_start = 0; only_correct_trials = true;
outbound_decision_region_valid_count = zeros(length(days), length(epoches));
for k=1:length(days)
    day = days(k);
    for j=1:length(epoches)
        epoch = epoches(j); 
        load(sprintf('../results/%schoice%d-%d.mat', animal, day, epoch), 'choice');
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
        t_period_abs_idxs(t_idxs_to_remove) = [];
        outbound_decision_region_valid_count(k, j) = length(t_period_abs_idxs);
    end
end
mean_outbound_decision_region_valid_count = mean(outbound_decision_region_valid_count(:));
significant_raio = binoinv(1-0.05, floor(mean_outbound_decision_region_valid_count), 1/2) * 100/mean_outbound_decision_region_valid_count;