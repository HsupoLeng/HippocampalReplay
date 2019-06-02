clear; close all; 
day = 4; epoch = 2; start_choice_idx = 1; 
spikes_in_ripple_all = detect_ripple_demo(day, epoch);
choice = place_cell_choice(day, epoch);
[spatial_firing_rate_by_unit, p_min] = place_cell_spatial_firing_rate(day, epoch);
[accuracy, samples] = predict_location_with_place_cell_firing_map(day, epoch, start_choice_idx);
