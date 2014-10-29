function mrenderplot(filename,varargin)




%pp = get(gcf,'PaperPosition');
set(gcf,'PaperPositionMode','manual');
set(gcf,'PaperPosition',[0,0,4*1.618,4])
%set(gcf,'PaperType','usletter')




print(gcf,'-depsc',filename,'-loose')

end
