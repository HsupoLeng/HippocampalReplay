function [spatial_firing_rate_by_unit, p_min] = place_cell_spatial_firing_rate(day, epoch)
    data_dir='../dataset/Bon/';
    name='bon';
    %day=4;
    %epoch=4;
    [pos_t,pos_p,pos_v,sp_all]=load_data(data_dir,name,day,epoch);
    tetrode_all=find(~cellfun(@isempty,sp_all));

    %% init map & count time spent in every grid
    acc=0; % # after decimal point
    p_min=min(pos_p);
    map_size=ceil(max(pos_p)-min(pos_p))+1; % fix for acc=1
    disp(['map accuracy ', num2str(10^(-acc)),', size ',num2str(map_size)])
    stay_time=zeros(map_size);
    for t=1:length(pos_t)
        p=round(pos_p(t,:)-p_min,acc)+1; % p cannot be 0
        stay_time(p(1),p(2))=stay_time(p(1),p(2))+1;
    end
    % check with figures
    % figure('Position',[800,300,1000,500]);
    % subplot(1,2,1); scatter(pos_p(:,1),pos_p(:,2),'.')
    % subplot(1,2,2); imagesc(log(stay_time')); colormap(gray);set(gca,'YDir','normal')

    %% test for all cells
    % tet_id=2;
    spatial_firing_rate_by_unit = struct('tetrode', nan, 'neuron', nan, 'firing_rate_map', []);
    num_unit = 0;
    for tet_id=1:length(tetrode_all)
        tet=tetrode_all(tet_id);
        unit_all=find(~cellfun(@isempty,sp_all{tet}));
    %     unit_id=2;
        for unit_id=1:length(unit_all)
            unit=unit_all(unit_id);
            sp_cnt=zeros(map_size);
            if ~isempty(sp_all{tet}{unit}.data) % ? consider skipping unit with little spikes
                sp=sp_all{tet}{unit}.data(:,1); % spike time only for now
                disp(['analyzing tetrode ',num2str(tet),', unit ',num2str(unit)])
                for i=1:size(sp,1)
                    [~,pid]=min(abs(pos_t-sp(i)));
                    p=round(pos_p(pid,:)-p_min,acc)+1;
                    sp_cnt(p(1),p(2))=sp_cnt(p(1),p(2))+1;
                end
                fr=sp_cnt./(stay_time+eps);
                num_unit = num_unit + 1;
                spatial_firing_rate_by_unit(num_unit).tetrode = tet;
                spatial_firing_rate_by_unit(num_unit).neuron = unit;
                spatial_firing_rate_by_unit(num_unit).firing_rate_map = fr./sum(fr(:)+eps);

                figure('visible','off');
                imagesc(log(fr')); colormap(gray);set(gca,'YDir','normal')
                title(['day ',num2str(day),' epoch ',num2str(epoch),' tetrode ',num2str(tet),' unit ',num2str(unit)])
                saveas(gcf,['../results/',num2str(day),'-',num2str(epoch),'-',num2str(tet),'-',num2str(unit),'.png'])
            end
        end
    end

    save(sprintf('../results/spatial_firing_rate_by_unit-day_%d-epoch_%d', day, epoch), 'spatial_firing_rate_by_unit', 'p_min');
end




