figure; plot(pos_p(:,1),pos_p(:,2),'Color', [.6 .6 .6])
title(['animal trajectory day ',num2str(day),' epoch ',num2str(epoch)],'FontSize',16)
xlim([20,130]); ylim([50,170])
hold on
decision_region=[58,92,55,110];
plot([decision_region(1),decision_region(2)],[decision_region(3),decision_region(3)],'k','LineWidth',2)
plot([decision_region(1),decision_region(2)],[decision_region(4),decision_region(4)],'k','LineWidth',2)
plot([decision_region(1),decision_region(1)],[decision_region(3),decision_region(4)],'k','LineWidth',2)
plot([decision_region(2),decision_region(2)],[decision_region(3),decision_region(4)],'k','LineWidth',2)

viscircles([37,140],13)
viscircles([72,141],13)
viscircles([108,142],13)
 
xticks([40,75,110])
xticklabels({'L','M','R'})
yticks([])