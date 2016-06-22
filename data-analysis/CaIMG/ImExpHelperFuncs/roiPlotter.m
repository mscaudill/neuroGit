function roiPlotter(roi, color, axes)
% set the axis state to hold on
hold(axes, 'on');
plot(roi(:,1),roi(:,2),[color,'-'], 'LineWidth', 2, 'Parent', axes)
hold(axes, 'off');
end


