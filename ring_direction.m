function v = ring_direction(medpolar)

dim = size(medpolar);

v = zeros(1,dim(2)/2);
for i=1:dim(2)/2
    indx1 = (i:i+dim(2)/2-1);
    indx2 = mod(indx1 + dim(2)/2-1,dim(2))+1;
    win1 = medpolar(:,indx1);
    win2 = medpolar(:,indx2);
    m1 = repmat(mean(win1,2),[1 dim(2)/2]);
    m2 = repmat(mean(win2,2),[1 dim(2)/2]);
    %whos win1 win2 m1 m2
    v(i) = mean2(abs([win1,win2]-[m1,m2]));
end