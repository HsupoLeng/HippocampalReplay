clear; clc
data_dir='../dataset/Bon/';
name='bon';
day=4;
epoch=2;
[pos_t,pos_p,pos_v,sp_all]=load_data(data_dir,name,day,epoch);
tetrode_all=find(~cellfun(@isempty,sp_all));

%% animated plot of animal's trajectory

% figure;
% for i=11000:length(pos_t)-50
%      plot(pos_p(i:i+50,1),pos_p(i:i+50,2))
%      xlim([120,240]);ylim([60,180]);
% %      if strcmp(name,'bon')
% %         xlim([20,140]);ylim([40,180]);
% %     end
% %     if strcmp(name,'con')
% %         xlim([0,120]);ylim([20,120]);
% %     end
%      title(num2str(i))
%      drawnow% limitrate;
% end

%% animal's choice
% % for Bon-Track B
xleft=55;    % x<55 is left
xright=90;   % x>90 is right
ycheck=110; % check region if y>110
in_left=(pos_p(:,2)>ycheck).*(pos_p(:,1)<xleft);
in_right=(pos_p(:,2)>ycheck).*(pos_p(:,1)>xright);
in_mid=(pos_p(:,2)>ycheck).*(pos_p(:,1)>xleft).*(pos_p(:,1)<xright);

% for Bon-Track A
% yup=142;    % y>141 is up/left,133 for day 3
% ydown=100;   % y<100 is down/right, 95  for day 3
% xcheck=190; % check region if x<190
% in_left=(pos_p(:,1)<xcheck).*(pos_p(:,2)>yup);
% in_right=(pos_p(:,1)<xcheck).*(pos_p(:,2)<ydown);
% in_mid=(pos_p(:,1)<xcheck).*(pos_p(:,2)<yup).*(pos_p(:,2)>ydown);

% % for Conley-Track A
% yup=88;    % y>90 is up/left
% ydown=50;   % y<50 is down/right
% xcheck=60; % check region if x>60
% in_left=(pos_p(:,1)>xcheck).*(pos_p(:,2)>yup);
% in_right=(pos_p(:,1)>xcheck).*(pos_p(:,2)<ydown);
% in_mid=(pos_p(:,1)>xcheck).*(pos_p(:,2)<yup).*(pos_p(:,2)>ydown);

% % check with plots
figure;
% scatter(pos_p(:,1),pos_p(:,2),'.k')
hold on
scatter(pos_p(in_left==1,1),pos_p(in_left==1,2),'.b')
scatter(pos_p(in_right==1,1),pos_p(in_right==1,2),'.r')
scatter(pos_p(in_mid==1,1),pos_p(in_mid==1,2),'.m')
% if strcmp(name,'bon')
%     xlim([20,140]);ylim([40,180]);
% end
% if strcmp(name,'con')
%     xlim([0,120]);ylim([20,120]);
% end

% %  (1) check only if animal starts from mid
% choice=[]; %(time,choice)
% start_from_mid=0;
% for t=1:length(pos_t)
%     if ~start_from_mid && in_mid(t)
%         start_from_mid=1;
%     end
%     if start_from_mid
%         if in_left(t); choice=[choice;t,-1]; start_from_mid=0; end
%         if in_right(t); choice=[choice;t,1]; start_from_mid=0; end
%     end
% end

% (2) L/R/M with enter & leave time
choice_all=[]; % L/R/M enter time, leave time
in_region=0;
for t=1:length(pos_t)
    if ~in_region
        if in_left(t); choice_all=[choice_all;-1,t,0]; in_region=1;end
        if in_mid(t); choice_all=[choice_all;0,t,0]; in_region=1;end
        if in_right(t); choice_all=[choice_all;1,t,0]; in_region=1;end
    else
        if ~(in_left(t)+in_mid(t)+in_right(t)) % not in any region, leave
            in_region=0;
        else % still in a region, update leave time
            choice_all(end,3)=t+1;
        end
    end
end
% combine some records (briefly leave then come back)
choice=choice_all(1,:);
region=choice_all(1,1);
for i=2:size(choice_all,1)
    if choice_all(i,1)==region
        if choice_all(i,3)~=0
            choice(end,3)=choice_all(i,3);
        end
    else
        choice=[choice;choice_all(i,:)];
        region=choice_all(i,1);
    end
end
choice(end,3)=choice(end,3)-1;
clearvars choice_all
save(['../results/',name,'choice',num2str(day),'-',num2str(epoch),'.mat'],'choice')














