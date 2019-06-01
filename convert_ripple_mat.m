function spikes_in_ripple_all = convert_ripple_mat(ripples_by_group_tetrode)
    spikes_in_ripple_all = struct('tetrode', nan, 'neuron', nan, 'start_sec', nan, 'end_sec', nan, 'length_sec', nan, 'spike_sec', nan);
    num_spikes = 0;
    for i=1:length(ripples_by_group_tetrode)
        ripples = ripples_by_group_tetrode(i).ripples; 
        for j=1:length(ripples)
            neurons = ripples(j).spike_locs;
            if isempty(neurons)
                continue;
            else
                for k=1:length(neurons)
                    spikes = neurons{k};
                    for l=1:length(spikes)
                        num_spikes = num_spikes + 1;
                        spikes_in_ripple_all(num_spikes).tetrode = ripples(j).neuron_ids(k, 1);
                        spikes_in_ripple_all(num_spikes).neuron = ripples(j).neuron_ids(k, 2);
                        spikes_in_ripple_all(num_spikes).start_sec = ripples(j).start_sec;
                        spikes_in_ripple_all(num_spikes).end_sec = ripples(j).end_sec; 
                        spikes_in_ripple_all(num_spikes).length_sec = ripples(j).length_sec;
                        spikes_in_ripple_all(num_spikes).spike_sec = spikes(l);
                    end
                end
            end
        end
    end
    
    spikes_in_ripple_table = struct2table(spikes_in_ripple_all);
    spikes_in_ripple_table = sortrows(spikes_in_ripple_table, [1,2,3,6]);
    spikes_in_ripple_all = table2struct(spikes_in_ripple_table);
end