function ripples = detect_ripple(lfp, smpl_rate, algo_option_str, draw_scalogram)
    ripples = struct('peak', nan, 'start', nan, 'end', nan, 'length', nan);
    ripples(1) = []; 
    
    % 64th-order Parks-McClellan FIR equi-ripple filter
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
                ripples(num_of_events).start = ripple_candidates(i);
                ripples(num_of_events).end = ripples(num_of_events).start + 1;
                ripples(num_of_events).peak = 0;
                
                if i == length(ripple_event_mask)
                    num_of_events = num_of_events + 1;
                    ripples(num_of_events).start = ripple_candidates(i+1);
                    ripples(num_of_events).end = ripples(num_of_events).start + 1;
                    ripples(num_of_events).peak = 0;
                end
            else
                if i == 1
                    num_of_events = num_of_events + 1;
                    ripples(num_of_events).start = ripple_candidates(i);
                    ripples(num_of_events).peak = 0;
                elseif ripple_event_mask(i-1) == false
                    num_of_events = num_of_events + 1;
                    ripples(num_of_events).start = ripple_candidates(i);
                    ripples(num_of_events).peak = 0;
                end

                if i == length(ripple_event_mask)
                    ripples(num_of_events).end = ripple_candidates(i+1);
                elseif ripple_event_mask(i+1) == false
                    ripples(num_of_events).end = ripple_candidates(i+1);
                end
            end
        end
        
        ripple_peaks = find(abs(lfp_ripple_band) > 7*lfp_std);
        for i=1:length(ripple_peaks)
            for j = 1:length(ripples)
                if ripple_peaks(i) >= ripples(j).start && ripple_peaks(i) < ripples(j).end
                    ripples(j).peak = max(ripples(j).peak, ripple_peaks(i)); 
                    ripples(j).length = ripples(j).end - ripples(j).start;
                end
            end
        end
        ripples(~[ripples(:).peak]) = [];
        
    elseif strcmp(algo_option_str, 'karlsson09')
        lfp_ripple_envelope = envelope(lfp_ripple_band);
        lfp_ripple_envelope = smoothdata(lfp_ripple_envelope, 'gaussian', uint8(smpl_rate*0.004));
        cross_threshold_mask = lfp_ripple_envelope > (mean(lfp_ripple_envelope) + 3*std(lfp_ripple_envelope));
        ripple_candidates_start = find(diff(cross_threshold_mask) == 1) + 1;
        ripple_candidates_end = find(diff(cross_threshold_mask) == -1) + 1;
        for i=1:length(ripple_candidates_start)
            ripples(i).start = ripple_candidates_start(i);
            ripples(i).end = ripple_candidates_end(i);
            ripples(i).length = ripples(i).end - ripples(i).start; 
            ripples(i).peak = nan;
        end
        ripples([ripples(:).length]<smpl_rate*0.015) = [];
    else
        fprintf("Select ripple search method as either 'wilson07' or 'karlsson09'\n");
        return; 
    end
    
    % Generate wavelet transform magnitude scalogram of the raw LFP to confirm the result
    if draw_scalogram
        for i=1:length(ripples)
            figure(1);
            cwt(lfp_ripple_band((ripples(i).start-uint32(smpl_rate*0.5)):(ripples(i).end+uint32(smpl_rate*0.5))),'amor', smpl_rate);
            pause(3);
        end
    end
end