function [XS,XE,XS2,XE2] = msigfig(X,E)

	 E = abs(E);

  NX = regexp(num2str(X,'%.1E'),'E.*','match'); NX = eval(NX{1}(2:length(NX{1})));
  NE = regexp(num2str(E,'%.1E'),'E.*','match'); NE = eval(NE{1}(2:length(NE{1})));

  XS = num2str(X,['%.',num2str(NX-NE,'%i'),'E']);
  XE = num2str(E,'%.0E');  
 

  NX = regexp(num2str(X,'%.0E'),'E.*','match'); NX = eval(NX{1}(2:length(NX{1})));
  NE = regexp(num2str(E,'%.0E'),'E.*','match'); NE = eval(NE{1}(2:length(NE{1})));

  a = num2str(roundn(X,NE),'%20.10f');
  b = num2str(roundn(E,NE),'%20.10f');


%keyboard



if NE < 1

   XE2 = b(1:-NE+2);

   if NX < 1
      
      XS2 = a(1:-NE+2);
      
   else

     XS2 = a(1:NX+2-NE);
       
   end

else

    XS2 = a(1:NX+1);
    XE2 = b(1:NE+1);


end


if XS2(length(XS2)) == '.'
XS2(length(XS2)) = [];
end
if XE2(length(XE2)) == '.'
XE2(length(XE2)) = [];
end
  

end
