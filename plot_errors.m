function plot_errors(groups,bias_pct,rmse_vec,tit)
f1=figure;
if iscell(groups)
    x=1:length(groups);
else
    x=groups;
end
[ax,h1,h2]=plotyy(x,bias_pct*100,x,rmse_vec);
set([h1 h2],'LineWidth',2,'Marker','o');

set(ax(1),'YLim',[-100 100],'YTick',-100:20:100,...
    'XTick',x,'XTickLabel',groups,'XTickLabelRotation',-45);
set(ax(2),'YLim',[0 400],'YTick',0:40:400,'XTick',x,'XTickLabel',[]);

ylabel(ax(1),'Bias, %');
ylabel(ax(2),'RMSE, mm');
title(tit)
set(ax,'FontSize',15,'Ygrid','on');
text(ax(1),x(1),80,'(a)','FontSize',25);
set(f1,'Position',[100 100 900 400],'Color','w')
set(ax,'Position',[0.10 0.32 0.74 0.6])