function plot_residuals(groups,residuals,tit)
if iscell(groups)
    x=1:length(groups);
else
    x=groups;
end
xx=repmat(x,length(residuals),1);
yy=residuals;
[values, centers] = hist3([xx(:) yy(:)],...
    {x;-2000:50:2000});
f1=figure;
set(gca,'YDir','normal'); hold on;
yy=log10(values)';
yy(yy==-Inf)=NaN;
imagesc(x,centers{2},yy);
axis tight;
c=[1 10 100 1000 10000];
caxis(log10([c(1) c(length(c))]));
c=colorbar('FontSize',15,'YTick',log10(c),'YTickLabel',c);
c.Label.String='N';
freezeColors('nancolor',[1 1 1]);
xlabel('year');
ylabel('residuals, mm')
set(gca,'XTick',x,'XTickLabel',groups,'XTickLabelRotation',-45)
title(tit)
set(gca,'FontSize',15,'Ygrid','on');
text(gca,x(1),2000,'(b)','FontSize',25);
set(f1,'Position',[100 100 900 400],'Color','w')
set(gca,'Position',[0.10 0.32 0.74 0.6])