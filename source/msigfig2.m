function [XS2,XE2] = msigfig2(X,E)  

if X < 0
 mark = true;
else
mark = false;
end
X = abs(X);
E = abs(E);

%A = 10.^(floor(log10(E)));
%E1 = feval('round',E./A).*A;
%E1(find(E==0)) = 0;
%E = E1;

NX = regexp(num2str(X,'%.0E'),'E.*','match'); 
NX = eval(NX{1}(2:length(NX{1})));

NE = regexp(num2str(E,'%.0E'),'E.*','match'); 
NE = eval(NE{1}(2:length(NE{1})));

X = round(X*10^-NE)/10^-NE;
E = round(E*10^-NE)/10^-NE;

a = num2str(X,'%20.10f');
b = num2str(E,'%20.10f');

%a

%b

if NE < 1
   XE2 = b(1:-NE+2);
   if NX < 1      
      XS2 = a(1:-NE+2);      
   else
     XS2 = a(1:NX+2-NE);       
   end
else
    if NX < 0
       XS2 = a(1);
    else 
      XS2 = a(1:NX+1);   
    end
    XE2 = b(1:NE+1);
end
%NE
%NX
%XS2
if XS2(length(XS2)) == '.'
XS2(length(XS2)) = [];
end
if XE2(length(XE2)) == '.'
XE2(length(XE2)) = [];
end

if mark && ~strcmp(XS2,'0')
   XS2 = ['-',XS2];

end

  

end
