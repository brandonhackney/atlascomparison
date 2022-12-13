function position = nestedPosition(indOuter,indInner,maxInner)
% When generating an array that loops over two variables at once,
% and collapses into a single dimension (e.g. A1 A2 A3 B1 B2 etc.)
% this function will calculate the current position in that stack.
%
% indOuter is the current index of the top-level loop
% indInner is the current index of the inner loop
% maxInner is the maximum value of the inner loop
%
% e.g. if you loop for a = 1:A, for b = 1:B,
% thisRow = nestedPosition(a, b, B)

position = maxInner * (indOuter - 1) + indInner;

end
