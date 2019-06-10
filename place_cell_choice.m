function choice = place_cell_choice(animal, day, epoch)
    data_dir= fullfile('../dataset', animal);
    %name='bon';
    %day=4;
    %epoch=4;
    [pos_t,pos_p,pos_v,sp_all]=load_data(data_dir,animal,day,epoch);
    tetrode_all=find(~cellfun(@isempty,sp_all));

    %% animated plot of animal's trajectory
% 
%     figure;
%     for i=1:length(pos_t)-50
%          plot(pos_p(i:i+50,1),pos_p(i:i+50,2))
%          xlim([20,140]);ylim([40,180]);
%          title(num2str(i))
%          drawnow limitrate;
%     end

    %% animal's choice
    xleft=55;    % x<55 is left
    xright=90;   % x>90 is right
    ycheck=110; % check region if y>110
    in_left=(pos_p(:,2)>ycheck).*(pos_p(:,1)<xleft);
    in_right=(pos_p(:,2)>ycheck).*(pos_p(:,1)>xright);
    in_mid=(pos_p(:,2)>ycheck).*(pos_p(:,1)>xleft).*(pos_p(:,1)<xright);
    in_t = (pos_p(:,2)<ycheck-10).*(pos_p(:,1)>xleft).*(pos_p(:,1)<xright);
    % % check with plots
    % `;
    % scatter(pos_p(in_left==1,1),pos_p(in_left==1,2),'x')
    % xlim([20,140]);ylim([40,180]);
    % hold on
    % scatter(pos_p(in_right==1,1),pos_p(in_right==1,2),'xr')
    % scatter(pos_p(in_mid==1,1),pos_p(in_mid==1,2),'xm')

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
            if in_left(t); choice_all=[choice_all;-1,t,t]; in_region=1;end
            if in_mid(t); choice_all=[choice_all;0,t,t]; in_region=1;end
            if in_right(t); choice_all=[choice_all;1,t,t]; in_region=1;end
            if in_t(t); choice_all=[choice_all; 7,t,t]; in_region=1;end
        else
            if ~(in_left(t)+in_mid(t)+in_right(t)+in_t(t)) % not in any region, leave
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
        if choice_all(i,1) == 7 % Do not combine T-region
            choice = [choice; choice_all(i, :)];
            region=choice_all(i,1);
        else    
            if choice_all(i,1)==region
                choice(end,3)=choice_all(i,3);
            else
                choice=[choice;choice_all(i,:)];
                region=choice_all(i,1);
            end
        end
    end
    choice(end,3)=choice(end,3)-1;
    clearvars choice_all
    save(['../results/',animal,'choice',num2str(day),'-',num2str(epoch),'.mat'],'choice')
end













