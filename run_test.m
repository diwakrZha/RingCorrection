% this script is compares the use of correlation and mutual information (MI)
% for matching images. Here we use the same image corrupted with noise.
% It is beleved that MI can be even improved further by using normalised
% MI.

% load im
load('image.mat');

%% loop
layers = 200:1000;
mi = zeros(11,10,21);
cors = zeros(11,10,21);

d = -10:10;
sigma = 0:0.1:1;
for s=1:length(sigma)
    for k=1:10
        sn0 = n0+sigma(s)*randn(size(n0));
        sn180 = n0+sigma(s)*randn(size(n0));
        
        % mutual information
        for i=1:length(d);
            if d(i)>0
                % 'pos'
                %d(i)
                mi(s,k,i) = information(sn0(1:end-d(i)*1024) , sn180(d(i)*1024+1:end));
            else
                % 'neg'
                %d(i)
                mi(s,k,i) = information(sn0((-d(i))*1024+1:end) , sn180(1:end+d(i)*1024));
            end
        end

        % correlation
        corr = normxcorr2(sn0(layers,:), sn180(layers,:));
        cors(s,k,:) = corr(end/2+0.5,1490/2+1+[-10:10]);
    end
end

[mc,ic]=max(cors,[],3);
[me,ie]=max(mi,[],3);

% the correct position is 11, that is why we subtract it
figure
plot(sigma, mean(abs(ie-11),2),sigma,mean(abs(ic-11),2));
xlabel('noise level \sigma')
ylabel('average deviation from correct position')
legend('Mutual information','Correlation','Location','NorthWest')