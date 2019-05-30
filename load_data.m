function [pos_t,pos_p,pos_v,sp_all]=load_data(data_dir,name,day,epoch)
    task_path=[data_dir,name,'task',num2str(day,'%02d')];
    load(task_path)
%     for epoch=1:7
    task_type=task{day}{epoch}.type;
    task_env='';
    if strcmp(task_type,'run')
        task_env=task{day}{epoch}.environment;  
    end
    data_info=['Data info: day ',num2str(day),', epoch ',num2str(epoch),', ', task_type,' ', task_env];
    disp(data_info)
%     end

    % load position
    pos_path=[data_dir,name,'pos',num2str(day,'%02d')];
    load(pos_path)
    pos_t=pos{day}{epoch}.data(:,1);
    pos_p=pos{day}{epoch}.data(:,2:3);
    pos_v=pos{day}{epoch}.data(:,6); % smooth-v
    f_pos=30; %Hz

    % load spikes
    sp_path=[data_dir,name,'spikes',num2str(day,'%02d')];
    load(sp_path)
    sp_all=spikes{day}{epoch};
end