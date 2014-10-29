function D = malign(A,B,C,Tolerance)

  D = cell(size(C));
  ai = []; 
  bi = [];
  for i=1:size(A,1)
      
      [v,j] = min(abs(A(i,1)-B(:,1)));

      if v < Tolerance

	 ai = [ai,i];
	 bi = [bi,j];

      end

  end      

  for i=1:length(C)

      D{i} = nan(size(A,1),size(C{i},2));
      D{i}(ai,:) = C{i}(bi,:);

  end

    
end
