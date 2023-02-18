function [top, bottom] = topandbottomX(data, number)
% Given an input array, find the top x values and bottom x values
% Returns the indices from the array, not the values themselves
% Get the values by using the outputs to index from your input

assert(strcmp(class(number),'double'), 'Second input must be a number')
assert((number > 0) && (round(number) == number), 'Second input must be a positive integer')

% init
mu = mean(data); % Get mean for later
top = zeros([number,1]);
bottom = zeros([number, 1]);

% Iteratively find max and min values, export indices to a matrix
for i = 1:number
    thisMax = max(data);
    top(i) = find(data == thisMax);
    
    thisMin = min(data);
    bottom(i) = find(data == thisMin);
    % Replace values with mean, so we can find the next values
    data(top(i)) = mu; data(bottom(i)) = mu;
end