function coeff = diceParcel(parcelV,funcV,mriSize)
% Takes an array of parcel vertices A and compares with vertices B
% Outputs the Dice coefficient for that parcel

parcelMap = false(mriSize);
    parcelMap(parcelV) = 1;
funcMap = false(mriSize);
    funcMap(funcV) = 1;
coeff = dice(parcelMap,funcMap);

end