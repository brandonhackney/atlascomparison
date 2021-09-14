function coeff = diceParcel(parcelV,funcV,mriSize)
% Takes an array of parcel vertices A and compares with GLM vertices B
% Outputs the Dice coefficient for that parcel

% mriSize = [mriSize,1];
% parcelMap = false(mriSize);
%     parcelMap(parcelV) = 1;
% funcMap = false(mriSize);
%     funcMap(funcV) = 1;
% coeff = dice(parcelMap,funcMap);
% dice() doesn't show up until rev2017b - improvising for rev2017a
coeff = (2 * length(intersect(parcelV,funcV))) / (length(parcelV) + length(funcV));

end