function choosemasterfield(HSPReduction)
%CHOOSEMASTERFIELD Summary of this function goes here
%   Detailed explanation goes here


% Extract some information.
MasterFieldArray = HSPReduction.MasterFieldArray;
FieldSolutions = HSPReduction.FieldSolutions;



solutionIndex =  mode([FieldSolutions.FieldIndex]);



MasterFieldArray = MasterFieldArray(solutionIndex);





for iSolution = 1:length(FieldSolutions)
    if FieldSolutions(iSolution).FieldIndex == solutionIndex
        FieldSolutions(iSolution).FieldIndex = 1;
    else
        FieldSolutions(iSolution).WasFound = false;
    end
    
    
end


HSPReduction.MasterFieldArray = MasterFieldArray;
HSPReduction.FieldSolutions = FieldSolutions;




end

