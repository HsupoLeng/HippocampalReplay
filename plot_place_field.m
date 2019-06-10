% plots for final slides
clear;clc
data_dir='../dataset/Bon/';
name='bon';
day=4;
epoch=2;
[pos_t,pos_p,pos_v,sp_all]=load_data(data_dir,name,day,epoch);

tetrode_selected=[11,10,5,1,4,13];
unit_selected=[4,1,1,10,1,4];

%% init map & count time spent in every grid
acc=0;
p_min=min(pos_p);
map_size=ceil(max(pos_p)-min(pos_p))+1;
disp(['map accuracy ', num2str(10^(-acc)),', size ',num2str(map_size)])
stay_time=zeros(map_size);
for t=1:length(pos_t)
    p=round(pos_p(t,:)-p_min,acc)+1; % p cannot be 0
    stay_time(p(1),p(2))=stay_time(p(1),p(2))+1;
end

%% background
background=zeros(map_size);
for t=1:length(pos_t)
    p=round(pos_p(t,:)-p_min,acc)+1;
    background(p(1),p(2))=1;
end
background(45:60,52:59)=ones(16,8);
background(86:97,55:80)=ones(12,80-55+1);
background(95:97,55:59)=zeros(3,5);
background(58:67,22:36)=ones(10,15);
background(44,102)=1;
filled=imfill(background,'holes');
% figure; imagesc(filled'); colormap(gray);set(gca,'YDir','normal')
bg2=1-filled;
imagesc(bg2'); colormap(gray);set(gca,'YDir','normal')

%% for selected cells
eps=1e-6;
figure;
for idx=1:length(tetrode_selected)
    tet=tetrode_selected(idx);
    unit=unit_selected(idx);
    sp_cnt=zeros(map_size);
    if ~isempty(sp_all{tet}{unit}.data)
        sp=sp_all{tet}{unit}.data(:,1);
        disp(['analyzing tetrode ',num2str(tet),', unit ',num2str(unit)])
        for i=1:size(sp,1)
            [~,pid]=min(abs(pos_t-sp(i)));
            p=round(pos_p(pid,:)-p_min,acc)+1;
            sp_cnt(p(1),p(2))=sp_cnt(p(1),p(2))+1;
        end
        fr=sp_cnt./(stay_time+eps);
        
            
        subplot(2,3,idx);
        im=imagesc(log(fr'));
        colormap(hot);set(gca,'YDir','normal')
        set(im,'AlphaData',mat2gray(filled'))
        title(['neuron',num2str(idx)])
        xticks([])
        yticks([])
    end
end

%% multimodal cell
tet=14; unit=3;
sp_cnt=zeros(map_size);
sp=sp_all{tet}{unit}.data(:,1);
disp(['analyzing tetrode ',num2str(tet),', unit ',num2str(unit)])
for i=1:size(sp,1)
    [~,pid]=min(abs(pos_t-sp(i)));
    p=round(pos_p(pid,:)-p_min,acc)+1;
    sp_cnt(p(1),p(2))=sp_cnt(p(1),p(2))+1;
end
fr=sp_cnt./(stay_time+eps);

figure;
im=imagesc(log(fr)');
colormap(hot);set(gca,'YDir','normal')
set(im,'AlphaData',mat2gray(filled'))
title(['multimodal cell'])
xticks([])
yticks([])

%% directional cell
tet=18; unit=1; % 12-3 directional; 18-1 bi-directional
sp_cnt=zeros(map_size);
sp=sp_all{tet}{unit}.data(:,1);
disp(['analyzing tetrode ',num2str(tet),', unit ',num2str(unit)])
for i=1:size(sp,1)
    [~,pid]=min(abs(pos_t-sp(i)));
    p=round(pos_p(pid,:)-p_min,acc)+1;
    sp_cnt(p(1),p(2))=sp_cnt(p(1),p(2))+1;
end
fr=sp_cnt./(stay_time+eps);

figure;
im=imagesc(log(fr'));
colormap(hot);set(gca,'YDir','normal')
set(im,'AlphaData',mat2gray(filled'))
title(['directional cell'])
xticks([])
yticks([])
block=[60,75,95,120]; % xmin,ymin, xmax,ymax
p1=round(block(1:2)-p_min,acc)+1;
p2=round(block(3:4)-p_min,acc)+1;
hold on
plot([p1(1),p1(1)],[p1(2),p2(2)],'r','LineWidth',2)
plot([p2(1),p2(1)],[p1(2),p2(2)],'r','LineWidth',2)
plot([p1(1),p2(1)],[p1(2),p1(2)],'r','LineWidth',2)
plot([p1(1),p2(1)],[p2(2),p2(2)],'r','LineWidth',2)

