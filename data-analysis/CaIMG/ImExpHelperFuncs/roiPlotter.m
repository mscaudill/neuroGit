function roiPlotter(roi, color, axes, drawMethod)
% set the axis state to hold on
hold(axes, 'on');
% and plot our roi polygon as yellow
if strcmp(drawMethod, 'Free Hand') 
    plot(roi(:,1),roi(:,2),[color,'-'], 'LineWidth', 2, 'Parent', axes)
    hold(axes, 'off');
elseif strcmp(drawMethod, 'Ellipse')
     rectangle('Position',roi,'Curvature',[1,1], 'EdgeColor',color,...
         'LineWidth', 2, 'Parent', axes); 
     hold(axes, 'off');
end

end

