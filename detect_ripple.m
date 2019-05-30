function [lfp_ripple_band, ripples] = detect_ripple(lfp, smpl_rate, start_time, algo_option_str, draw_scalogram)
    ripples = struct('peak_idx', nan, 'start_idx', nan, 'end_idx', nan, 'length_idx', nan, ...
        'peak_sec', nan, 'start_sec', nan, 'end_sec', nan, 'length_sec', nan);
    ripples(1) = []; 
    
    % 32th-order Parks-McClellan FIR equi-ripple filter
    % Pass band 150~250Hz w. transition 50Hz each side
    filt_coeffs = firpm(32, ...
        [0, 100, 150, 250, 300, smpl_rate/2]./(smpl_rate/2), ...
        [0, 0, 1, 1, 0, 0]); 
    lfp_ripple_band = filtfilt(filt_coeffs, 1, lfp);
    
    if strcmp(algo_option_str, 'wilson07')
        lfp_std = std(lfp_ripple_band);
        ripple_candidates = find(abs(lfp_ripple_band) > 3*lfp_std);
        ripple_event_mask = diff(ripple_candidates) < smpl_rate*0.05;

        num_of_events = 0;
        for i=1:length(ripple_event_mask)
            if ripple_event_mask(i) == false
                num_of_events = num_of_events + 1;
                ripples(num_of_events).start_idx = ripple_candidates(i);
                ripples(num_of_events).end_idx = ripples(num_of_events).start_idx + 1;
                ripples(num_of_events).peak_idx = 0;
                
                if i == length(ripple_event_mask)
                    num_of_events = num_of_events + 1;
                    ripples(num_of_events).start_idx = ripple_candidates(i+1);
                    ripples(num_of_events).end_idx = ripples(num_of_events).start_idx + 1;
                    ripples(num_of_events).peak_idx = 0;
                end
            else
                if i == 1
                    num_of_events = num_of_events + 1;
                    ripples(num_of_events).start_idx = ripple_candidates(i);
                    ripples(num_of_events).peak_idx = 0;
                elseif ripple_event_mask(i-1) == false
                    num_of_events = num_of_events + 1;
                    ripples(num_of_events).start_idx = ripple_candidates(i);
                    ripples(num_of_events).peak_idx = 0;
                end

                if i == length(ripple_event_mask)
                    ripples(num_of_events).end_idx = ripple_candidates(i+1);
                elseif ripple_event_mask(i+1) == false
                    ripples(num_of_events).end_idx = ripple_candidates(i+1);
                end
            end
        end
        
        ripple_peaks = find(abs(lfp_ripple_band) > 7*lfp_std);
        for i=1:length(ripple_peaks)
            for j = 1:length(ripples)
                if ripple_peaks(i) >= ripples(j).start_idx && ripple_peaks(i) < ripples(j).end_idx
                    ripples(j).peak_idx = max(ripples(j).peak_idx, ripple_peaks(i)); 
                    ripples(j).length_idx = ripples(j).end_idx - ripples(j).start_idx;
                end
            end
        end
        ripples(~[ripples(:).peak_idx]) = [];
        
    elseif strcmp(algo_option_str, 'karlsson09')
        lfp_ripple_band_mean = mean(lfp_ripple_band);
        [lfp_ripple_envelope, ~] = envelope(lfp_ripple_band);
        % Original paper uses Gaussian window with 4ms s.t.d.. MATLAB's
        % smoothdata function uses gaussian window with s.t.d. that is
        % fixed at 1/5 of the window length. 
        lfp_ripple_envelope = smoothdata(lfp_ripple_envelope, 'gaussian', uint8(smpl_rate*0.004*5)); 
        cross_threshold_mask = lfp_ripple_envelope > (lfp_ripple_band_mean + 3*std(lfp_ripple_envelope));
        ripple_candidates_start = find(diff(cross_threshold_mask) == 1) + 1;
        ripple_candidates_end = find(diff(cross_threshold_mask) == -1) + 1;
        for i=1:length(ripple_candidates_start)
            ripples(i).start_idx = ripple_candidates_start(i);
            ripples(i).end_idx = ripple_candidates_end(i);
            ripples(i).length_idx = ripples(i).end_idx - ripples(i).start_idx; 
            ripples(i).peak_idx = nan;
        end
        ripples([ripples(:).length_idx]<smpl_rate*0.040) = [];
    else
        fprintf("Select ripple search method as either 'wilson07' or 'karlsson09'\n");
        return; 
    end
    
    % Generate wavelet transform magnitude scalogram of the raw LFP to confirm the result
    if draw_scalogram
        for i=1:length(ripples)
            figure(1);
            cwt(lfp_ripple_band((ripples(i).start_idx-uint32(smpl_rate*0.05)):(ripples(i).end_idx+uint32(smpl_rate*0.05))),'amor', smpl_rate);
            pause(3);
        end
    end
    
    % Convert time from index to second
    for i=1:length(ripples)
        ripples(i).peak_sec = start_time + (ripples(i).peak_idx - 1)/smpl_rate;
        ripples(i).start_sec = start_time + (ripples(i).start_idx - 1)/smpl_rate;
        ripples(i).end_sec = start_time + (ripples(i).end_idx - 1)/smpl_rate;
        ripples(i).length_sec = ripples(i).end_sec - ripples(i).start_sec;
    end   
    
    if isempty(ripples)
        ripples = [];
    end
end