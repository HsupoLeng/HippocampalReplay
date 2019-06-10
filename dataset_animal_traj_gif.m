clear; clc
data_dir='../dataset/Bon/';
name='bon';
day=4;
epoch=2;
[pos_t,pos_p,pos_v,sp_all]=load_data(data_dir,name,day,epoch);

load(['../results/bon_mat/',name,'choice',num2str(day),'-',num2str(epoch),'.mat'])

%%
figure; plot(pos_p(:,1),pos_p(:,2),'Color', [.6 .6 .6])
title(['animal trajectory day ',num2str(day),' epoch ',num2str(epoch)])
xlim([20,130]); ylim([50,170])

%%
filename = '../results/correct_traj.gif';
h=figure;
for i=23000:10:26000
    hold off
    plot(pos_p(:,1),pos_p(:,2),'Color', [.8 .8 .8])
    hold on
    plot(pos_p(i:i+50,1),pos_p(i:i+50,2),'b')
    xlim([20,130]); ylim([50,170])
    xticks([40,75,110])
    xticklabels({'L','M','R'})
    yticks([])
    title(['animal trajectory ',num2str(i/30,'%.1f'),'s'])
    drawnow limitrate;
    
    frame=getframe(h);
    im=frame2im(frame);
    [A,map] = rgb2ind(im,256);
    if i == 23000
        imwrite(A,map,filename,'gif','LoopCount',Inf,'DelayTime',0.01);
    else
        imwrite(A,map,filename,'gif','WriteMode','append','DelayTime',0.01);
    end

end

