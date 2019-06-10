% spike count of a certain unit on different paths/regions
clear; clc
data_dir='../dataset/Bon/';
name='bon';
day=4;
epoch=2;
load(['../results/bon_mat/',name,'choice',num2str(day),'-',num2str(epoch),'.mat'])
[pos_t,pos_p,pos_v,sp_all]=load_data(data_dir,name,day,epoch);

tet=18;% 12-3 directional; 18-1 bi-directional; 14-3 multimodal
unit=1;%17-1, 1-10 T left; 2-4 left up; 11-4, 12-1, 12-3 middle downward// 18-1, 14-3 up/down
sp=sp_all{tet}{unit}.data(:,1);

cnt_in_path=zeros(2,2); %[outbound L/R; inbound L/R]
cnt_in_region=zeros(1,3); % L/M/R

direction=zeros(length(sp),1);

for s=1:length(sp)
    spt=sp(s);
    [~,pid]=min(abs(pos_t-spt));
    b=pos_p(pid,2)-pos_p(pid-1,2);
    a=pos_p(pid,1)-pos_p(pid-1,1);
    if a==0
        if b>0
            direction(pid)=pi/2;
        elseif b<0
            direction(pid)=-pi/2;
        end
    else
        tan_value=b/a;
        direction(pid)=atan(tan_value);
        if a<0 && b>=0
            direction(pid)=direction(pid)+pi;
        elseif a<0&& b<0
            direction(pid)=direction(pid)-pi;
        end
    end
    
    if pos_p(pid,1)<60 || pos_p(pid,1)>95 || pos_p(pid,2)<75 || pos_p(pid,2)>120
        direction(pid)=0;
    end

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
% figure;bar(cnt_in_path)
% xticklabels(['outbound';' inbound'])
% legend('L','R')
% % x-55-90,y>110
% % map 34-69,y>57
% % stay=zeros(1,3);
% % stay(1)=sum(sum(stay_time(1:33,57:end)));
% % stay(2)=sum(sum(stay_time(34:90,57:end)));
% % stay(3)=sum(sum(stay_time(91:end,57:end)));
% figure;bar(cnt_in_region,'b')
% xticklabels(['L';'M';'R'])
x=find(direction~=0);
% figure; 
polarhistogram(direction(x))
title([num2str(tet),'-',num2str(unit)])