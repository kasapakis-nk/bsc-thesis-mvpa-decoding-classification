% NULL Hypothesis: 
% The means of 2C and 4C accuracies, across 3000 folds, for the ffa, DO NOT DIFFER significantly.

% 4C fold data
opts_1 = spreadsheetImportOptions('NumVariables',1);
opts_1.Sheet = '4C_fold_HN';
opts_1.DataRange = 'L17:L3016';
fold_data_4C = readmatrix('classif_res_ffa.xlsx',opts_1);
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

% NULL Hypothesis (Normality):
% The data does NOT come from a normal distribution. 1=NOT 0=DOES

% Shapiro - Wilk test for normality is not built-in to matlab.
% [h1, p1] = swtest(fold_data_4C);

% Lilliefors test for normality of data.
[h_4C_lil, p_4C_lil] = lillietest(fold_data_4C); % h=1 means NOT NORMAL.
[h_2C_lil, p_2C_lil] = lillietest(fold_data_2C);

% Jarque - Bera test for normality of data.
[h_4C, p_4C] = jbtest(fold_data_4C); % h=1 means NOT NORMAL.
[h_2C, p_2C] = jbtest(fold_data_2C); % h=0 means it COULD be normal.

% Variance test
% NULL Hypothesis (Variance):
% There IS NOT a significant diff between the variances of the two samples.
[h_var, p_var, ci_var, stats_var] = vartest2(fold_data_2C,fold_data_4C);
% h=1 means YES DIFFERENT % h=0 means NOT DIFFERENT

% Mean Difference Mann-Whitney U Test (Wilcoxon Rank-Sum Test)
% NULL Hypothesis (Mean Difference):
% The two distributions DO NOT differ.
[p_mean, h_mean, stats_mean] = ranksum(fold_data_2C,fold_data_4C);
% h=1 means YES DIFFERENT % h=0 means NOT DIFFERENT


% Kruskal-Wallis test is for more than 2 data sets.