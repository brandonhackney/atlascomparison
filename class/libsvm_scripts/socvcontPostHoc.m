% Get marginal means from anova data
% idk why it doesn't give you them to begin with
alist = unique(hms);
for a = 1:length(alist)
    atlas = alist{a};
    fprintf(1,'%s mean accuracy = %0.2f\n',atlas, mean(y(strcmp(hms,atlas))));
end


% post-hoc t-test
justLH = strcmp(hms,'RH');
justSoc = strcmp(cnd, cndList{1});
justCont = strcmp(cnd, cndList{2});
lhSoc = y(justLH & justSoc);
lhCont = y(justLH & justCont);
[~,postpval,~,postStats] = ttest(lhSoc, lhCont);

% Post-hoc anova
% What's your limiting factor?
justLH = strcmp(cnd,cndList{2});
postData = y(justLH);
% postdMatrix = {atls(justLH) hms(justLH)};
% postvarnames = {'Atlas' 'Hemisphere'};
postdMatrix = {mtrc(justLH)};
postvarnames = {'Metric'};
[postpval,posttbl,poststats] = anovan(postData,postdMatrix,'model','interaction','varnames',postvarnames);
