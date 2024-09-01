% Boxplot that shows acc variance over 3000 folds.
opts_1 = spreadsheetImportOptions('NumVariables',1);
opts_1.Sheet = '4C_per_subj';
opts_1.DataRange = 'B2:B21'; %'D2:D20'; %'B2:B21'; %with outliers
per_subj_box_plot_data = readmatrix('classif_res_ffa.xlsx',opts_1);
per_subj_box_plot_data = str2double(per_subj_box_plot_data);

figure;
box_plot = boxplot(per_subj_box_plot_data,'Widths',0.2);

axis_1 = gca;
axis_1.Title.String = '4C\_Mean\_Acc - Per Subject - FFA';
axis_1.XLabel.String = 'Subject Count';
axis_1.YLabel.String = 'Accuracy (%)';

axis_1.YLim = [0,1];

axis_1.YTick = linspace(0, 1, 11);
axis_1.YTickLabel = {'0%' '10%' '20%' '30%' '40%' '50%' '60%' '70%' '80%' '90%' '100%'};
axis_1.XTick = 1;
axis_1.XTickLabel = {'20'};

%boxWidth = 2;
boxes = findobj(axis_1, 'Tag', 'Box');

for i = 1:length(boxes)
    p = patch(get(boxes(i), 'XData'), get(boxes(i), 'YData'), [1, 0 , 0], 'FaceAlpha', 1); %[0, 0.9 , 1]
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