% count the the number of ripples/spikes before the animal makes a decision
clear;clc
for day=3:10
    for epoch=[2,4,6]
result_dir='../results/bon_mat/';
data_dir='../dataset/Bon/';
name='bon';
[pos_t,pos_p,pos_v,sp_all]=load_data(data_dir,name,day,epoch);
load([result_dir,'ripples-day_',num2str(day),'-epoch_',num2str(epoch),'.mat'])
% load([result_dir,'spikes_in_ripple_all-day_',num2str(day),'-epoch_',num2str(epoch),'.mat'])
load([result_dir,name,'choice',num2str(day),'-',num2str(epoch),'.mat'])


% % define decision region
if strcmp(name,'con')
    decision_region=[10,45,48,85];
elseif strcmp(name,'bon')
    if epoch==2 || epoch==4
        decision_region=[58,95,50,110]; % min_x,max_x,min_y,max_y
    elseif epoch==6
        if day==3
            decision_region=[205,240,105,140];
        else
            decision_region=[205,240,105,145];
        end
    end
end
% % visualize
% figure; hold on
% plot(pos_p(:,1),pos_p(:,2),'b')
% plot([decision_region(1),decision_region(2)],[decision_region(3),decision_region(3)],'r')
% plot([decision_region(1),decision_region(2)],[decision_region(4),decision_region(4)],'r')
% plot([decision_region(1),decision_region(1)],[decision_region(3),decision_region(4)],'r')
% plot([decision_region(2),decision_region(2)],[decision_region(3),decision_region(4)],'r')
% title('decision region')

% %  find the time when decision is made
% region - target region
% time - when the animal leaves the decision region
% duration - animal stays inside the decision region (max trace-back time)
% correct - if the choice is correct (the first two entries are always 0)
% ripples - number of ripples
decision=struct('region',0,'time',0,'duration',0,'correct',-1,'ripples',0,'spikes_1sec',0,'spikes_all',0);
n_choice=size(choice,1);
for d=2:n_choice
    decision(d).region=choice(d,1);
    if d>2 && choice(d-1,1)==0 && choice(d-2,1)==-choice(d,1)  % correct choice of L/R
        decision(d).correct=1;
    elseif d>2 && choice(d-1,1)==0 && choice(d-2,1)==choice(d,1)
        decision(d).correct=0;
    else
        decision(d).correct=-1;
    end
    t1=choice(d-1,3);
    t2=choice(d,2);
    a=pos_p(t1:t2,1)>decision_region(1) & pos_p(t1:t2,1)<decision_region(2) &...
        pos_p(t1:t2,2)>decision_region(3) & pos_p(t1:t2,2)<decision_region(4) ;
    b=find(a==1)+t1;
%     figure; hold on
%     plot(pos_p(t1:t2,1),pos_p(t1:t2,2),'k')
%     plot(pos_p(b,1),pos_p(b,2),'r')
    decision(d).time=pos_t(max(b));
    decision(d).duration=pos_t(max(b))-pos_t(min(b));
    decision(d).ripples=0;
    decision(d).spikes_1sec=0;
    decision(d).spikes_all=0;
end

% % count ripples
max_time=1; % sec
for g=1:length(ripples_by_group_tetrode)
    for r=1:length(ripples_by_group_tetrode(g).ripples)
        t=ripples_by_group_tetrode(g).ripples(r).start_sec; % only look at ripple start time
        for d=2:n_choice
            if t<decision(d).time
                if t>decision(d).time-min(decision(d).duration,max_time)
                    decision(d).ripples=decision(d).ripples+1;
                    decision(d).spikes_1sec=decision(d).spikes_1sec+size(ripples_by_group_tetrode(g).ripples(r).neuron_ids,1);
                end
                if t>decision(d).time-decision(d).duration % all ripples in decision region
                    decision(d).spikes_all=decision(d).spikes_all+size(ripples_by_group_tetrode(g).ripples(r).neuron_ids,1);
                end
                break % counted or cannot count, continue to next ripple
            end
        end
    end
end

save([result_dir,name,'_decision-day',num2str(day),'-epoch',num2str(epoch)],'decision')

    end
end

%% spike count during ripples (1 sec vs. decision region)
spike_count=struct('day',[],'epoch',[],'ripples',[],'spikes_1sec',[],'spikes_all',[],'correct',[]);
n_data=0;
for day=3:10
    for epoch=[2,4]
        load([result_dir,name,'_decision-day',num2str(day),'-epoch',num2str(epoch)])

        for d=3:length(decision) % first choice (d=2) is ignored (cannot determine correctness)
            if decision(d).correct==1 % correct choice
                n_data=n_data+1;
                spike_count(n_data).day=day;
                spike_count(n_data).epoch=epoch;
                spike_count(n_data).ripples=decision(d).ripples;
                spike_count(n_data).spikes_1sec=decision(d).spikes_1sec;
                spike_count(n_data).spikes_all=decision(d).spikes_all/decision(d).duration;
                spike_count(n_data).correct=1;
            elseif decision(d).correct==0 % incorrect choice from any
                n_data=n_data+1;
                spike_count(n_data).day=day;
                spike_count(n_data).epoch=epoch;
                spike_count(n_data).ripples=decision(d).ripples;
                spike_count(n_data).spikes_1sec=decision(d).spikes_1sec;
                spike_count(n_data).spikes_all=decision(d).spikes_all/decision(d).duration;
                spike_count(n_data).correct=0;
            end
        end

    end
end

save([result_dir,name,'_spike_count.mat'],'spike_count')

%% plot spike rate during SWRs
load([result_dir,name,'_spike_count.mat'],'spike_count')
data=cell2mat(reshape(struct2cell(spike_count),6,length(spike_count))');
figure; hold on
data_range=find(data(:,1)>6);
gscatter(data(data_range,4),data(data_range,5),data(data_range,6),'rb','xo')
title('spike rate during ripples')
xlabel('in 1 second before action')
ylabel('in decision region')

%% plot animal's performance
result_dir='../results/bon_mat/';
acc=zeros(8,2);
for  day=3:10
    for epoch=[2,4]
        load([result_dir,name,'_decision-day',num2str(day),'-epoch',num2str(epoch)])
        data=cell2mat(reshape(struct2cell(decision),7,length(decision))');
        correct=sum(data(:,4)==1);
        total=sum(data(1:end-1,1)==0);
        acc(day-2,epoch/2)=correct/total;
    end
end
plot(acc)