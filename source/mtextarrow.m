function a=  mtextarrow(a,b,text,varargin)

axPos = get(gca,'Position');

xMinMax = xlim;
yMinMax = ylim;


x1 = axPos(1) + ((a(1) - xMinMax(1))/(xMinMax(2)-xMinMax(1))) * axPos(3);

y1 = axPos(2) + ((a(2) - yMinMax(1))/(yMinMax(2)-yMinMax(1))) * axPos(4);


x2 = axPos(1) + ((b(1) - xMinMax(1))/(xMinMax(2)-xMinMax(1))) * axPos(3);

y2 = axPos(2) + ((b(2) - yMinMax(1))/(yMinMax(2)-yMinMax(1))) * axPos(4);


a = annotation('textarrow',[x1,x2],[y1,y2],'String',text,'headlength',6,'headwidth',6,'fontsize',10,'linestyle','-','linewidth',.25,'textcolor','k','Color','r',varargin{:});


end
