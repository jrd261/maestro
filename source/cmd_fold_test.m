function cmd_fold_test(args)
    

   p = args.period;   
   nnn = args.polynomial;
   II = args.iterations;
   t0 = args.offset;
   
   if isempty(II)
       II = 10;
   end
   
   if isempty(nnn)
       nnn = 3;
   end
   
   if isempty(t0)
       
       
   end
   
   files = FILE(args.fileName,'allowdirectories',false);    
   data = cell(length(files),1);
    
    N = 0;
    for i=1:length(files)
        data{i} = str2double(mread(files(i).FullName));
        N = N + length(data{i}(:,1));        
    end
    
    if isempty(t0)
        t0 = Inf;
        for i=1:length(data)
            t0 = min(t0,min(data{i}(:,1)));        
        end
    end
    
    NN = round(N/10); 
    X = (1:NN)';    
    Y = nan(NN,length(data));
    for i=1:length(data)
        data{i}(:,1) = data{i}(:,1) - t0;
        data{i}(:,3) =  mod(data{i}(:,1),p)/p*(NN-1) + 1;                
    end
   
   
    
   
   for k=1:II
    for i=1:length(data)
        ai = round(data{i}(:,3));
        for j=1:NN            
            Y(j,i) = nanmean(data{i}(ai==j,2));      
        end        
    end    
    model = [X,nanmean(Y,2)];
    

    for i=1:length(data)
        y = interp1(model(:,1),model(:,2),data{i}(:,3),'pchip','extrap') - data{i}(:,2);
        x = data{i}(:,1);
        x = x - mean(x);              
        par = polyfit(x,y,nnn);
      
        data{i}(:,2) = data{i}(:,2) + polyval(par,x)/2;
                              
    end
   end
%        hold off
%     for i=1:length(data)
%         if mod(i,3) == 1
%             plot(data{i}(:,3),data{i}(:,2),'bo');
%         elseif mod(i,3) == 2
%           plot(data{i}(:,3),data{i}(:,2),'ro');
% 
%         else
%      plot(data{i}(:,3),data{i}(:,2),'go');
% 
%         end
%         
%         hold on
%     end
%     plot(model(:,1),model(:,2),'ko');
%     hold off
%     keyboard 
   
   out = [];
   for i=1:length(data)
      X = (data{i}(:,3) - 1)/(NN-1);
      Y = data{i}(:,2);
       
      out  = [out;[X,Y]];
   end
   
   
   
    
    save folded out -ASCII -DOUBLE




end