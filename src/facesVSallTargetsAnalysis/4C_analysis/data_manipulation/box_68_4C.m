% Boxplot that shows acc variance over 3000 folds.
opts_1 = spreadsheetImportOptions('NumVariables',1);
opts_1.Sheet = '4C_fold';
opts_1.DataRange = 'G8:G75';
fold_count_68_box_plot_data = readmatrix('classif_res_ffa.xlsx',opts_1);
fold_count_68_box_plot_data = str2double(fold_count_68_box_plot_data);

figure;
box_plot = boxplot(fold_count_68_box_plot_data,'Widths',0.2);

axis_1 = gca;

axis_1.Title.String = '4C\_Accuracy Variance - 68 Folds - FFA';
axis_1.XLabel.String = 'Fold Count';
axis_1.YLabel.String = 'Accuracy (%)';

axis_1.YLim = [0.4,0.9];

axis_1.YTick = linspace(0.4, 0.9, 6);
axis_1.YTickLabel = {'40%' '50%' '60%' '70%' '80%' '90%'};
axis_1.XTick = 1;
axis_1.XTickLabel = {'68'};

%boxWidth = 2;
boxes = findobj(axis_1, 'Tag', 'Box');

for i = 1:length(boxes)
    p = patch(get(boxes(i), 'XData'), get(boxes(i), 'YData'), [1, 0.5 , 0], 'FaceAlpha', 0.9);
end

medianLines = findobj(axis_1, 'Tag', 'Median');
upperWhiskers = findobj(axis_1, 'Tag', 'Upper Whisker');
lowerWhiskers = findobj(axis_1, 'Tag', 'Lower Whisker');
outliers = findobj(axis_1, 'Tag', 'Outliers');
lowerValue = findobj(axis_1, 'Tag', 'Lower Adjacent Value');
upperValue = findobj(axis_1, 'Tag', 'Upper Adjacent Value');

set(boxes, 'LineWidth', 1.3,'Color','[0 0 0]');
set(medianLines, 'LineWidth', 1.2,'Color','[0 0 0]');
set(upperWhiskers, 'LineWidth', 1.4);
set(lowerWhiskers, 'LineWidth', 1.4);
set(outliers, 'LineWidth', 1.4,'MarkerEdgeColor','[1 0 0]');
set(lowerValue, 'LineWidth',1.4);
set(upperValue, 'LineWidth',1.4);

axis_1.XGrid = 'on';
axis_1.YGrid = 'on';
axis_1.GridLineStyle = '--';
axis_1.GridColor = [0.5, 0.5, 0.5];
axis_1.GridAlpha = 0.7;

uistack(p, 'bottom');

display(axis_1)