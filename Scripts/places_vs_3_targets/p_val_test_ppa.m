% NULL Hypothesis: The means of 2C and 4C, across different 3000 folds, 
% differ significantly.

% 4C fold data
opts_1 = spreadsheetImportOptions('NumVariables',1);
opts_1.Sheet = '4C_fold_HN';
opts_1.DataRange = 'L17:L3016';
fold_data_4C = readmatrix('classif_res_ppa.xlsx',opts_1);
fold_data_4C = str2double(fold_data_4C);

% 2C fold data
opts_1 = spreadsheetImportOptions('NumVariables',1);
opts_1.Sheet = '2C_fold_HN';
opts_1.DataRange = 'L17:L3016';
fold_data_2C = readmatrix('classif_res_ffa.xlsx',opts_1);
fold_data_2C = str2double(fold_data_2C);

fold_data = [fold_data_4C,fold_data_2C];

% Compare data with normal probability.
normplot(fold_data_4C);
normplot(fold_data_2C);

% Jarque - Bera test for normality of data.
norm_4C = jbtest(fold_data_4C); % 4C data does come from normal dist.
norm_2C = jbtest(fold_data_2C); % 2C data does not come from normal dist.

% Variance test
var_test = vartest2(fold_data_2C,fold_data_4C); % Result is NO, they don't have same variance.

% Non-parametric Kruskal-Wallis test for p value about:
% "statistical significance of difference between the mean values of the
% two distributions of data for 2C, 4C"
p = kruskalwallis(fold_data);

%{
% t-value calculation
mean_diff = ((sum(fold_data(:,2))/size(fold_data,1)) - (sum(fold_data(:,1))/size(fold_data,1)));
denom = sqrt(((std(fold_data(:,2))^2)/size(fold_data,1)) + ((std(fold_data(:,1))^2)/size(fold_data,1)));
t_value = mean_diff / denom;
disp(['t value is: ' num2str(t_value)])
%}