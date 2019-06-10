clear; close all; 
animal = 'bon';
days = 3:10;
epoches = [2,4];
predict_opt_str = 'outbound';
num_repeats = 10;

regions = [-1, 0, 1];
if strcmp(predict_opt_str, 'outbound')
    trial_start = 0;
elseif strcmp(predict_opt_str, 'inbound_from_left')
    trial_start = -1;
elseif strcmp(predict_opt_str, 'inbound_from_right')
    trial_start = 1;
else % default to outbound
    trial_start = 0;
end
candidates = regions(regions~=trial_start);
    
accuracies = zeros(length(days), length(epoches), num_repeats);
incorrect_decision_ratios = zeros(size(accuracies));
for i=1:length(days)
    day = days(i);
    for j=1:length(epoches)
        epoch = epoches(j); 
        start_choice_idx = 1; 
        spikes_in_ripple_all = detect_ripple_demo(animal, day, epoch);
        choice = place_cell_choice(animal, day, epoch);
        [spatial_firing_rate_by_unit, p_min] = place_cell_spatial_firing_rate(animal, day, epoch);
        
        decision_count = zeros(length(candidates), 2, num_repeats);
        
        for k=1:num_repeats
            [accuracies(i,j,k), samples, incorrect_decision_ratios(i,j,k)] = predict_location_with_place_cell_firing_map(animal, day, epoch, predict_opt_str, start_choice_idx, false);
            for l=1:length(candidates)
                decision_count(l, 1, k) = length(find([samples(:).next_region] == candidates(l)));
                decision_count(l, 2, k) = length(find([samples(:).pred_region] == candidates(l)));
            end
        end
        
%         figure();
%         bar(mean(decision_count, 3));
%         xticklabels({'left', 'right'});
%         ylabel('Turning decision count')
%         legend({'Actual', 'Predicted'});
%         saveas(gcf, sprintf('../results/%s-prediction_sample_count-day_%d-epoch_%d.png', animal, day, epoch));
    end
end

accuracies_daily_mean = squeeze(mean(accuracies, 3));
incorrect_decision_ratio_daily_mean = squeeze(mean(incorrect_decision_ratios, 3));
save(sprintf('../results/%sprediction_accuracy-all_days-epoch_%d_%d.mat', animal, epoches(1), epoches(2)), 'accuracies_daily_mean');
save(sprintf('../results/%sincorrect_decision_ratio-all_days-epoch_%d_%d.mat', animal, epoches(1), epoches(2)), 'incorrect_decision_ratio_daily_mean');

figure();
hold on;
plot(accuracies_daily_mean, 'LineWidth', 2);
line([1, 8], repmat(mean(accuracies_daily_mean(:,1)), 1 ,2), 'Color', 'b', 'LineStyle', '-.');
line([1, 8],  repmat(mean(accuracies_daily_mean(:,2)), 1 ,2), 'Color', 'r', 'LineStyle', '-.');
ax = gca;
ax.XAxis.FontWeight = 'bold';
ax.YAxis.FontWeight = 'bold';
ax.XAxis.FontSize = 12;
ax.YAxis.FontSize = 12;
ylabel('Prediction accuracy', 'FontWeight', 'bold', 'FontSize', 12);
ylim([0, 1]);
legend([strcat('Epoch ', cellstr(num2str(epoches'))); strcat('Epoch ', cellstr(num2str(epoches')), ' mean')], 'FontWeight', 'bold');
xlabel('Day', 'FontWeight', 'bold', 'FontSize', 12);
xticklabels(cellstr(num2str(days')));
hold off;
saveas(gcf, sprintf('../results/%s-prediction_accuracy-all_days-epoch_%d_%d.png', animal, epoches(1), epoches(2)));
%%
figure();
hold on;
plot(1-incorrect_decision_ratio_daily_mean, '--', 'LineWidth', 2);
line([1, 8], 1-repmat(mean(incorrect_decision_ratio_daily_mean(:,1)), 1 ,2), 'Color', 'b', 'LineStyle', '-.');
line([1, 8],  1-repmat(mean(incorrect_decision_ratio_daily_mean(:,2)), 1 ,2), 'Color', 'r', 'LineStyle', '-.');
ax = gca;
ax.XAxis.FontWeight = 'bold';
ax.YAxis.FontWeight = 'bold';
ax.XAxis.FontSize = 12;
ax.YAxis.FontSize = 12;
ylabel('Ratio of correct decisions', 'FontWeight', 'bold');
ylim([0, 1]);
legend([strcat('Epoch ', cellstr(num2str(epoches'))); strcat('Epoch ', cellstr(num2str(epoches')), ' mean')], 'FontWeight', 'bold');
xlabel('Day', 'FontWeight', 'bold');
xticklabels(cellstr(num2str(days')));

saveas(gcf, sprintf('../results/%s-correct_decisions_ratio-all_days-epoch_%d_%d.png', animal, epoches(1), epoches(2)));




