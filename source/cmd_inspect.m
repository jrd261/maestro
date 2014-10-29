function  cmd_inspect(args)

% Got to fix the *.fits bug here. 
Fits = FITS(args.fileName{1});



mtalk('\n ');
mtalk([num2str(length(Fits)),' FITS files to inspect...\n\n']);
mtalk('[NAME|MEAN|MEDIAN|STD]\n\n');
for Fit = Fits
    mtalk([Fit.FileObject.Name,'\t\t',num2str(Fit.PrimaryImageMean),'\t',num2str(Fit.PrimaryImageMedian),'\t',num2str(Fit.PrimaryImageSTD)]);    
    if ~isempty(args.keyName)
        for i = 1:length(args.keyName)
            mtalk(['    ',Fit.getheaderval(Fit.PrimaryHeader,args.keyName{i},'.*')]);             
        end       
    end
    mtalk('\n');
end
return
