%% all cells, average of two epochs in a day
clear; clc
data_dir='../dataset/Bon/';
name='bon';
day=4;
[pos_t2,pos_p2,pos_v2,sp_all2]=load_data(data_dir,name,day,2);
tetrode_all2=find(~cellfun(@isempty,sp_all2));
[pos_t4,pos_p4,pos_v4,sp_all4]=load_data(data_dir,name,day,4);
tetrode_all4=find(~cellfun(@isempty,sp_all4));
tetrode_all=intersect(tetrode_all2,tetrode_all4);
clearvars tetrode_all2 tetrode_all4

% init map & count time spent in every grid
acc=0; % # after decimal point
p_min=min(min(pos_p2),min(pos_p4));
p_max=max(max(pos_p2),max(pos_p4));
map_size=ceil(p_max-p_min)+1; % fix for acc=1
disp(['map accuracy ', num2str(10^(-acc)),', size ',num2str(map_size)])

stay_time=zeros(map_size);
for t=1:length(pos_t2)
    p=round(pos_p2(t,:)-p_min,acc)+1; % p cannot be 0
    stay_time(p(1),p(2))=stay_time(p(1),p(2))+1;
end
for t=1:length(pos_t4)
    p=round(pos_p4(t,:)-p_min,acc)+1; % p cannot be 0
    stay_time(p(1),p(2))=stay_time(p(1),p(2))+1;
end

for tet_id=1:length(tetrode_all)
    tet=tetrode_all(tet_id);
    unit_all=intersect(find(~cellfun(@isempty,sp_all2{tet})), find(~cellfun(@isempty,sp_all4{tet})));
    for unit_id=1:length(unit_all)
        unit=unit_all(unit_id);
        sp_cnt=zeros(map_size);
        if ~isempty(sp_all2{tet}{unit}.data) && ~isempty(sp_all4{tet}{unit}.data)
            disp(['analyzing tetrode ',num2str(tet),', unit ',num2str(unit)])
            sp2=sp_all2{tet}{unit}.data(:,1); % spike time only for now
            for i=1:size(sp2,1)
                [~,pid]=min(abs(pos_t2-sp2(i)));
                p=round(pos_p2(pid,:)-p_min,acc)+1;
                sp_cnt(p(1),p(2))=sp_cnt(p(1),p(2))+1;
            end
            sp4=sp_all4{tet}{unit}.data(:,1); % spike time only for now
            for i=1:size(sp4,1)
                [~,pid]=min(abs(pos_t4-sp4(i)));
                p=round(pos_p4(pid,:)-p_min,acc)+1;
                sp_cnt(p(1),p(2))=sp_cnt(p(1),p(2))+1;
            end
            fr=sp_cnt./stay_time;
            figure('visible','off');
            imagesc(log(fr')); colormap(gray);set(gca,'YDir','normal')
            title(['day ',num2str(day),' tetrode ',num2str(tet),' unit ',num2str(unit)])
            saveas(gcf,['../results/',num2str(day),'-',num2str(tet),'-',num2str(unit),'.png'])
        end
    end
end