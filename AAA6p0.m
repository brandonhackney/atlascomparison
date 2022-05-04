subjectList = [1 2 3 4 5 6 7 8 10 11];
% Do subjects 1 and 7 after you run QC and make the MTCs
% Skip subject 9 entirely - not enough data.
main(subjectList,'schaefer400');
main(subjectList,'gordon333dil');
main(subjectList,'glasser6p0');
main(subjectList,'power6p0');
classSetup;