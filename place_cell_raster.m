clear; clc
data_dir='../dataset/Bon/';
name='bon';
day=4;
epoch=2;
[pos_t,pos_p,pos_v,sp_all]=load_data(data_dir,name,day,epoch);
tetrode_all=find(~cellfun(@isempty,sp_all));

%% raster plot of certain cells, with position & velocity over time
% plot(pos_p(:,1))
% for tet_id=1:length(tetrode_all)
%     tet=tetrode_all(tet_id);
%     unit_all=find(~cellfun(@isempty,sp_all2{tet});
%     for unit_id=1:length(unit_all)
%         unit=unit_all(unit_id);
%         
%     end
% end
figure;
x_range=[18000,27000];
subplot(3,1,1)
plot(pos_p)
xlim(x_range)
xticks([])
ylabel('distance')

subplot(3,1,3)
plot(pos_v)
xlim(x_range)
xlabel('time (s)')
xtickpos=x_range(1):1000:x_range(2);
xticks(xtickpos)
xticklabels(xtickpos/30)
ylabel('velocity')

subplot(3,1,2)
hold on
% tetrode_selected=[5,19,4,13,12];
% unit_selected=[1,2,1,4,2];
tetrode_selected=[11,14,10,5,1];
unit_selected=[4,4,1,1,10];
for id=1:length(tetrode_selected)
    tet=tetrode_selected(id);
    unit=unit_selected(id);
    sp=sp_all{tet}{unit}.data(:,1);
%     fr=zeros(size(pos_t));
%     for i=1:length(pos_t)
%             fr(i)=sum((sp>=pos_t(i)-1/60).*(sp<pos_t(i)+1/60));
%     end
    for s=1:length(sp)
        [~,pid]=min(abs(pos_t-sp(s)));
        plot([pid,pid],[id-1,id],'b')
    end
end
xlim(x_range)
xticks([])
ylabel('neurons')
% plot(fr)