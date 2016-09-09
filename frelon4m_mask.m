function mask=frelon4m_mask
% dead pixels from May 2006 experiment on ID22
mask=zeros(1201,1801);
hs=mask;
mask(58:525,580)=1;
mask(5:525,581:582)=1;
mask(52:155,583)=1;

mask(58:525,579)=1;

mask(1:70,580)=1;
mask(1:10,580:582)=1;
mask(53:67,583:584)=1;

% hotspots
hs(251,164)=1;
hs(20,143)=1;
hs(366,126)=1;
hs(194,571)=1;
hs(236,1414)=1;
hs(145,1496)=1;
hs(168,1409)=1;
hs(116,1592)=1;
hs(156,1586)=1;
hs(116,1650)=1;
hs(366,1439)=1;
hs(438,1431)=1;
hs(421,1450)=1;
hs(469,1395)=1;
hs(214,1604)=1;
hs(674,188)=1;
hs(671,144)=1;





hs=imdilate(hs,ones(3));

mask=mask|hs;

disp('Written ''mask.edf''');
edfwrite('mask.edf',mask','uint8');

