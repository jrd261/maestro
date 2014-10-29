function a=  mtext(a,text,varargin)

axPos = get(gca,'Position');

xMinMax = xlim;
yMinMax = ylim;


x1 = axPos(1) + ((a(1) - xMinMax(1))/(xMinMax(2)-xMinMax(1))) * axPos(3);

y1 = axPos(2) + ((a(2) - yMinMax(1))/(yMinMax(2)-yMinMax(1))) * axPos(4);


%x2 = axPos(1) + ((b(1) - xMinMax(1))/(xMinMax(2)-xMinMax(1))) * axPos(3);

%y2 = axPos(2) + ((b(2) - yMinMax(1))/(yMinMax(2)-yMinMax(1))) * axPos(4);


%a = annotation('textarrow',[x1,x2],[y1,y2],'String',text,'headlength',6,'headwidth',6,'fontsize',8,'linestyle','-','linewidth',.25,'textcolor','k','Color','r',varargin{:});
a = annotation('textbox',[x1 y1 0 0],'string',text,'fitboxtotext','on','horizontalalignment','center','margin',0,varargin{:},'FontSize',10);
p = get(a,'Position');

set(a,'Position',[p(1)-p(3)/2,p(2)+p(4)/2,p(3),p(4)]);

set(a,'verticalalignment','bottom','linestyle','none');

%'horizontalalignment','center','verticalalignment','center',varargin{:});


end
