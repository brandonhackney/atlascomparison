function input = conditionLabel(input, taskName)
    [~,~,~,~,~,social,motion] = getConditionFromFilename(taskName);
    for i = 1:length(input)
       input(i).motionMeanB = mean(mean(input(i).betaHat(motion,:)));
       input(i).motionMeanSD = mean(std(input(i).betaHat(motion,:)'),2);
       input(i).socialMeanB = mean(mean(input(i).betaHat(social,:)));
       input(i).socialMeanSD = mean(std(input(i).betaHat(social,:)'),2);
    end
end