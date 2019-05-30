% spike count of a certain unit on different paths/regions
clear; clc
data_dir='../dataset/Bon/';
name='bon';
day=4;
epoch=2;
load(['../results/',name,'choice',num2str(day),'-',num2str(epoch),'.mat'])
[pos_t,pos_p,pos_v,sp_all]=load_data(data_dir,name,day,epoch);

tet=17;
unit=1;
sp=sp_all{tet}{unit}.data(:,1);

cnt_in_path=zeros(2,2); %[outbound L/R; inbound L/R]
cnt_in_region=zeros(1,3); % L/M/R
% figure; hold on
for s=1:length(sp)
    spt=sp(s);
%     [~,pid]=min(abs(pos_t-spt));
%     scatter(pos_p(pid,1),pos_p(pid,2))
%     if pos_p(pid,1)<40
%         pid
%     end
    for c=1:size(choice,1)
        if spt>=pos_t(choice(c,2)) && spt<pos_t(choice(c,3))
            cnt_in_region(choice(c,1)+2)=cnt_in_region(choice(c,1)+2)+1;
            break
        end
        if c>1
            if spt<pos_t(choice(c,2)) && spt>=pos_t(choice(c-1,3))
                if choice(c-1,1)==0 % outbound 0 >> -1/1
                    t=max(1,choice(c,1)+1);
                    cnt_in_path(1,t)=cnt_in_path(1,t)+1;
                    break
                end
                if choice(c,1)==0 % inbound -1/1 >> 0
                    t=max(1,choice(c-1,1)+1);
                    cnt_in_path(2,t)=cnt_in_path(2,t)+1;
                    break
                end
            end
        end
    end
end
cnt_other=length(sp)-sum(cnt_in_path(:))-sum(cnt_in_region(:));
figure;bar(cnt_in_path)
xticklabels(['outbound';' inbound'])
legend('L','R')
figure;bar(cnt_in_region)
xticklabels(['L';'M';'R'])