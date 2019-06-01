clear; clc
data_dir='../dataset/Bon/';
results_dir = '../results';
name='bon';
day=4;
epoch=2;
[pos_t,pos_p,pos_v,sp_all]=load_data(data_dir,name,day,epoch);
load(fullfile(results_dir, sprintf('ripples-day_%d-epoch_%d.mat', day, epoch)), 'ripples_by_group_tetrode');

%% Visualize spatial frequency of ripple occurence
acc=0; % # after decimal point
p_min=min(pos_p);
map_size=ceil(max(pos_p)-min(pos_p))+1; % fix for acc=1
disp(['map accuracy ', num2str(10^(-acc)),', size ',num2str(map_size)])
ripple_count=zeros(map_size(1), map_size(2), length(ripples_by_group_tetrode));
for i=1400:length(pos_t)
    p=round(pos_p(i,:)-p_min,acc)+1; % p cannot be 0
    for j=1:length(ripples_by_group_tetrode)
        ripples = ripples_by_group_tetrode(j).ripples;
        ripple_curr = sum(arrayfun(@(ripple) ~(ripple.end_sec<pos_t(i)||ripple.start_sec>pos_t(i)+(30/1000)) && ~isempty(ripple.spike_locs), ripples));
        ripple_count(p(1), p(2), j) = ripple_count(p(1), p(2), j) + ripple_curr;
    end
end

save(sprintf('ripple_spatial_count-day_%d-epoch_%d.mat', day, epoch), 'ripple_count');

for i=1:size(ripple_count, 3)
    figure();
    imagesc(log(ripple_count(:, :, i)'));
    set(gca,'YDir','normal');
    colormap gray;
    title(sprintf('Spatial map of ripple with spikes on tetrode group %d', i));
    colorbar;
    saveas(gcf, sprintf('../results/ripple_spatial_count-tetrode_group_%d-day_%d-epoch_%d.png', i, day, epoch));
end

figure();
imagesc(log(sum(ripple_count, 3)'));
set(gca,'YDir','normal');
colormap gray;
title('Spatial map of ripple with spikes over all tetrodes');
colorbar;
saveas(gcf, sprintf('../results/ripple_spatial_count-all-day_%d-epoch_%d.png', day, epoch));

%% animated plot of animal's trajectory, overlaid with ripple occurences
figure();
for i=1400:length(pos_t)-16
    for j=1:length(ripples_by_group_tetrode)
        ripples = ripples_by_group_tetrode(j).ripples;
        ripple_happening = any(arrayfun(@(ripple) ~(ripple.end_sec<pos_t(i)||ripple.start_sec>pos_t(i)+30*16/1000) && ~isempty(ripple.spike_locs), ripples));
        if ripple_happening
            break;
        end
    end
    if ripple_happening
        traj_color = 'r';
    else
        traj_color = 'b';
    end
    plot(pos_p(i:i+16,1),pos_p(i:i+16,2), 'Color', traj_color, 'LineWidth', 2);
    hold off;
    xlim([20,140]);ylim([40,180]);
    title(num2str(i))
    drawnow limitrate;
end